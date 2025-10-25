import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/password_service.dart';
import '../models/credential.dart';

class VaultProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final StorageService _storageService = StorageService();
  final PasswordService _passwordService = PasswordService();

  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];
  SecurityStats _securityStats = SecurityStats.empty();
  List<String> _tags = [];
  List<String> _searchHistory = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String _searchQuery = '';
  CredentialType? _selectedType;
  String? _selectedTag;
  String _sortBy = 'updated_at';
  bool _sortAscending = false;
  bool _showStarredOnly = false;

  // Getters
  List<Credential> get credentials => _credentials;
  List<Credential> get filteredCredentials => _filteredCredentials;
  SecurityStats get securityStats => _securityStats;
  List<String> get tags => _tags;
  List<String> get searchHistory => _searchHistory;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  CredentialType? get selectedType => _selectedType;
  String? get selectedTag => _selectedTag;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get showStarredOnly => _showStarredOnly;

  VaultProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedData();
    await loadCredentials();
  }

  Future<void> _loadCachedData() async {
    _credentials = await _storageService.getCachedCredentials();
    _securityStats =
        await _storageService.getCachedSecurityStats() ?? SecurityStats.empty();
    _tags = await _storageService.getCachedTags();
    _searchHistory = await _storageService.getSearchHistory();
    _applyFilters();
  }

  Future<void> loadCredentials() async {
    _setLoading(true);
    _clearError();

    try {
      _credentials = await _supabaseService.getCredentials();
      await _storageService.cacheCredentials(_credentials);

      await _loadSecurityStats();
      await _loadTags();

      _applyFilters();
    } catch (e) {
      _setError('Failed to load credentials: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCredentials() async {
    _setRefreshing(true);
    _clearError();

    try {
      _credentials = await _supabaseService.getCredentials();
      await _storageService.cacheCredentials(_credentials);

      await _loadSecurityStats();
      await _loadTags();

      _applyFilters();
    } catch (e) {
      _setError('Failed to refresh credentials: ${e.toString()}');
    } finally {
      _setRefreshing(false);
    }
  }

  Future<void> _loadSecurityStats() async {
    _securityStats = await _supabaseService.getSecurityStats();
    await _storageService.cacheSecurityStats(_securityStats);
  }

  Future<void> _loadTags() async {
    _tags = await _supabaseService.getAllTags();
    await _storageService.cacheTags(_tags);
  }

  Future<Credential?> createCredential(Credential credential) async {
    _setLoading(true);
    _clearError();

    try {
      final createdCredential = await _supabaseService.createCredential(
        credential,
      );
      _credentials.insert(0, createdCredential);
      await _storageService.cacheCredentials(_credentials);

      await _loadSecurityStats();
      await _loadTags();

      _applyFilters();
      return createdCredential;
    } catch (e) {
      _setError('Failed to create credential: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCredential(Credential credential) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedCredential = await _supabaseService.updateCredential(
        credential,
      );
      final index = _credentials.indexWhere((c) => c.id == credential.id);
      if (index != -1) {
        _credentials[index] = updatedCredential;
        await _storageService.cacheCredentials(_credentials);

        await _loadSecurityStats();
        await _loadTags();

        _applyFilters();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update credential: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCredential(String credentialId) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.deleteCredential(credentialId);
      _credentials.removeWhere((c) => c.id == credentialId);
      await _storageService.cacheCredentials(_credentials);

      await _loadSecurityStats();
      await _loadTags();

      _applyFilters();
      return true;
    } catch (e) {
      _setError('Failed to delete credential: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleStarred(String credentialId) async {
    final credential = _credentials.firstWhere((c) => c.id == credentialId);
    final updatedCredential = credential.copyWith(
      isStarred: !credential.isStarred,
    );

    return await updateCredential(updatedCredential);
  }

  Future<List<Credential>> searchCredentials(String query) async {
    if (query.isEmpty) {
      _searchQuery = '';
      _applyFilters();
      return _filteredCredentials;
    }

    _searchQuery = query;
    await _storageService.addSearchHistory(query);
    _searchHistory = await _storageService.getSearchHistory();

    _applyFilters();
    return _filteredCredentials;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSelectedType(CredentialType? type) {
    _selectedType = type;
    _applyFilters();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    _applyFilters();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = false;
    }
    _applyFilters();
  }

  void setShowStarredOnly(bool show) {
    _showStarredOnly = show;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _selectedTag = null;
    _sortBy = 'updated_at';
    _sortAscending = false;
    _showStarredOnly = false;
    _applyFilters();
  }

  void _applyFilters() {
    List<Credential> filtered = List.from(_credentials);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((credential) {
        return credential.title.toLowerCase().contains(lowercaseQuery) ||
            credential.username.toLowerCase().contains(lowercaseQuery) ||
            credential.url.toLowerCase().contains(lowercaseQuery) ||
            credential.tags.any(
              (tag) => tag.toLowerCase().contains(lowercaseQuery),
            );
      }).toList();
    }

    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered
          .where((credential) => credential.type == _selectedType)
          .toList();
    }

    // Apply tag filter
    if (_selectedTag != null) {
      filtered = filtered
          .where((credential) => credential.tags.contains(_selectedTag))
          .toList();
    }

    // Apply starred filter
    if (_showStarredOnly) {
      filtered = filtered.where((credential) => credential.isStarred).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'username':
          comparison = a.username.compareTo(b.username);
          break;
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
        default:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    _filteredCredentials = filtered;
    notifyListeners();
  }

  // Security analysis methods
  List<Credential> getWeakPasswords() {
    return _passwordService.findWeakPasswords(_credentials);
  }

  List<Credential> getReusedPasswords() {
    final reusedPasswords = _passwordService.findReusedPasswords(_credentials);
    return _credentials
        .where((credential) => reusedPasswords.contains(credential.password))
        .toList();
  }

  List<Credential> getOldPasswords() {
    return _passwordService.findOldPasswords(_credentials);
  }

  Future<List<Credential>> getCompromisedPasswords() async {
    final compromised = <Credential>[];

    for (final credential in _credentials) {
      if (credential.password.isNotEmpty) {
        final isCompromised = await _passwordService.isPasswordCompromised(
          credential.password,
        );
        if (isCompromised) {
          compromised.add(credential);
        }
      }
    }

    return compromised;
  }

  // Credential type counts
  Map<CredentialType, int> getCredentialTypeCounts() {
    final counts = <CredentialType, int>{};

    for (final type in CredentialType.values) {
      counts[type] = _credentials.where((c) => c.type == type).length;
    }

    return counts;
  }

  // Tag counts
  Map<String, int> getTagCounts() {
    final counts = <String, int>{};

    for (final credential in _credentials) {
      for (final tag in credential.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }

    return counts;
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = [];
    notifyListeners();
  }

  // Export data
  Future<Map<String, dynamic>> exportData() async {
    return await _supabaseService.exportData();
  }

  // Import data
  Future<void> importData(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.importData(data);
      await loadCredentials();
    } catch (e) {
      _setError('Failed to import data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
