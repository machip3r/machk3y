import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/credential.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize storage
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure storage methods
  Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  // Preferences storage methods
  Future<void> storePreference(String key, dynamic value) async {
    if (_prefs == null) await initialize();

    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs!.setStringList(key, value);
    }
  }

  Future<T?> getPreference<T>(String key) async {
    if (_prefs == null) await initialize();

    return _prefs!.get(key) as T?;
  }

  Future<void> deletePreference(String key) async {
    if (_prefs == null) await initialize();
    await _prefs!.remove(key);
  }

  Future<void> clearPreferences() async {
    if (_prefs == null) await initialize();
    await _prefs!.clear();
  }

  // App settings methods
  Future<void> setThemeMode(String themeMode) async {
    await storePreference('theme_mode', themeMode);
  }

  Future<String> getThemeMode() async {
    return await getPreference<String>('theme_mode') ?? 'system';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await storeSecure(AppConstants.biometricEnabledKey, enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await getSecure(AppConstants.biometricEnabledKey);
    return enabled == 'true';
  }

  Future<void> setAutoLockTimeout(int minutes) async {
    await storePreference(AppConstants.autoLockTimeoutKey, minutes);
  }

  Future<int> getAutoLockTimeout() async {
    return await getPreference<int>(AppConstants.autoLockTimeoutKey) ??
        AppConstants.defaultAutoLockMinutes;
  }

  Future<void> setClipboardTimeout(int seconds) async {
    await storePreference(AppConstants.clipboardTimeoutKey, seconds);
  }

  Future<int> getClipboardTimeout() async {
    return await getPreference<int>(AppConstants.clipboardTimeoutKey) ??
        AppConstants.defaultClipboardSeconds;
  }

  // Credential cache methods
  Future<void> cacheCredentials(List<Credential> credentials) async {
    final credentialsJson = credentials.map((c) => c.toJson()).toList();
    await storePreference('cached_credentials', jsonEncode(credentialsJson));
  }

  Future<List<Credential>> getCachedCredentials() async {
    final credentialsJson = await getPreference<String>('cached_credentials');
    if (credentialsJson == null) return [];

    try {
      final List<dynamic> credentialsList = jsonDecode(credentialsJson);
      return credentialsList.map((json) => Credential.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearCredentialsCache() async {
    await deletePreference('cached_credentials');
  }

  // Security stats cache
  Future<void> cacheSecurityStats(SecurityStats stats) async {
    final statsJson = {
      'totalCredentials': stats.totalCredentials,
      'weakPasswords': stats.weakPasswords,
      'compromisedPasswords': stats.compromisedPasswords,
      'reusedPasswords': stats.reusedPasswords,
      'strongPasswords': stats.strongPasswords,
      'securityScore': stats.securityScore,
    };
    await storePreference('cached_security_stats', jsonEncode(statsJson));
  }

  Future<SecurityStats?> getCachedSecurityStats() async {
    final statsJson = await getPreference<String>('cached_security_stats');
    if (statsJson == null) return null;

    try {
      final Map<String, dynamic> statsMap = jsonDecode(statsJson);
      return SecurityStats(
        totalCredentials: statsMap['totalCredentials'] ?? 0,
        weakPasswords: statsMap['weakPasswords'] ?? 0,
        compromisedPasswords: statsMap['compromisedPasswords'] ?? 0,
        reusedPasswords: statsMap['reusedPasswords'] ?? 0,
        strongPasswords: statsMap['strongPasswords'] ?? 0,
        securityScore: (statsMap['securityScore'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> clearSecurityStatsCache() async {
    await deletePreference('cached_security_stats');
  }

  // Tags cache
  Future<void> cacheTags(List<String> tags) async {
    await storePreference('cached_tags', tags);
  }

  Future<List<String>> getCachedTags() async {
    return await getPreference<List<String>>('cached_tags') ?? [];
  }

  Future<void> clearTagsCache() async {
    await deletePreference('cached_tags');
  }

  // Search history
  Future<void> addSearchHistory(String query) async {
    if (query.isEmpty) return;

    final history = await getSearchHistory();
    history.remove(query); // Remove if exists
    history.insert(0, query); // Add to beginning

    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }

    await storePreference('search_history', history);
  }

  Future<List<String>> getSearchHistory() async {
    return await getPreference<List<String>>('search_history') ?? [];
  }

  Future<void> clearSearchHistory() async {
    await deletePreference('search_history');
  }

  // App state
  Future<void> setLastActiveTime(DateTime time) async {
    await storePreference('last_active_time', time.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastActiveTime() async {
    final timestamp = await getPreference<int>('last_active_time');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setVaultLocked(bool locked) async {
    await storePreference('vault_locked', locked);
  }

  Future<bool> isVaultLocked() async {
    return await getPreference<bool>('vault_locked') ?? true;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await storePreference('onboarding_completed', completed);
  }

  Future<bool> isOnboardingCompleted() async {
    return await getPreference<bool>('onboarding_completed') ?? false;
  }

  // Backup and restore
  Future<void> createBackup(Map<String, dynamic> data) async {
    final backupJson = jsonEncode(data);
    await storeSecure('backup_data', backupJson);
  }

  Future<Map<String, dynamic>?> getBackup() async {
    final backupJson = await getSecure('backup_data');
    if (backupJson == null) return null;

    try {
      return jsonDecode(backupJson);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearBackup() async {
    await deleteSecure('backup_data');
  }

  // Clear all data
  Future<void> clearAllData() async {
    await clearSecure();
    await clearPreferences();
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'themeMode': await getThemeMode(),
      'autoLockTimeout': await getAutoLockTimeout(),
      'clipboardTimeout': await getClipboardTimeout(),
      'biometricEnabled': await isBiometricEnabled(),
      'onboardingCompleted': await isOnboardingCompleted(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['themeMode'] != null) {
      await setThemeMode(settings['themeMode']);
    }
    if (settings['autoLockTimeout'] != null) {
      await setAutoLockTimeout(settings['autoLockTimeout']);
    }
    if (settings['clipboardTimeout'] != null) {
      await setClipboardTimeout(settings['clipboardTimeout']);
    }
    if (settings['biometricEnabled'] != null) {
      await setBiometricEnabled(settings['biometricEnabled']);
    }
    if (settings['onboardingCompleted'] != null) {
      await setOnboardingCompleted(settings['onboardingCompleted']);
    }
  }

  // Check if auto-lock should be triggered
  Future<bool> shouldAutoLock() async {
    final lastActiveTime = await getLastActiveTime();
    if (lastActiveTime == null) return false;

    final autoLockTimeout = await getAutoLockTimeout();
    if (autoLockTimeout == 0) return false; // Never auto-lock

    final timeSinceLastActive = DateTime.now().difference(lastActiveTime);
    return timeSinceLastActive.inMinutes >= autoLockTimeout;
  }

  // Update last active time
  Future<void> updateLastActiveTime() async {
    await setLastActiveTime(DateTime.now());
  }
}
