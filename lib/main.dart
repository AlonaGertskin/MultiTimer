import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'font_licence.dart';
import 'home_page.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicence();
  await NotificationService.instance.init();
  runApp(
    MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const MyMainPage(),
    ),
  );
}
