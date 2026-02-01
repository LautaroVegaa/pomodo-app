import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(PomodoApp(notificationService: notificationService));
}
