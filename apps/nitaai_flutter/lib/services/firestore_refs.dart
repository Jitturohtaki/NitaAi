import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase/firebase_paths.dart';

class FirestoreRefs {
  FirestoreRefs({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> users() => _firestore.collection(FirebasePaths.users);
  DocumentReference<Map<String, Object?>> user(String uid) => users().doc(uid);

  CollectionReference<Map<String, Object?>> vendors() => _firestore.collection(FirebasePaths.vendors);
  DocumentReference<Map<String, Object?>> vendor(String vendorId) => vendors().doc(vendorId);

  CollectionReference<Map<String, Object?>> drivers() => _firestore.collection(FirebasePaths.drivers);
  DocumentReference<Map<String, Object?>> driver(String driverId) => drivers().doc(driverId);

  CollectionReference<Map<String, Object?>> orders() => _firestore.collection(FirebasePaths.orders);
  DocumentReference<Map<String, Object?>> order(String orderId) => orders().doc(orderId);

  CollectionReference<Map<String, Object?>> chats() => _firestore.collection(FirebasePaths.chats);
  DocumentReference<Map<String, Object?>> chat(String chatId) => chats().doc(chatId);
  CollectionReference<Map<String, Object?>> chatMessages({String chatId = 'default_thread'}) =>
      chat(chatId).collection(FirebasePaths.messages);
}
