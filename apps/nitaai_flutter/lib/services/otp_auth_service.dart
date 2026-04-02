import 'package:firebase_auth/firebase_auth.dart';

class OtpAuthService {
  OtpAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(UserCredential credential) autoVerified,
    required void Function(FirebaseAuthException error) onError,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final credentialResult = await _auth.signInWithCredential(credential);
          autoVerified(credentialResult);
        } on FirebaseAuthException catch (e) {
          onError(e);
        }
      },
      verificationFailed: onError,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}
