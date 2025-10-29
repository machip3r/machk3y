import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/password_service.dart';
import '../core/services/auth_service.dart';
import '../models/credential.dart';

class VaultProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final StorageService _storageService = StorageService();
  final PasswordService _passwordService = PasswordService();
  final AuthService _authService = AuthService();

  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];
  SecurityStats _securityStats = SecurityStats.empty();
  List<String> _tags = [];
  List<String> _searchHistory = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  CredentialType? _selectedType;
  String? _selectedTag;
  String _sortBy = 'title';
  bool _sortAscending = true;
  bool _showStarredOnly = false;

  // Pagination
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMore = true;

  // Getters
  List<Credential> get credentials => _credentials;
  List<Credential> get filteredCredentials => _filteredCredentials;
  SecurityStats get securityStats => _securityStats;
  List<String> get tags => _tags;
  List<String> get searchHistory => _searchHistory;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
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
    // Don't load cached credentials - it will be loaded fresh from server
    // to ensure we only get current user's credentials
    _securityStats =
        await _storageService.getCachedSecurityStats() ?? SecurityStats.empty();
    _tags = await _storageService.getCachedTags();
    _searchHistory = await _storageService.getSearchHistory();
  }

  Future<void> loadCredentials({bool refresh = false}) async {
    if (refresh) {
      _credentials.clear();
      _currentOffset = 0;
      _hasMore = true;
    }

    _setLoading(true);
    _clearError();

    try {
      final newCredentials = await _supabaseService.getCredentials(
        limit: _pageSize,
        offset: refresh ? 0 : _currentOffset,
      );

      if (refresh) {
        _credentials = newCredentials;
      } else {
        // Filter out duplicates before adding
        final existingIds = _credentials.map((c) => c.id).toSet();
        final uniqueCredentials = newCredentials
            .where((c) => !existingIds.contains(c.id))
            .toList();
        _credentials.addAll(uniqueCredentials);
      }

      _currentOffset = _credentials.length;
      _hasMore = newCredentials.length == _pageSize;

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

  Future<void> loadMoreCredentials() async {
    if (_isLoadingMore || !_hasMore) return;

    _setLoadingMore(true);
    _clearError();

    try {
      final newCredentials = await _supabaseService.getCredentials(
        limit: _pageSize,
        offset: _currentOffset,
      );

      // Filter out duplicates before adding
      final existingIds = _credentials.map((c) => c.id).toSet();
      final uniqueCredentials = newCredentials
          .where((c) => !existingIds.contains(c.id))
          .toList();
      _credentials.addAll(uniqueCredentials);
      _currentOffset = _credentials.length;
      _hasMore = newCredentials.length == _pageSize;

      await _storageService.cacheCredentials(_credentials);

      _applyFilters();
    } catch (e) {
      _setError('Failed to load more credentials: ${e.toString()}');
    } finally {
      _setLoadingMore(false);
    }
  }

  Future<void> refreshCredentials() async {
    _setRefreshing(true);
    _clearError();

    try {
      await loadCredentials(refresh: true);
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
    _sortBy = 'title';
    _sortAscending = true;
    _showStarredOnly = false;
    _applyFilters();
  }

  void _applyFilters() {
    // Filter by current user to ensure no credentials from other users
    final currentUser = _authService.getCurrentUser();
    List<Credential> filtered = _credentials
        .where(
          (credential) =>
              currentUser != null && credential.userId == currentUser.id,
        )
        .toList();

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

    // Apply sorting - only sort client-side for encrypted fields (title, username)
    // Database-level fields (created_at, updated_at) are already sorted from DB
    if (_sortBy == 'title' || _sortBy == 'username') {
      filtered.sort((a, b) {
        int comparison = 0;

        switch (_sortBy) {
          case 'title':
            comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case 'username':
            comparison = a.username.toLowerCase().compareTo(
              b.username.toLowerCase(),
            );
            break;
          default:
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    }
    // For DB-sorted fields (created_at, updated_at), data is already sorted from query

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

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
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
