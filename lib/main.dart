import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The cockpit / rocket UI is designed portrait-only — lock orientation so
  // rotating to landscape can't overflow the fixed-height layouts.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Fire-and-forget: notification setup requests OS permission, which on a fresh
  // browser shows a native prompt. Awaiting it here would block the first paint
  // (white screen) until the user answers. Nothing in runApp depends on init()
  // having finished, so let the UI render and wire notifications in the
  // background.
  unawaited(NotificationService.instance.init());
  runApp(const MomentumApp());
}
