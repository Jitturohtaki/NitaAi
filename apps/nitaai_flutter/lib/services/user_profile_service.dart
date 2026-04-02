import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'firestore_refs.dart';

class UserProfileService {
  UserProfileService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _refs = FirestoreRefs(firestore: firestore);

  final FirebaseAuth _auth;
  final FirestoreRefs _refs;

  Future<void> ensureUserProfile({String defaultRole = 'user'}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Not signed in');
    }

    final now = DateTime.now();
    final uid = currentUser.uid;
    final phoneNumber = currentUser.phoneNumber ?? '';

    await _refs.users().doc(uid).set(
      AppUser(
        uid: uid,
        phoneNumber: phoneNumber,
        role: defaultRole,
        createdAt: now,
        updatedAt: now,
      ).toJson(),
      SetOptions(merge: true),
    );
  }
}
