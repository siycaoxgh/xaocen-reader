import 'package:flutter/foundation.dart';

/// Stable local identity for one user's profile.
///
/// A profile is an application/domain identity.  It deliberately contains no
/// [DataRoot], directory, database, account session, or network state.  The
/// local storage implementation maps this identity to a DataRoot separately.
@immutable
final class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
  });

  static const String defaultId = 'default';
  static const String defaultDisplayName = '默认用户';

  final String id;
  final String displayName;

  /// Reserved for a future authenticated account mapping.  It is not used by
  /// the local profile registry in this stage.
  final String? accountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDefault => id == defaultId;

  UserProfile copyWith({
    String? displayName,
    String? accountId,
    bool clearAccountId = false,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      accountId: clearAccountId ? null : accountId ?? this.accountId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'formatVersion': 1,
    'id': id,
    'displayName': displayName,
    if (accountId != null) 'accountId': accountId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static UserProfile fromJson(Object? value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['displayName'] is! String ||
        value['createdAt'] is! String ||
        value['updatedAt'] is! String) {
      throw const FormatException('invalid user profile');
    }
    final createdAt = DateTime.tryParse(value['createdAt'] as String);
    final updatedAt = DateTime.tryParse(value['updatedAt'] as String);
    if (createdAt == null || updatedAt == null) {
      throw const FormatException('invalid user profile timestamp');
    }
    final accountId = value['accountId'];
    if (accountId != null && accountId is! String) {
      throw const FormatException('invalid user profile account id');
    }
    return UserProfile(
      id: value['id'] as String,
      displayName: value['displayName'] as String,
      accountId: accountId as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfile &&
        other.id == id &&
        other.displayName == displayName &&
        other.accountId == accountId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, accountId, createdAt, updatedAt);
}
