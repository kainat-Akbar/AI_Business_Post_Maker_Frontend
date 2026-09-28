import 'package:flutter/material.dart';
import 'screens/admin_web_login_screen.dart';

void main() {
  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Business Post Maker Admin',
      home: const AdminWebLoginScreen(),
    );
  }
}