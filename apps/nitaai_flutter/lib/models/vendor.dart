import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  const Vendor({
    required this.vendorId,
    required this.storeName,
    required this.phoneNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.address,
  });

  final String vendorId;
  final String storeName;
  final String phoneNumber;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'vendorId': vendorId,
      'storeName': storeName,
      'phoneNumber': phoneNumber,
      'address': address,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Vendor fromJson(Map<String, Object?> json) {
    return Vendor(
      vendorId: (json['vendorId'] as String?) ?? '',
      storeName: (json['storeName'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      address: json['address'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
