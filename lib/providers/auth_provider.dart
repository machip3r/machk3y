import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isAuthenticated = false;
  bool _isVaultUnlocked = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isVaultUnlocked => _isVaultUnlocked;
  bool get isLoading => _isLoading;
  String? get error => _error;

  User? get currentUser => _authService.getCurrentUser();

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if there's a valid Supabase session
    final user = _authService.getCurrentUser();
    if (user != null) {
      // User has an active session
      _isAuthenticated = true;

      // Default vault to locked on app restart for security
      // User needs to unlock vault with master password
      _isVaultUnlocked = false;

      // Set vault as locked on app startup (unless we're in the middle of login)
      await _storageService.setVaultLocked(true);

      print(
        'Session restored: User ${user.id} is authenticated, vault is locked',
      );
    } else {
      _isAuthenticated = false;
      _isVaultUnlocked = false;
      print('No active session found');
    }
    notifyListeners();
  }

  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
      );

      if (result.success) {
        // Don't set authenticated yet - wait for completeRegistration
        await _storageService.updateLastActiveTime();
      } else {
        _setError(result.error ?? 'Registration failed');
      }

      return result;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return AuthResult.failure('Registration failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> completeRegistration({
    required String masterPassword,
    required String recoveryKey,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.completeRegistration(
        masterPassword: masterPassword,
        recoveryKey: recoveryKey,
      );

      if (result.success) {
        _isAuthenticated = true;
        _isVaultUnlocked = true;
        await _storageService.updateLastActiveTime();
        await _storageService.setVaultLocked(false); // Mark vault as unlocked
      } else {
        _setError(result.error ?? 'Registration completion failed');
      }

      return result;
    } catch (e) {
      _setError('Registration completion failed: ${e.toString()}');
      return AuthResult.failure(
        'Registration completion failed: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Email confirmation methods using codes
  Future<AuthResult> verifyConfirmationCode({
    required String email,
    required String code,
  }) async {
    return await _authService.verifyConfirmationCode(email: email, code: code);
  }

  Future<AuthResult> resendConfirmationCode(String email) async {
    return await _authService.resendConfirmationCode(email);
  }

  Future<AuthResult> initialLogin({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.initialLogin(
        email: email,
        password: password,
      );

      if (!result.success) {
        _setError(result.error ?? 'Login failed');
      }

      return result;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return AuthResult.failure('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> completeLogin({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.completeLogin(
        email: email,
        password: password,
        masterPassword: masterPassword,
      );

      if (result.success) {
        _isAuthenticated = true;
        _isVaultUnlocked = true;
        await _storageService.updateLastActiveTime();
        await _storageService.setVaultLocked(false); // Mark vault as unlocked
      } else {
        _setError(result.error ?? 'Login failed');
      }

      return result;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return AuthResult.failure('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
        masterPassword: masterPassword,
      );

      if (result.success) {
        _isAuthenticated = true;
        _isVaultUnlocked = true;
        await _storageService.updateLastActiveTime();
      } else {
        _setError(result.error ?? 'Login failed');
      }

      return result;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return AuthResult.failure('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> unlockVault(String masterPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.unlockVault(masterPassword);

      if (result.success) {
        _isVaultUnlocked = true;
        await _storageService.updateLastActiveTime();
      } else {
        _setError(result.error ?? 'Unlock failed');
      }

      return result;
    } catch (e) {
      _setError('Unlock failed: ${e.toString()}');
      return AuthResult.failure('Unlock failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> unlockVaultWithBiometrics() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.unlockVaultWithBiometrics();

      if (result.success) {
        _isVaultUnlocked = true;
        await _storageService.updateLastActiveTime();
      } else {
        _setError(result.error ?? 'Biometric unlock failed');
      }

      return result;
    } catch (e) {
      _setError('Biometric unlock failed: ${e.toString()}');
      return AuthResult.failure('Biometric unlock failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> enableBiometricUnlock(String masterPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.enableBiometricUnlock(masterPassword);

      if (result.success) {
        await _storageService.setBiometricEnabled(true);
      } else {
        _setError(result.error ?? 'Failed to enable biometric unlock');
      }

      return result;
    } catch (e) {
      _setError('Failed to enable biometric unlock: ${e.toString()}');
      return AuthResult.failure(
        'Failed to enable biometric unlock: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> disableBiometricUnlock() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.disableBiometricUnlock();

      if (result.success) {
        await _storageService.setBiometricEnabled(false);
      } else {
        _setError(result.error ?? 'Failed to disable biometric unlock');
      }

      return result;
    } catch (e) {
      _setError('Failed to disable biometric unlock: ${e.toString()}');
      return AuthResult.failure(
        'Failed to disable biometric unlock: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> changeMasterPassword({
    required String currentMasterPassword,
    required String newMasterPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.changeMasterPassword(
        currentMasterPassword: currentMasterPassword,
        newMasterPassword: newMasterPassword,
      );

      if (!result.success) {
        _setError(result.error ?? 'Failed to change master password');
      }

      return result;
    } catch (e) {
      _setError('Failed to change master password: ${e.toString()}');
      return AuthResult.failure(
        'Failed to change master password: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> recoverAccount({
    required String email,
    required String password,
    required String recoveryKey,
    required String newMasterPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.recoverAccount(
        email: email,
        password: password,
        recoveryKey: recoveryKey,
        newMasterPassword: newMasterPassword,
      );

      if (result.success) {
        _isAuthenticated = true;
        _isVaultUnlocked = true;
        await _storageService.updateLastActiveTime();
      } else {
        _setError(result.error ?? 'Account recovery failed');
      }

      return result;
    } catch (e) {
      _setError('Account recovery failed: ${e.toString()}');
      return AuthResult.failure('Account recovery failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      _isAuthenticated = false;
      _isVaultUnlocked = false;
      await _storageService.clearAllData();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> lockVault() async {
    await _authService.lockVault();
    _isVaultUnlocked = false;
    notifyListeners();
  }

  Future<bool> isBiometricUnlockEnabled() async {
    return await _authService.isBiometricUnlockEnabled();
  }

  Future<bool> checkBiometricAvailability() async {
    return await _authService.checkBiometricAvailability();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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
