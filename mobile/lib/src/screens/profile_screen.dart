import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 32, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user.role.label, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Telefon'),
                  subtitle: Text(user.phone.isEmpty ? 'Nie podano' : user.phone),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Adres'),
                  subtitle: Text(user.address ?? 'Nie podano'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data rejestracji'),
                  subtitle: Text(
                    '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Ustawienia'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Pomoc'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('O aplikacji'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Sąsiedzi & Seniorzy',
                      applicationVersion: '1.0.0',
                      children: [
                        const Text('Platforma łącząca sąsiadów z seniorami w Polsce.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Wyloguj się'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
