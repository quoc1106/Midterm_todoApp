/// 🔐 USER MODEL - Authentication Data Structure
///
/// ⭐ RIVERPOD LEVEL 1 FOUNDATION ⭐
/// User model với Hive persistence cho authentication system
/// Supports username-based multi-user data separation

import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

part 'user.g.dart';

@HiveType(typeId: 10) // New typeId for User model
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String hashedPassword;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastLoginAt;

  @HiveField(5)
  final String email;

  @HiveField(6)
  final String displayName;

  User({
    required this.id,
    required this.username,
    required this.hashedPassword,
    required this.createdAt,
    required this.lastLoginAt,
    required this.email,
    required this.displayName,
  });

  /// Factory constructor for new user registration
  factory User.register({
    required String username,
    required String password,
    required String email,
    required String displayName,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final hashedPassword = _hashPassword(password);
    final now = DateTime.now();

    return User(
      id: id,
      username: username.toLowerCase().trim(),
      hashedPassword: hashedPassword,
      createdAt: now,
      lastLoginAt: now,
      email: email.toLowerCase().trim(),
      displayName: displayName.trim(),
    );
  }

  /// Verify password for login
  bool verifyPassword(String password) {
    return hashedPassword == _hashPassword(password);
  }

  /// Update last login time
  User updateLastLogin() {
    return User(
      id: id,
      username: username,
      hashedPassword: hashedPassword,
      createdAt: createdAt,
      lastLoginAt: DateTime.now(),
      email: email,
      displayName: displayName,
    );
  }

  /// Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Copy with method for immutable updates
  User copyWith({
    String? username,
    String? hashedPassword,
    DateTime? lastLoginAt,
    String? email,
    String? displayName,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, displayName: $displayName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
