import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../models/credential.dart';

class PasswordService {
  static final PasswordService _instance = PasswordService._internal();
  factory PasswordService() => _instance;
  PasswordService._internal();

  final Random _random = Random.secure();

  // Generate random password
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = true,
  }) {
    String chars = '';

    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) chars += '0123456789';
    if (includeSymbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    if (excludeAmbiguous) {
      chars = chars.replaceAll(RegExp(r'[0O1lI]'), '');
    }

    if (chars.isEmpty) chars = 'abcdefghijklmnopqrstuvwxyz';

    return List.generate(
      length,
      (index) => chars[_random.nextInt(chars.length)],
    ).join('');
  }

  // Generate pronounceable password
  String generatePronounceablePassword({int length = 16}) {
    final vowels = 'aeiou';
    final consonants = 'bcdfghjklmnpqrstvwxyz';

    String password = '';
    bool isVowel = _random.nextBool();

    for (int i = 0; i < length; i++) {
      if (isVowel) {
        password += vowels[_random.nextInt(vowels.length)];
      } else {
        password += consonants[_random.nextInt(consonants.length)];
      }
      isVowel = !isVowel;
    }

    return password;
  }

  // Analyze password strength
  PasswordAnalysis analyzePasswordStrength(String password) {
    int score = 0;
    final issues = <String>[];

    // Length checks
    if (password.length < 8) {
      score -= 2;
      issues.add('Password is too short (minimum 8 characters)');
    } else if (password.length >= 12) {
      score += 2;
    }

    if (password.length >= 16) {
      score += 1;
    }

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 1;
    } else {
      issues.add('Add lowercase letters');
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 1;
    } else {
      issues.add('Add uppercase letters');
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 1;
    } else {
      issues.add('Add numbers');
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 2;
    } else {
      issues.add('Add special characters');
    }

    // Pattern checks
    if (_hasSequentialChars(password)) {
      score -= 1;
      issues.add('Avoid sequential characters');
    }

    if (_hasRepeatingChars(password)) {
      score -= 1;
      issues.add('Avoid repeating characters');
    }

    if (_hasCommonPatterns(password)) {
      score -= 1;
      issues.add('Avoid common patterns');
    }

    // Determine strength
    PasswordStrength strength;
    if (score >= 7) {
      strength = PasswordStrength.strong;
    } else if (score >= 5) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.weak;
    }

    return PasswordAnalysis(strength: strength, score: score, issues: issues);
  }

  // Check if password is compromised using HIBP API
  Future<bool> isPasswordCompromised(String password) async {
    try {
      final hash = sha1.convert(utf8.encode(password));
      final hashStr = hash.toString().toUpperCase();
      final prefix = hashStr.substring(0, 5);
      final suffix = hashStr.substring(5);

      final response = await http.get(
        Uri.parse('${AppConstants.hibpApiUrl}$prefix'),
        headers: {'User-Agent': 'MachK3y-PasswordManager'},
      );

      if (response.statusCode == 200) {
        return response.body.contains(suffix);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Check for reused passwords
  List<String> findReusedPasswords(List<Credential> credentials) {
    final passwordCounts = <String, List<String>>{};

    for (final credential in credentials) {
      final password = credential.password;
      if (password.isNotEmpty) {
        passwordCounts.putIfAbsent(password, () => []).add(credential.title);
      }
    }

    final reusedPasswords = <String>[];
    passwordCounts.forEach((password, titles) {
      if (titles.length > 1) {
        reusedPasswords.add(password);
      }
    });

    return reusedPasswords;
  }

  // Get password age in days
  int getPasswordAge(DateTime createdAt) {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Check for weak passwords
  List<Credential> findWeakPasswords(List<Credential> credentials) {
    return credentials.where((credential) {
      final password = credential.password;
      if (password.isEmpty) return false;

      final analysis = analyzePasswordStrength(password);
      return analysis.strength == PasswordStrength.weak;
    }).toList();
  }

  // Check for old passwords (older than 90 days)
  List<Credential> findOldPasswords(List<Credential> credentials) {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

    return credentials.where((credential) {
      return credential.updatedAt.isBefore(cutoffDate);
    }).toList();
  }

  // Generate password suggestions
  List<String> generatePasswordSuggestions({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = true,
  }) {
    final suggestions = <String>[];

    // Generate 5 different passwords
    for (int i = 0; i < 5; i++) {
      suggestions.add(
        generatePassword(
          length: length,
          includeUppercase: includeUppercase,
          includeLowercase: includeLowercase,
          includeNumbers: includeNumbers,
          includeSymbols: includeSymbols,
          excludeAmbiguous: excludeAmbiguous,
        ),
      );
    }

    return suggestions;
  }

  // Validate password requirements
  PasswordValidationResult validatePasswordRequirements(
    String password, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSymbols = true,
  }) {
    final issues = <String>[];

    if (password.length < minLength) {
      issues.add('Password must be at least $minLength characters long');
    }

    if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('Password must contain at least one uppercase letter');
    }

    if (requireLowercase && !RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('Password must contain at least one lowercase letter');
    }

    if (requireNumbers && !RegExp(r'[0-9]').hasMatch(password)) {
      issues.add('Password must contain at least one number');
    }

    if (requireSymbols &&
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      issues.add('Password must contain at least one special character');
    }

    return PasswordValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  // Helper methods
  bool _hasSequentialChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      final char1 = password.codeUnitAt(i);
      final char2 = password.codeUnitAt(i + 1);
      final char3 = password.codeUnitAt(i + 2);

      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }
    }
    return false;
  }

  bool _hasRepeatingChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      final char = password[i];
      if (password[i + 1] == char && password[i + 2] == char) {
        return true;
      }
    }
    return false;
  }

  bool _hasCommonPatterns(String password) {
    final commonPatterns = [
      '123',
      'abc',
      'qwe',
      'asd',
      'zxc',
      'password',
      'admin',
      'user',
      'test',
      'demo',
    ];

    final lowerPassword = password.toLowerCase();
    return commonPatterns.any((pattern) => lowerPassword.contains(pattern));
  }

  // Calculate password entropy
  double calculateEntropy(String password) {
    int charsetSize = 0;

    if (RegExp(r'[a-z]').hasMatch(password)) charsetSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) charsetSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) charsetSize += 10;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) charsetSize += 32;

    if (charsetSize == 0) charsetSize = 26; // Default to lowercase

    return password.length * (log(charsetSize) / ln2);
  }

  // Get password strength color
  String getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '#EF4444'; // Red
      case PasswordStrength.medium:
        return '#F59E0B'; // Amber
      case PasswordStrength.strong:
        return '#10B981'; // Green
    }
  }

  // Get password strength text
  String getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> issues;

  PasswordValidationResult({required this.isValid, required this.issues});
}
