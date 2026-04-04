import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/bootstrap/firebase_bootstrap.dart';
import 'app/nitaai_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initializeFirebase();
  runApp(const NitaAiApp());
}
