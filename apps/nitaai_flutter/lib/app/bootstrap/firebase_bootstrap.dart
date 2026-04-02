import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

Future<void> initializeFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
