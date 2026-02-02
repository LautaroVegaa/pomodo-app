import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    PomodoApp(
      notificationService: notificationService,
      startSignedIn: false,
    ),
  );
}
