import 'package:flutter/material.dart';

import 'app/bootstrap/firebase_bootstrap.dart';
import 'app/nitaai_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const NitaAiApp());
}
