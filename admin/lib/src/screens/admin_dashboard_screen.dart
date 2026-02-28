import 'package:flutter/material.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../services/admin_api_service.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminApiService api;
  const AdminDashboardScreen({super.key, required this.api});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  StatsModel? _stats;
  List<UserModel>? _users;
  List<OrderModel>? _orders;
  List<UserModel>? _verifications;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _stats = await widget.api.getStats();
      _users = await widget.api.getUsers();
      _orders = await widget.api.getOrders();
      _verifications = await widget.api.getPendingVerifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            extended: MediaQuery.of(context).size.width > 900,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.admin_panel_settings, color: Theme.of(context).primaryColor, size: 32),
                  const SizedBox(height: 4),
                  const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      widget.api.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => AdminLoginScreen(api: widget.api)),
                      );
                    },
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Użytkownicy')),
              NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Zlecenia')),
              NavigationRailDestination(icon: Icon(Icons.verified_user), label: Text('Weryfikacje')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Raporty')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsersPage();
      case 2:
        return _buildOrdersPage();
      case 3:
        return _buildVerificationsPage();
      case 4:
        return _buildReportsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard() {
    if (_stats == null) return const Center(child: Text('Brak danych'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard('Użytkownicy', '${_stats!.totalUsers}', Icons.people, Colors.blue),
              _statCard('Zlecenia', '${_stats!.totalOrders}', Icons.list_alt, Colors.green),
              _statCard('Aktywne', '${_stats!.activeOrders}', Icons.pending_actions, Colors.orange),
              _statCard('Zakończone', '${_stats!.completedOrders}', Icons.done_all, Colors.teal),
              _statCard('Przychód', '${_stats!.totalRevenue.toStringAsFixed(2)} zł', Icons.payments, Colors.purple),
              _statCard('Prowizja', '${_stats!.totalCommission.toStringAsFixed(2)} zł', Icons.account_balance, Colors.indigo),
              _statCard('Zweryfikowani', '${_stats!.verifiedWorkers}', Icons.verified, Colors.green),
              _statCard('Oczekujące', '${_stats!.pendingVerifications}', Icons.hourglass_top, Colors.amber),
            ],
          ),
          if (_stats!.ordersByType.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('Zlecenia wg typu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _stats!.ordersByType.entries.map((e) {
                    final type = OrderType.values.firstWhere((t) => t.name == e.key, orElse: () => OrderType.volunteer);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(type.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(type.label)),
                          Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersPage() {
    if (_users == null) return const Center(child: Text('Brak danych'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text('Użytkownicy (${_users!.length})', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Imię')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Rola')),
                DataColumn(label: Text('Telefon')),
                DataColumn(label: Text('Status weryfikacji')),
                DataColumn(label: Text('Data rejestracji')),
              ],
              rows: _users!.map((u) => DataRow(cells: [
                DataCell(Text(u.name)),
                DataCell(Text(u.email)),
                DataCell(Text(u.role.label)),
                DataCell(Text(u.phone)),
                DataCell(Text(u.verificationStatus.name)),
                DataCell(Text('${u.createdAt.day}.${u.createdAt.month}.${u.createdAt.year}')),
              ])).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersPage() {
    if (_orders == null) return const Center(child: Text('Brak danych'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text('Zlecenia (${_orders!.length})', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Typ')),
                DataColumn(label: Text('Tytuł')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Cena')),
                DataColumn(label: Text('Prowizja')),
                DataColumn(label: Text('Adres')),
                DataColumn(label: Text('Data')),
              ],
              rows: _orders!.map((o) => DataRow(cells: [
                DataCell(Text('${o.type.icon} ${o.type.label}')),
                DataCell(Text(o.title)),
                DataCell(Text(o.status.label)),
                DataCell(Text(o.price != null ? '${o.price!.toStringAsFixed(2)} zł' : '-')),
                DataCell(Text(o.commission != null ? '${o.commission!.toStringAsFixed(2)} zł' : '-')),
                DataCell(Text(o.address, overflow: TextOverflow.ellipsis)),
                DataCell(Text('${o.createdAt.day}.${o.createdAt.month}.${o.createdAt.year}')),
              ])).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationsPage() {
    if (_verifications == null) return const Center(child: Text('Brak danych'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Oczekujące weryfikacje (${_verifications!.length})',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: _verifications!.isEmpty
              ? const Center(child: Text('Brak oczekujących weryfikacji'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _verifications!.length,
                  itemBuilder: (_, i) {
                    final user = _verifications![i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user.name),
                        subtitle: Text('${user.email} • ${user.phone}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                await widget.api.verifyWorker(user.id);
                                _loadData();
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Weryfikuj'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await widget.api.rejectWorker(user.id);
                                _loadData();
                              },
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Odrzuć'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportsPage() {
    if (_stats == null) return const Center(child: Text('Brak danych'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Raporty i Statystyki', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Dane dla raportów grantowych', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Podsumowanie platformy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _reportRow('Liczba użytkowników', '${_stats!.totalUsers}'),
                  _reportRow('Liczba zleceń', '${_stats!.totalOrders}'),
                  _reportRow('Aktywne zlecenia', '${_stats!.activeOrders}'),
                  _reportRow('Zakończone zlecenia', '${_stats!.completedOrders}'),
                  _reportRow('Łączny przychód', '${_stats!.totalRevenue.toStringAsFixed(2)} zł'),
                  _reportRow('Prowizja platformy', '${_stats!.totalCommission.toStringAsFixed(2)} zł'),
                  _reportRow('Zweryfikowani wykonawcy', '${_stats!.verifiedWorkers}'),
                  _reportRow('Oczekujące weryfikacje', '${_stats!.pendingVerifications}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zlecenia wg kategorii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ..._stats!.ordersByType.entries.map((e) {
                    final type = OrderType.values.firstWhere((t) => t.name == e.key, orElse: () => OrderType.volunteer);
                    return _reportRow('${type.icon} ${type.label}', '${e.value}');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
