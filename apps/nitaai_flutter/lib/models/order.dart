import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final num unitPrice;

  num get lineTotal => unitPrice * quantity;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  static OrderItem fromJson(Map<String, Object?> json) {
    return OrderItem(
      name: (json['name'] as String?) ?? '',
      quantity: (json['quantity'] as int?) ?? 0,
      unitPrice: (json['unitPrice'] as num?) ?? 0,
    );
  }
}

class Order {
  const Order({
    required this.orderId,
    required this.userId,
    required this.vendorId,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.driverId,
    this.deliveryAddress,
    this.notes,
  });

  final String orderId;
  final String userId;
  final String vendorId;
  final String? driverId;
  final String status;
  final List<OrderItem> items;
  final num totalAmount;
  final String? deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'vendorId': vendorId,
      'driverId': driverId,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Order fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((item) => OrderItem.fromJson(Map<String, Object?>.from(item)))
            .toList()
        : <OrderItem>[];

    return Order(
      orderId: (json['orderId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      vendorId: (json['vendorId'] as String?) ?? '',
      driverId: json['driverId'] as String?,
      status: (json['status'] as String?) ?? 'placed',
      items: items,
      totalAmount: (json['totalAmount'] as num?) ?? 0,
      deliveryAddress: json['deliveryAddress'] as String?,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
