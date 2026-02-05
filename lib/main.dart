import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureFirebaseInitialized();
  tz.initializeTimeZones();

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();
  final bool startSignedIn = FirebaseAuth.instance.currentUser != null;

  runApp(
    PomodoApp(
      notificationService: notificationService,
      startSignedIn: startSignedIn,
    ),
  );
}

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    Firebase.app();
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code == 'duplicate-app') {
      Firebase.app();
      return;
    }
    rethrow;
  }
}
