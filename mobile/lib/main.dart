import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/api_service.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/order_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';

void main() {
  runApp(const NeighborsSeniorsApp());
}

class NeighborsSeniorsApp extends StatelessWidget {
  const NeighborsSeniorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'Sąsiedzi & Seniorzy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
          brightness: Brightness.light,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          cardTheme: CardTheme(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        home: const AppStartup(),
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.tryAutoLogin();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => success ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text(
              'Sąsiedzi & Seniorzy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
