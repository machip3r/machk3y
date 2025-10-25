import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'encryption_service.dart';
import 'supabase_service.dart';
import '../../models/credential.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabase = SupabaseService();
  final EncryptionService _encryption = EncryptionService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Authentication state
  bool _isAuthenticated = false;
  bool _isVaultUnlocked = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isVaultUnlocked => _isVaultUnlocked;

  // Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    try {
      // Register with Supabase
      final authResponse = await _supabase.signUp(email, password);

      if (authResponse.user == null) {
        return AuthResult.failure('Registration failed');
      }

      // Generate salt and recovery key
      final salt = await _encryption.generateSalt();
      final recoveryKey = await _encryption.generateRecoveryKey();

      // Derive master key
      final masterKey = await _encryption.deriveMasterKey(masterPassword, salt);

      // Encrypt recovery key
      final encryptedRecoveryKey = await _encryption.encryptRecoveryKey(
        recoveryKey,
        masterKey,
      );

      // Store salt and master password hash
      await _encryption.storeSalt(salt);
      await _encryption.storeMasterKeyHash(masterPassword);

      // Create user settings
      await _supabase.createUserSettings(
        base64Encode(salt),
        encryptedRecoveryKey,
      );

      // Set session keys
      _encryption.setMasterKey(masterKey);
      _encryption.setSalt(salt);

      _isAuthenticated = true;
      _isVaultUnlocked = true;

      return AuthResult.success(recoveryKey: recoveryKey);
    } catch (e) {
      return AuthResult.failure('Registration failed: ${e.toString()}');
    }
  }

  // Login existing user
  Future<AuthResult> login({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    try {
      // Login with Supabase
      final authResponse = await _supabase.signIn(email, password);

      if (authResponse.user == null) {
        return AuthResult.failure('Login failed');
      }

      // Get user settings
      final settings = await _supabase.getUserSettings();
      if (settings == null) {
        return AuthResult.failure('User settings not found');
      }

      // Get salt
      final salt = base64Decode(settings.salt);

      // Derive master key
      final masterKey = await _encryption.deriveMasterKey(masterPassword, salt);

      // Verify master password by trying to decrypt recovery key
      if (settings.encryptedRecoveryKey != null) {
        try {
          await _encryption.decryptRecoveryKey(
            settings.encryptedRecoveryKey!,
            masterKey,
          );
        } catch (e) {
          return AuthResult.failure('Invalid master password');
        }
      }

      // Store master password hash
      await _encryption.storeMasterKeyHash(masterPassword);

      // Set session keys
      _encryption.setMasterKey(masterKey);
      _encryption.setSalt(salt);

      _isAuthenticated = true;
      _isVaultUnlocked = true;

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  // Recover account using recovery key
  Future<AuthResult> recoverAccount({
    required String email,
    required String password,
    required String recoveryKey,
    required String newMasterPassword,
  }) async {
    try {
      // Login with Supabase
      final authResponse = await _supabase.signIn(email, password);

      if (authResponse.user == null) {
        return AuthResult.failure('Login failed');
      }

      // Get user settings
      final settings = await _supabase.getUserSettings();
      if (settings == null) {
        return AuthResult.failure('User settings not found');
      }

      // Derive key from recovery key
      final recoveryKeyDerived = await _encryption.deriveKeyFromRecoveryKey(
        recoveryKey,
      );

      // Decrypt old recovery key to verify
      if (settings.encryptedRecoveryKey != null) {
        try {
          await _encryption.decryptRecoveryKey(
            settings.encryptedRecoveryKey!,
            recoveryKeyDerived,
          );
        } catch (e) {
          return AuthResult.failure('Invalid recovery key');
        }
      }

      // Generate new salt
      final newSalt = await _encryption.generateSalt();

      // Derive new master key
      final newMasterKey = await _encryption.deriveMasterKey(
        newMasterPassword,
        newSalt,
      );

      // Encrypt recovery key with new master key
      final newEncryptedRecoveryKey = await _encryption.encryptRecoveryKey(
        recoveryKey,
        newMasterKey,
      );

      // Update user settings
      final updatedSettings = settings.copyWith(
        salt: base64Encode(newSalt),
        encryptedRecoveryKey: newEncryptedRecoveryKey,
      );

      await _supabase.updateUserSettings(updatedSettings);

      // Store new master password hash
      await _encryption.storeMasterKeyHash(newMasterPassword);

      // Set session keys
      _encryption.setMasterKey(newMasterKey);
      _encryption.setSalt(newSalt);

      _isAuthenticated = true;
      _isVaultUnlocked = true;

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Recovery failed: ${e.toString()}');
    }
  }

  // Unlock vault with master password
  Future<AuthResult> unlockVault(String masterPassword) async {
    try {
      // Verify master password
      final isValid = await _encryption.verifyMasterPassword(masterPassword);
      if (!isValid) {
        return AuthResult.failure('Invalid master password');
      }

      // Get salt
      final salt = await _encryption.getStoredSalt();
      if (salt == null) {
        return AuthResult.failure('Salt not found');
      }

      // Derive master key
      final masterKey = await _encryption.deriveMasterKey(masterPassword, salt);

      // Set session keys
      _encryption.setMasterKey(masterKey);
      _encryption.setSalt(salt);

      _isVaultUnlocked = true;

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Unlock failed: ${e.toString()}');
    }
  }

  // Unlock vault with biometrics
  Future<AuthResult> unlockVaultWithBiometrics() async {
    try {
      // Check if biometrics are available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return AuthResult.failure('Biometrics not available');
      }

      // Check if biometrics are enabled
      final biometricEnabled = await _secureStorage.read(
        key: AppConstants.biometricEnabledKey,
      );
      if (biometricEnabled != 'true') {
        return AuthResult.failure('Biometrics not enabled');
      }

      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        return AuthResult.failure('Biometric authentication failed');
      }

      // Get stored master password hash and salt
      final masterPasswordHash = await _secureStorage.read(
        key: AppConstants.masterPasswordKey,
      );
      final saltStr = await _secureStorage.read(key: AppConstants.saltKey);

      if (masterPasswordHash == null || saltStr == null) {
        return AuthResult.failure('Authentication data not found');
      }

      // For biometric unlock, we need to store the master key temporarily
      // This is a simplified approach - in production, use secure enclave
      final masterKeyStr = await _secureStorage.read(key: 'temp_master_key');
      if (masterKeyStr == null) {
        return AuthResult.failure(
          'Master key not available for biometric unlock',
        );
      }

      final masterKey = SecretKey(base64Decode(masterKeyStr));
      final salt = base64Decode(saltStr);

      // Set session keys
      _encryption.setMasterKey(masterKey);
      _encryption.setSalt(salt);

      _isVaultUnlocked = true;

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Biometric unlock failed: ${e.toString()}');
    }
  }

  // Enable biometric unlock
  Future<AuthResult> enableBiometricUnlock(String masterPassword) async {
    try {
      // Verify master password
      final isValid = await _encryption.verifyMasterPassword(masterPassword);
      if (!isValid) {
        return AuthResult.failure('Invalid master password');
      }

      // Check if biometrics are available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return AuthResult.failure('Biometrics not available');
      }

      // Authenticate with biometrics to enable
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        return AuthResult.failure('Biometric authentication failed');
      }

      // Get salt and derive master key
      final salt = await _encryption.getStoredSalt();
      if (salt == null) {
        return AuthResult.failure('Salt not found');
      }

      final masterKey = await _encryption.deriveMasterKey(masterPassword, salt);

      // Store master key temporarily for biometric unlock
      // TODO; In production, use secure enclave or similar secure storage
      await _secureStorage.write(
        key: 'temp_master_key',
        value: base64Encode(await masterKey.extractBytes()),
      );

      // Enable biometric unlock
      await _secureStorage.write(
        key: AppConstants.biometricEnabledKey,
        value: 'true',
      );

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(
        'Failed to enable biometric unlock: ${e.toString()}',
      );
    }
  }

  // Disable biometric unlock
  Future<AuthResult> disableBiometricUnlock() async {
    try {
      await _secureStorage.delete(key: AppConstants.biometricEnabledKey);
      await _secureStorage.delete(key: 'temp_master_key');

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(
        'Failed to disable biometric unlock: ${e.toString()}',
      );
    }
  }

  // Check if biometric unlock is enabled
  Future<bool> isBiometricUnlockEnabled() async {
    final enabled = await _secureStorage.read(
      key: AppConstants.biometricEnabledKey,
    );
    return enabled == 'true';
  }

  // Change master password
  Future<AuthResult> changeMasterPassword({
    required String currentMasterPassword,
    required String newMasterPassword,
  }) async {
    try {
      // Verify current master password
      final isValid = await _encryption.verifyMasterPassword(
        currentMasterPassword,
      );
      if (!isValid) {
        return AuthResult.failure('Invalid current master password');
      }

      // Get current settings
      final settings = await _supabase.getUserSettings();
      if (settings == null) {
        return AuthResult.failure('User settings not found');
      }

      // Get current salt
      final salt = base64Decode(settings.salt);

      // Derive current master key
      final currentMasterKey = await _encryption.deriveMasterKey(
        currentMasterPassword,
        salt,
      );

      // Decrypt recovery key
      String? recoveryKey;
      if (settings.encryptedRecoveryKey != null) {
        recoveryKey = await _encryption.decryptRecoveryKey(
          settings.encryptedRecoveryKey!,
          currentMasterKey,
        );
      }

      // Generate new salt
      final newSalt = await _encryption.generateSalt();

      // Derive new master key
      final newMasterKey = await _encryption.deriveMasterKey(
        newMasterPassword,
        newSalt,
      );

      // Encrypt recovery key with new master key
      String? newEncryptedRecoveryKey;
      if (recoveryKey != null) {
        newEncryptedRecoveryKey = await _encryption.encryptRecoveryKey(
          recoveryKey,
          newMasterKey,
        );
      }

      // Update user settings
      final updatedSettings = settings.copyWith(
        salt: base64Encode(newSalt),
        encryptedRecoveryKey: newEncryptedRecoveryKey,
      );

      await _supabase.updateUserSettings(updatedSettings);

      // Store new master password hash
      await _encryption.storeMasterKeyHash(newMasterPassword);

      // Update session keys
      _encryption.setMasterKey(newMasterKey);
      _encryption.setSalt(newSalt);

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(
        'Failed to change master password: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await _supabase.signOut();
    _isAuthenticated = false;
    _isVaultUnlocked = false;
  }

  // Lock vault
  Future<void> lockVault() async {
    _isVaultUnlocked = false;
    // Clear session keys by calling clearAllData which sets internal fields to null
    await _encryption.clearAllData();
  }

  // Check if vault is locked
  bool isVaultLocked() {
    return !_isVaultUnlocked;
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.getCurrentUser();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _isAuthenticated && getCurrentUser() != null;
  }
}

class AuthResult {
  final bool success;
  final String? error;
  final String? recoveryKey;

  AuthResult._({required this.success, this.error, this.recoveryKey});

  factory AuthResult.success({String? recoveryKey}) {
    return AuthResult._(success: true, recoveryKey: recoveryKey);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}

// Extension for UserSettings to add copyWith method
extension UserSettingsExtension on UserSettings {
  UserSettings copyWith({
    String? id,
    String? userId,
    String? salt,
    String? encryptedRecoveryKey,
    DateTime? createdAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      salt: salt ?? this.salt,
      encryptedRecoveryKey: encryptedRecoveryKey ?? this.encryptedRecoveryKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
