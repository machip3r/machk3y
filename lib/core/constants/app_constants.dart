class AppConstants {
  // App Info
  static const String appName = 'MachK3y';
  static const String appVersion = '1.0.0';

  // Security
  static const int pbkdf2Iterations = 100000;
  static const int keyLength = 256; // bits
  static const int nonceLength = 12; // bytes for AES-GCM

  // Storage Keys
  static const String masterPasswordKey = 'master_password_hash';
  static const String saltKey = 'user_salt';
  static const String recoveryKeyKey = 'recovery_key';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String autoLockTimeoutKey = 'auto_lock_timeout';
  static const String clipboardTimeoutKey = 'clipboard_timeout';

  // Timeouts
  static const int defaultAutoLockMinutes = 5;
  static const int defaultClipboardSeconds = 30;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // Password Generator
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int defaultPasswordLength = 16;

  // API Endpoints
  static const String hibpApiUrl = 'https://api.pwnedpasswords.com/range/';
  static const String faviconApiUrl =
      'https://www.google.com/s2/favicons?domain=';

  // Credential Types
  static const List<String> credentialTypes = [
    'email',
    'website',
    'card',
    'social',
    'other',
  ];

  // Default Tags
  static const List<String> defaultTags = [
    'work',
    'personal',
    'finance',
    'social',
    'entertainment',
    'shopping',
    'utilities',
    'travel',
  ];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI Constants
  static const double borderRadius = 16.0;
  static const double cardElevation = 4.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
}
