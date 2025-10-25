import 'package:uuid/uuid.dart';

enum CredentialType { email, website, card, social, other }

enum PasswordStrength { weak, medium, strong }

class Credential {
  final String id;
  final String userId;
  final CredentialType type;
  final String title;
  final Map<String, dynamic> data;
  final List<String> tags;
  final String? faviconUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isStarred;
  final bool isShared;

  Credential({
    String? id,
    required this.userId,
    required this.type,
    required this.title,
    required this.data,
    this.tags = const [],
    this.faviconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isStarred = false,
    this.isShared = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'],
      userId: json['user_id'],
      type: CredentialType.values.firstWhere(
        (e) => e.toString().split('.').last == json['credential_type'],
        orElse: () => CredentialType.other,
      ),
      title: json['title'] ?? '',
      data: json['data'] ?? {},
      tags: List<String>.from(json['tags'] ?? []),
      faviconUrl: json['favicon_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isStarred: json['is_starred'] ?? false,
      isShared: json['is_shared'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'credential_type': type.toString().split('.').last,
      'title': title,
      'data': data,
      'tags': tags,
      'favicon_url': faviconUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_starred': isStarred,
      'is_shared': isShared,
    };
  }

  Credential copyWith({
    String? id,
    String? userId,
    CredentialType? type,
    String? title,
    Map<String, dynamic>? data,
    List<String>? tags,
    String? faviconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarred,
    bool? isShared,
  }) {
    return Credential(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      data: data ?? this.data,
      tags: tags ?? this.tags,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
      isShared: isShared ?? this.isShared,
    );
  }

  // Helper methods for different credential types
  String get username {
    switch (type) {
      case CredentialType.email:
        return data['email'] ?? '';
      case CredentialType.website:
        return data['username'] ?? '';
      case CredentialType.social:
        return data['username'] ?? '';
      case CredentialType.card:
        return data['cardholder'] ?? '';
      case CredentialType.other:
        return data['username'] ?? '';
    }
  }

  String get password {
    return data['password'] ?? '';
  }

  String get url {
    switch (type) {
      case CredentialType.website:
        return data['url'] ?? '';
      case CredentialType.email:
        return 'mailto:${data['email']}';
      default:
        return '';
    }
  }

  String get displayTitle {
    if (title.isNotEmpty) return title;

    switch (type) {
      case CredentialType.email:
        return data['email'] ?? 'Email Account';
      case CredentialType.website:
        return data['url'] ?? 'Website';
      case CredentialType.card:
        return data['bank'] ?? 'Credit Card';
      case CredentialType.social:
        return data['platform'] ?? 'Social Media';
      case CredentialType.other:
        return 'Other';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Credential && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserSettings {
  final String id;
  final String userId;
  final String salt;
  final String? encryptedRecoveryKey;
  final DateTime createdAt;

  UserSettings({
    String? id,
    required this.userId,
    required this.salt,
    this.encryptedRecoveryKey,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'],
      userId: json['user_id'],
      salt: json['salt'],
      encryptedRecoveryKey: json['encrypted_recovery_key'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'salt': salt,
      'encrypted_recovery_key': encryptedRecoveryKey,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PasswordAnalysis {
  final PasswordStrength strength;
  final int score;
  final bool isCompromised;
  final bool isReused;
  final int ageInDays;
  final List<String> issues;

  PasswordAnalysis({
    required this.strength,
    required this.score,
    this.isCompromised = false,
    this.isReused = false,
    this.ageInDays = 0,
    this.issues = const [],
  });

  String get strengthText {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  String get strengthDescription {
    switch (strength) {
      case PasswordStrength.weak:
        return 'This password is weak and should be changed';
      case PasswordStrength.medium:
        return 'This password is okay but could be stronger';
      case PasswordStrength.strong:
        return 'This password is strong and secure';
    }
  }
}

class SecurityStats {
  final int totalCredentials;
  final int weakPasswords;
  final int compromisedPasswords;
  final int reusedPasswords;
  final int strongPasswords;
  final double securityScore;

  SecurityStats({
    required this.totalCredentials,
    required this.weakPasswords,
    required this.compromisedPasswords,
    required this.reusedPasswords,
    required this.strongPasswords,
    required this.securityScore,
  });

  factory SecurityStats.empty() {
    return SecurityStats(
      totalCredentials: 0,
      weakPasswords: 0,
      compromisedPasswords: 0,
      reusedPasswords: 0,
      strongPasswords: 0,
      securityScore: 0.0,
    );
  }
}

class SharedCredential {
  final String id;
  final String credentialId;
  final String sharedBy;
  final String sharedWith;
  final String encryptedForRecipient;
  final DateTime createdAt;

  SharedCredential({
    String? id,
    required this.credentialId,
    required this.sharedBy,
    required this.sharedWith,
    required this.encryptedForRecipient,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory SharedCredential.fromJson(Map<String, dynamic> json) {
    return SharedCredential(
      id: json['id'],
      credentialId: json['credential_id'],
      sharedBy: json['shared_by'],
      sharedWith: json['shared_with'],
      encryptedForRecipient: json['encrypted_for_recipient'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credential_id': credentialId,
      'shared_by': sharedBy,
      'shared_with': sharedWith,
      'encrypted_for_recipient': encryptedForRecipient,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
