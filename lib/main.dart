
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'chat_screen.dart';
import 'spike/encryption_spike.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await runEncryptionSpike();

  runApp(const DaskoApp());
}
