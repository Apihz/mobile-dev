import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check protects the Firebase AI Logic (Gemini) endpoint from abuse.
  // It's skipped in debug builds (e.g. the iOS Simulator, where attestation
  // fails) — that's fine because the AI Logic API is left "unenforced" during
  // development. Release builds activate it with real attestation providers.
  if (kReleaseMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidPlayIntegrityProvider(),
      providerApple: AppleDeviceCheckProvider(),
      providerWeb: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
  }

  runApp(const KanbanBoardApp());
}
