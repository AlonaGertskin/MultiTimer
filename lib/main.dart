import 'package:flutter/material.dart';
import 'home_page.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const MaterialApp(home: MyMainPage()));
}
