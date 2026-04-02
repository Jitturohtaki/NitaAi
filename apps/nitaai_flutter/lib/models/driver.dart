import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  const Driver({
    required this.driverId,
    required this.fullName,
    required this.phoneNumber,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.vehicleNumber,
  });

  final String driverId;
  final String fullName;
  final String phoneNumber;
  final String? vehicleNumber;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'driverId': driverId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'vehicleNumber': vehicleNumber,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Driver fromJson(Map<String, Object?> json) {
    return Driver(
      driverId: (json['driverId'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      vehicleNumber: json['vehicleNumber'] as String?,
      isAvailable: (json['isAvailable'] as bool?) ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
