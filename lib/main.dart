import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The chat prototype is local-first and must remain launchable even when
  // optional Firebase configuration is unavailable on a development device.
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    debugPrint('Dasko AI: Firebase initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const DaskoApp());
}
