
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ai_business_post_maker/screens/login_screen.dart';
import 'package:ai_business_post_maker/screens/admin_web_login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasAdminWebCode =
        kIsWeb && Uri.base.queryParameters.containsKey('code');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Business Post Maker',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),

      home: hasAdminWebCode
          ? const AdminWebLoginScreen()
          : const LoginScreen(),
    );
  }
}
