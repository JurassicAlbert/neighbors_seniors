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
  List<EquipmentModel>? _equipment;
  List<DisputeModel>? _disputes;
  List<ServiceOffer>? _serviceOffers;
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
      _equipment = await widget.api.getEquipment();
      _disputes = await widget.api.getDisputes();
      _serviceOffers = await widget.api.getServiceOffers();
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
              NavigationRailDestination(icon: Icon(Icons.build), label: Text('Sprzęt')),
              NavigationRailDestination(icon: Icon(Icons.gavel), label: Text('Spory')),
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
      case 5:
        return _buildEquipmentPage();
      case 6:
        return _buildDisputesPage();
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
              _statCard('Sprzęt', '${_stats!.totalEquipment}', Icons.build, Colors.brown),
              _statCard('Rezerwacje', '${_stats!.activeReservations}', Icons.event_available, Colors.cyan),
              _statCard('Spory', '${_stats!.openDisputes}', Icons.gavel, Colors.red),
              _statCard('Znajomości', '${_stats!.totalFriendships}', Icons.people_outline, Colors.pink),
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

  Widget _buildEquipmentPage() {
    if (_equipment == null) return const Center(child: Text('Brak danych'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text('Sprzęt (${_equipment!.length})', style: Theme.of(context).textTheme.headlineSmall),
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
                DataColumn(label: Text('Tytuł')),
                DataColumn(label: Text('Kategoria')),
                DataColumn(label: Text('Stan')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Cena')),
                DataColumn(label: Text('Właściciel')),
                DataColumn(label: Text('Data')),
              ],
              rows: _equipment!.map((eq) => DataRow(cells: [
                DataCell(Text(eq.title)),
                DataCell(Text('${eq.category.icon} ${eq.category.label}')),
                DataCell(Text(eq.condition.name)),
                DataCell(Text(eq.status.label)),
                DataCell(Text('${eq.pricePerUnit.toStringAsFixed(2)} zł/${eq.priceUnit.name}')),
                DataCell(Text(eq.owner?.name ?? eq.ownerId)),
                DataCell(Text('${eq.createdAt.day}.${eq.createdAt.month}.${eq.createdAt.year}')),
              ])).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisputesPage() {
    if (_disputes == null) return const Center(child: Text('Brak danych'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Spory (${_disputes!.length})',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: _disputes!.isEmpty
              ? const Center(child: Text('Brak sporów'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _disputes!.length,
                  itemBuilder: (_, i) {
                    final dispute = _disputes![i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(dispute.type.name, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dispute.status == DisputeStatus.open
                                        ? Colors.red.withAlpha(30)
                                        : dispute.status == DisputeStatus.resolved
                                            ? Colors.green.withAlpha(30)
                                            : Colors.orange.withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    dispute.status.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: dispute.status == DisputeStatus.open
                                          ? Colors.red
                                          : dispute.status == DisputeStatus.resolved
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(dispute.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(dispute.description, style: TextStyle(color: Colors.grey[700])),
                            if (dispute.status != DisputeStatus.resolved && dispute.status != DisputeStatus.closed) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: () => _showResolveDialog(dispute),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Rozwiąż'),
                                ),
                              ),
                            ],
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

  void _showResolveDialog(DisputeModel dispute) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rozwiąż spor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Opis rozwiązania',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await widget.api.resolveDispute(dispute.id, controller.text.trim());
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                }
              }
            },
            child: const Text('Zatwierdź'),
          ),
        ],
      ),
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
                  _reportRow('Sprzęt', '${_stats!.totalEquipment}'),
                  _reportRow('Aktywne rezerwacje', '${_stats!.activeReservations}'),
                  _reportRow('Otwarte spory', '${_stats!.openDisputes}'),
                  _reportRow('Łączne znajomości', '${_stats!.totalFriendships}'),
                  _reportRow('Oferty usług', '${_serviceOffers?.length ?? 0}'),
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Smart Village / Paramedical Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _reportRow('🏥 Opieka paramedyczna', '${_stats!.ordersByType['paramedical'] ?? 0}'),
                  _reportRow('❤️ Opieka domowa', '${_stats!.ordersByType['caregiving'] ?? 0}'),
                  _reportRow('🏠 Wymiana mieszkaniowa', '${_stats!.ordersByType['housing'] ?? 0}'),
                  _reportRow('🤝 Wolontariat', '${_stats!.ordersByType['volunteer'] ?? 0}'),
                  _reportRow('🛠️ Udostępnianie narzędzi', '${_stats!.ordersByType['toolSharing'] ?? 0}'),
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
