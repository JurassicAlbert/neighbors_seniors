import 'package:flutter/material.dart';
import 'src/services/admin_api_service.dart';
import 'src/screens/admin_login_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AdminApiService();
    return MaterialApp(
      title: 'Sąsiedzi & Seniorzy - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: AdminLoginScreen(api: api),
    );
  }
}
