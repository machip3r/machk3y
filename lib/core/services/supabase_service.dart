import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../config/env.dart';
import '../../models/credential.dart';
import 'encryption_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  // Authentication methods
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _encryption.clearAllData();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // User settings methods
  Future<UserSettings?> getUserSettings() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .single();

      return UserSettings.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<UserSettings> createUserSettings(
    String salt,
    String? encryptedRecoveryKey,
  ) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('User not authenticated');

    final settings = UserSettings(
      userId: user.id,
      salt: salt,
      encryptedRecoveryKey: encryptedRecoveryKey,
    );

    final response = await _supabase
        .from('user_settings')
        .insert(settings.toJson())
        .select()
        .single();

    return UserSettings.fromJson(response);
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    await _supabase
        .from('user_settings')
        .update(settings.toJson())
        .eq('id', settings.id);
  }

  // Credential methods
  Future<List<Credential>> getCredentials() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('encrypted_credentials')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final credentials = <Credential>[];
      final masterKey = _encryption.getMasterKey();
      final salt = _encryption.getSalt();

      if (masterKey == null || salt == null) {
        throw Exception('Master key not available');
      }

      for (final item in response) {
        try {
          final decryptedData = await _encryption.decryptCredential(
            item['encrypted_data'],
            item['nonce'],
            item['mac'],
            masterKey,
          );

          final credential = Credential(
            id: item['id'],
            userId: item['user_id'],
            type: CredentialType.values.firstWhere(
              (e) => e.toString().split('.').last == item['credential_type'],
              orElse: () => CredentialType.other,
            ),
            title: decryptedData['title'] ?? '',
            data: decryptedData,
            tags: List<String>.from(item['tags'] ?? []),
            faviconUrl: item['favicon_url'],
            createdAt: DateTime.parse(item['created_at']),
            updatedAt: DateTime.parse(item['updated_at']),
            isStarred: item['is_starred'] ?? false,
            isShared: item['is_shared'] ?? false,
          );

          credentials.add(credential);
        } catch (e) {
          // Skip corrupted credentials
          continue;
        }
      }

      return credentials;
    } catch (e) {
      return [];
    }
  }

  Future<Credential> createCredential(Credential credential) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('User not authenticated');

    final masterKey = _encryption.getMasterKey();
    if (masterKey == null) throw Exception('Master key not available');

    final encryptedData = await _encryption.encryptCredential(
      credential.data,
      masterKey,
    );

    final credentialData = {
      'user_id': user.id,
      'encrypted_data': encryptedData['encrypted_data'],
      'nonce': encryptedData['nonce'],
      'mac': encryptedData['mac'],
      'credential_type': credential.type.toString().split('.').last,
      'title': credential.title,
      'tags': credential.tags,
      'favicon_url': credential.faviconUrl,
      'is_starred': credential.isStarred,
      'is_shared': credential.isShared,
    };

    final response = await _supabase
        .from('encrypted_credentials')
        .insert(credentialData)
        .select()
        .single();

    return credential.copyWith(
      id: response['id'],
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: DateTime.parse(response['updated_at']),
    );
  }

  Future<Credential> updateCredential(Credential credential) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('User not authenticated');

    final masterKey = _encryption.getMasterKey();
    if (masterKey == null) throw Exception('Master key not available');

    final encryptedData = await _encryption.encryptCredential(
      credential.data,
      masterKey,
    );

    final credentialData = {
      'encrypted_data': encryptedData['encrypted_data'],
      'nonce': encryptedData['nonce'],
      'mac': encryptedData['mac'],
      'credential_type': credential.type.toString().split('.').last,
      'title': credential.title,
      'tags': credential.tags,
      'favicon_url': credential.faviconUrl,
      'is_starred': credential.isStarred,
      'is_shared': credential.isShared,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('encrypted_credentials')
        .update(credentialData)
        .eq('id', credential.id)
        .select()
        .single();

    return credential.copyWith(
      updatedAt: DateTime.parse(response['updated_at']),
    );
  }

  Future<void> deleteCredential(String credentialId) async {
    await _supabase
        .from('encrypted_credentials')
        .delete()
        .eq('id', credentialId);
  }

  // Shared credentials methods
  Future<List<SharedCredential>> getSharedCredentials() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('shared_credentials')
          .select()
          .eq('shared_with', user.id);

      return response.map((item) => SharedCredential.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<SharedCredential> shareCredential(
    String credentialId,
    String recipientEmail,
    String encryptedForRecipient,
  ) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('User not authenticated');

    // Get recipient user ID
    final recipientUser = await _supabase
        .from('auth.users')
        .select('id')
        .eq('email', recipientEmail)
        .single();

    final sharedCredential = SharedCredential(
      credentialId: credentialId,
      sharedBy: user.id,
      sharedWith: recipientUser['id'],
      encryptedForRecipient: encryptedForRecipient,
    );

    final response = await _supabase
        .from('shared_credentials')
        .insert(sharedCredential.toJson())
        .select()
        .single();

    return SharedCredential.fromJson(response);
  }

  Future<void> revokeSharedCredential(String sharedCredentialId) async {
    await _supabase
        .from('shared_credentials')
        .delete()
        .eq('id', sharedCredentialId);
  }

  // Security audit methods
  Future<SecurityStats> getSecurityStats() async {
    final credentials = await getCredentials();

    int weakPasswords = 0;
    int compromisedPasswords = 0;
    int reusedPasswords = 0;
    int strongPasswords = 0;

    final passwordCounts = <String, int>{};

    for (final credential in credentials) {
      final password = credential.password;
      if (password.isEmpty) continue;

      // Count password usage
      passwordCounts[password] = (passwordCounts[password] ?? 0) + 1;

      // Analyze password strength
      final strength = _analyzePasswordStrength(password);
      switch (strength) {
        case PasswordStrength.weak:
          weakPasswords++;
          break;
        case PasswordStrength.medium:
          // Count as weak for security purposes
          weakPasswords++;
          break;
        case PasswordStrength.strong:
          strongPasswords++;
          break;
      }
    }

    // Count reused passwords
    reusedPasswords = passwordCounts.values.where((count) => count > 1).length;

    // Calculate security score
    final totalPasswords = credentials.length;
    final securityScore = totalPasswords > 0
        ? (strongPasswords / totalPasswords) * 100
        : 100.0;

    return SecurityStats(
      totalCredentials: credentials.length,
      weakPasswords: weakPasswords,
      compromisedPasswords: compromisedPasswords,
      reusedPasswords: reusedPasswords,
      strongPasswords: strongPasswords,
      securityScore: securityScore,
    );
  }

  PasswordStrength _analyzePasswordStrength(String password) {
    int score = 0;

    if (password.length >= 12) score += 2;
    if (password.length >= 16) score += 1;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 2;

    if (score >= 7) return PasswordStrength.strong;
    if (score >= 5) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  // Check if password is compromised using HIBP API
  Future<bool> isPasswordCompromised(String password) async {
    try {
      final hash = sha256.convert(utf8.encode(password));
      final hashStr = hash.toString().toUpperCase();

      final response = await _supabase.functions.invoke(
        'check-password',
        body: {'hash': hashStr},
      );

      return response.data['compromised'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get favicon URL
  String getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${AppConstants.faviconApiUrl}${uri.host}&sz=64';
    } catch (e) {
      return '';
    }
  }

  // Search credentials
  Future<List<Credential>> searchCredentials(String query) async {
    final credentials = await getCredentials();

    if (query.isEmpty) return credentials;

    final lowercaseQuery = query.toLowerCase();

    return credentials.where((credential) {
      return credential.title.toLowerCase().contains(lowercaseQuery) ||
          credential.username.toLowerCase().contains(lowercaseQuery) ||
          credential.url.toLowerCase().contains(lowercaseQuery) ||
          credential.tags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  // Filter credentials by type
  Future<List<Credential>> getCredentialsByType(CredentialType type) async {
    final credentials = await getCredentials();
    return credentials.where((credential) => credential.type == type).toList();
  }

  // Filter credentials by tag
  Future<List<Credential>> getCredentialsByTag(String tag) async {
    final credentials = await getCredentials();
    return credentials
        .where((credential) => credential.tags.contains(tag))
        .toList();
  }

  // Get all unique tags
  Future<List<String>> getAllTags() async {
    final credentials = await getCredentials();
    final tags = <String>{};

    for (final credential in credentials) {
      tags.addAll(credential.tags);
    }

    return tags.toList()..sort();
  }

  // Backup and restore methods
  Future<Map<String, dynamic>> exportData() async {
    final credentials = await getCredentials();
    final settings = await getUserSettings();

    return {
      'credentials': credentials.map((c) => c.toJson()).toList(),
      'settings': settings?.toJson(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': AppConstants.appVersion,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final credentials = data['credentials'] as List<dynamic>;

    for (final credentialData in credentials) {
      final credential = Credential.fromJson(credentialData);
      await createCredential(credential);
    }
  }
}
