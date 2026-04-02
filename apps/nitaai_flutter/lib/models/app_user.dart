import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
  });

  final String uid;
  final String phoneNumber;
  final String role;
  final String? displayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'role': role,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static AppUser fromJson(Map<String, Object?> json) {
    return AppUser(
      uid: (json['uid'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'user',
      displayName: json['displayName'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
