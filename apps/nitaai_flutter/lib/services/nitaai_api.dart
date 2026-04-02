import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../firebase_options.dart';
import '../models/chat_message.dart';
import '../models/driver.dart';
import '../models/order.dart';
import '../models/tracking_view_data.dart';
import '../models/vendor.dart';
import 'firestore_refs.dart';

class NitaAiApi {
  NitaAiApi({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  late final FirestoreRefs _refs = FirestoreRefs(firestore: _firestore);
  final StreamController<int> _demoChanges = StreamController<int>.broadcast();

  final Vendor _demoVendor = Vendor(
    vendorId: 'vendor_demo',
    storeName: 'Nita Fresh Kitchen',
    phoneNumber: '+91 99999 10000',
    address: 'Bandra Kurla Complex, Mumbai',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final Driver _demoDriver = Driver(
    driverId: 'driver_demo',
    fullName: 'Rohan Patil',
    phoneNumber: '+91 99999 20000',
    vehicleNumber: 'MH 01 AB 1234',
    isAvailable: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  late List<ChatMessage> _demoMessages = <ChatMessage>[
    ChatMessage(
      id: 'welcome_assistant',
      text: 'Hi! I can help you review your cart, delivery ETA, or order status.',
      role: 'assistant',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      id: 'welcome_user',
      text: 'Great, show me what is in my cart.',
      role: 'user',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: 'welcome_reply',
      text: 'You have a millet bowl, iced coffee, and banana bread ready to place.',
      role: 'assistant',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  late Order _demoCart = Order(
    orderId: 'draft_order_001',
    userId: 'demo_user',
    vendorId: _demoVendor.vendorId,
    driverId: _demoDriver.driverId,
    status: 'draft',
    items: const <OrderItem>[
      OrderItem(name: 'Millet Power Bowl', quantity: 1, unitPrice: 189),
      OrderItem(name: 'Cold Coffee', quantity: 2, unitPrice: 99),
      OrderItem(name: 'Banana Bread', quantity: 1, unitPrice: 79),
    ],
    totalAmount: 466,
    deliveryAddress: 'Nita Towers, Powai, Mumbai',
    notes: 'No sugar in coffee, please.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  bool get isLive => DefaultFirebaseOptions.isConfigured;

  Stream<List<ChatMessage>> watchMessages() {
    if (isLive) {
      return _refs
          .chatMessages()
          .orderBy('createdAt')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ChatMessage.fromJson(doc.data()))
                .toList(),
          );
    }

    return _demoChanges.stream
        .startWith(0)
        .map((_) => List<ChatMessage>.unmodifiable(_demoMessages));
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final userMessage = ChatMessage(
      id: 'user_${now.microsecondsSinceEpoch}',
      text: trimmed,
      role: 'user',
      createdAt: now,
    );

    if (isLive) {
      await _refs.chatMessages().doc(userMessage.id).set(userMessage.toJson());

      final assistantReply = ChatMessage(
        id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
        text: _buildAssistantReply(trimmed),
        role: 'assistant',
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      );
      await _refs.chatMessages().doc(assistantReply.id).set(assistantReply.toJson());
      return;
    }

    _demoMessages = <ChatMessage>[..._demoMessages, userMessage];
    _emitDemoChange();

    final assistantReply = ChatMessage(
      id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
      text: _buildAssistantReply(trimmed),
      role: 'assistant',
      createdAt: DateTime.now(),
    );
    _demoMessages = <ChatMessage>[..._demoMessages, assistantReply];
    _emitDemoChange();
  }

  Stream<Order> watchCart() {
    if (isLive) {
      return _refs
          .orders()
          .where('status', isEqualTo: 'draft')
          .limit(1)
          .snapshots()
          .map((snapshot) {
            final doc = snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
            if (doc == null) {
              return _emptyDraftOrder();
            }
            return Order.fromJson(doc.data());
          });
    }

    return _demoChanges.stream.startWith(0).map((_) => _demoCart);
  }

  Future<void> placeOrder() async {
    if (isLive) {
      final snapshot = await _refs.orders().where('status', isEqualTo: 'draft').limit(1).get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final doc = snapshot.docs.first;
      await doc.reference.update({
        'status': 'confirmed',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return;
    }

    _demoCart = Order(
      orderId: _demoCart.orderId,
      userId: _demoCart.userId,
      vendorId: _demoCart.vendorId,
      driverId: _demoCart.driverId,
      status: 'on_the_way',
      items: _demoCart.items,
      totalAmount: _demoCart.totalAmount,
      deliveryAddress: _demoCart.deliveryAddress,
      notes: _demoCart.notes,
      createdAt: _demoCart.createdAt,
      updatedAt: DateTime.now(),
    );
    _emitDemoChange();
  }

  Stream<TrackingViewData?> watchTracking() async* {
    if (isLive) {
      await for (final orderSnapshot in _refs.orders().snapshots()) {
        final orders = orderSnapshot.docs
            .map((doc) => Order.fromJson(doc.data()))
            .where((order) => order.status != 'draft')
            .toList();

        if (orders.isEmpty) {
          yield null;
          continue;
        }

        orders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final order = orders.first;
        final vendor = await _loadVendor(order.vendorId);
        final driver = order.driverId == null ? null : await _loadDriver(order.driverId!);

        yield TrackingViewData(order: order, vendor: vendor, driver: driver);
      }
      return;
    }

    yield* _demoChanges.stream.startWith(0).map(
          (_) => TrackingViewData(
            order: _demoCart.status == 'draft'
                ? Order(
                    orderId: _demoCart.orderId,
                    userId: _demoCart.userId,
                    vendorId: _demoCart.vendorId,
                    driverId: _demoCart.driverId,
                    status: 'preparing',
                    items: _demoCart.items,
                    totalAmount: _demoCart.totalAmount,
                    deliveryAddress: _demoCart.deliveryAddress,
                    notes: _demoCart.notes,
                    createdAt: _demoCart.createdAt,
                    updatedAt: _demoCart.updatedAt,
                  )
                : _demoCart,
            vendor: _demoVendor,
            driver: _demoDriver,
          ),
        );
  }

  Future<Vendor?> _loadVendor(String vendorId) async {
    final snapshot = await _refs.vendor(vendorId).get();
    final data = snapshot.data();
    return data == null ? null : Vendor.fromJson(data);
  }

  Future<Driver?> _loadDriver(String driverId) async {
    final snapshot = await _refs.driver(driverId).get();
    final data = snapshot.data();
    return data == null ? null : Driver.fromJson(data);
  }

  Order _emptyDraftOrder() {
    final now = DateTime.now();
    return Order(
      orderId: 'empty_draft',
      userId: '',
      vendorId: '',
      status: 'draft',
      items: const <OrderItem>[],
      totalAmount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _buildAssistantReply(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('track') || lower.contains('delivery')) {
      return 'Your rider is on the way and should arrive in about 12 minutes.';
    }
    if (lower.contains('cart') || lower.contains('order')) {
      return 'Your cart total is Rs. ${_demoCart.totalAmount.toStringAsFixed(0)} with 4 items ready for checkout.';
    }
    return 'Got it. I saved that in the conversation and can help with checkout or tracking next.';
  }

  void _emitDemoChange() {
    _demoChanges.add(DateTime.now().millisecondsSinceEpoch);
  }
}

extension StreamInitialValue<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
