import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'login_screen.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import 'profile_screen.dart';
import 'equipment_screen.dart';
import 'directory_screen.dart';
import 'friends_screen.dart';
import 'badges_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      final auth = context.read<AuthProvider>();
      orderProvider.loadOrders();
      if (auth.user?.role == UserRole.worker) {
        orderProvider.loadAvailableOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();

    final pages = <Widget>[
      _buildMainPage(user),
      if (user.role == UserRole.worker) _buildAvailableOrdersPage(),
      _buildOrdersPage(user),
      const EquipmentScreen(),
      const DirectoryScreen(),
      const ProfileScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home), label: 'Główna'),
      if (user.role == UserRole.worker)
        const NavigationDestination(icon: Icon(Icons.search), label: 'Dostępne'),
      const NavigationDestination(icon: Icon(Icons.list_alt), label: 'Zlecenia'),
      NavigationDestination(icon: const Icon(Icons.handyman), label: S.equipment),
      NavigationDestination(icon: const Icon(Icons.storefront), label: S.directory),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
    ];

    final safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: destinations,
      ),
      floatingActionButton: (user.role == UserRole.family || user.role == UserRole.senior) && safeIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nowe zlecenie'),
            )
          : null,
    );
  }

  Widget _buildMainPage(UserModel user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text('Cześć, ${user.name.split(' ').first}!'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildWelcomeCard(user),
              const SizedBox(height: 16),
              Text('Usługi', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildServiceGrid(),
              const SizedBox(height: 24),
              _buildQuickAccessRow(),
              const SizedBox(height: 24),
              Text('Ostatnie zlecenia', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildRecentOrders(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user.role.label, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(Icons.star, Colors.amber, '${user.points} ${S.points}'),
                const SizedBox(width: 8),
                _buildStatChip(Icons.trending_up, Colors.blue, '${S.level} ${user.level}'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BadgesScreen()),
                  ),
                  child: _buildStatChip(
                    Icons.emoji_events,
                    Colors.purple,
                    '${user.badgeIds.length} ${S.badges}',
                  ),
                ),
              ],
            ),
            if (user.role == UserRole.worker) ...[
              const SizedBox(height: 12),
              _buildVerificationBadge(user.verificationStatus),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(VerificationStatus status) {
    Color color;
    IconData icon;
    String label;
    switch (status) {
      case VerificationStatus.verified:
        color = Colors.green;
        icon = Icons.verified;
        label = 'Zweryfikowany';
      case VerificationStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Weryfikacja w toku';
      case VerificationStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Odrzucony';
      case VerificationStatus.unverified:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'Niezweryfikowany';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    final services = OrderType.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final auth = context.read<AuthProvider>();
              if (auth.user?.role == UserRole.family || auth.user?.role == UserRole.senior) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateOrderScreen(preselectedType: service)),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(service.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    service.label,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (service.isFree) ...[
                  const SizedBox(height: 2),
                  Text('Bezpłatne', style: TextStyle(fontSize: 9, color: Colors.green[700], fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessRow() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EquipmentScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.handyman, size: 32, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 8),
                    Text(S.equipment, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.people, size: 32, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 8),
                    Text(S.friends, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 32, color: Colors.amber[700]),
                    const SizedBox(height: 8),
                    Text(S.badges, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.orders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Brak zleceń', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }
        return Column(
          children: provider.orders.take(3).map((order) => _buildOrderCard(order)).toList(),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(order.type.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(order.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(order.status.label),
        trailing: order.price != null && order.price! > 0
            ? Text('${order.price!.toStringAsFixed(0)} zł', style: const TextStyle(fontWeight: FontWeight.bold))
            : const Text('Bezpłatne', style: TextStyle(color: Colors.green)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
      ),
    );
  }

  Widget _buildAvailableOrdersPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Dostępne zlecenia')),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.loading) return const Center(child: CircularProgressIndicator());
          if (provider.availableOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Brak dostępnych zleceń'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAvailableOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.availableOrders.length,
              itemBuilder: (_, i) => _buildOrderCard(provider.availableOrders[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersPage(UserModel user) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje zlecenia')),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.loading) return const Center(child: CircularProgressIndicator());
          if (provider.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Brak zleceń'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              itemBuilder: (_, i) => _buildOrderCard(provider.orders[i]),
            ),
          );
        },
      ),
    );
  }
}
