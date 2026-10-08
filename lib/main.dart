import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'home_page.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(
    MaterialApp(
      theme: ThemeData(
        colorScheme: lightColors,
        scaffoldBackgroundColor: lightColors.surfaceContainer,
        appBarTheme: AppBarTheme(backgroundColor: lightColors.surfaceContainer),
        cardTheme: CardThemeData(color: readyCardColor(lightColors)),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColors,
        cardTheme: CardThemeData(color: readyCardColor(darkColors)),
      ),
      home: const MyMainPage(),
    ),
  );
}
