import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.family;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejestracja')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Wybierz typ konta:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...[UserRole.senior, UserRole.family, UserRole.worker].map(
                (role) => RadioListTile<UserRole>(
                  title: Text(role.label),
                  subtitle: Text(_roleDescription(role)),
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Imię i nazwisko',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Podaj imię' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Podaj prawidłowy email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numer telefonu',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  hintText: '+48...',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Podaj numer telefonu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  prefixIcon: Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 8) return 'Min. 8 znaków';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Consumer<AuthProvider>(
                builder: (_, auth, __) {
                  if (auth.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => FilledButton(
                  onPressed: auth.loading ? null : _register,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: auth.loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Zarejestruj się', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.senior:
        return 'Potrzebuję pomocy w codziennych sprawach';
      case UserRole.family:
        return 'Chcę zamawiać usługi dla bliskich seniorów';
      case UserRole.worker:
        return 'Chcę świadczyć usługi i pomagać';
      case UserRole.admin:
        return '';
    }
  }
}
