import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (_) {
    // Keep the local-first prototype launchable if Firebase is unavailable.
    // Do not log raw exception text or stack details.
    debugPrint('Dasko AI: Firebase initialization skipped.');
  }

  final crashlyticsSupportedPlatform = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  if (firebaseInitialized && crashlyticsSupportedPlatform) {
    final crashlytics = FirebaseCrashlytics.instance;

    FlutterError.onError = (details) {
      _recordSanitizedNonFatal(
        crashlytics: crashlytics,
        error: details.exception,
        stackTrace: details.stack,
        source: 'Flutter framework',
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _recordSanitizedNonFatal(
        crashlytics: crashlytics,
        error: error,
        stackTrace: stackTrace,
        source: 'uncaught asynchronous',
      );
      return true;
    };
  }

  runApp(const DaskoApp());
}

void _recordSanitizedNonFatal({
  required FirebaseCrashlytics crashlytics,
  required Object error,
  required StackTrace? stackTrace,
  required String source,
}) {
  // Report only the error type, a fixed source label, and stack frames.
  // Never pass exception text, Flutter diagnostics, chat content, or API keys.
  final safeError = StateError(
    'Unhandled $source error (${error.runtimeType})',
  );

  unawaited(
    crashlytics
        .recordError(
          safeError,
          stackTrace,
          reason: 'Unhandled $source error',
          fatal: false,
          printDetails: false,
        )
        .catchError((Object _) {}),
  );
}
