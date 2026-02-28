import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'login_screen.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import 'profile_screen.dart';
import 'equipment_detail_screen.dart';
import 'directory_screen.dart';
import 'notifications_screen.dart';
import 'browse_screen.dart';

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

  void _switchToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();

    final pages = <Widget>[
      _HomeTab(
        user: user,
        onSwitchToTab: _switchToTab,
      ),
      BrowseScreen(onSwitchToTab: _switchToTab),
      _OrdersTab(user: user),
      const ProfileScreen(),
    ];

    const destinations = <NavigationDestination>[
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Główna'),
      NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Szukaj'),
      NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Zlecenia'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
    ];

    final safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
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
}

// ---------------------------------------------------------------------------
// Home Tab
// ---------------------------------------------------------------------------
class _HomeTab extends StatefulWidget {
  final UserModel user;
  final ValueChanged<int> onSwitchToTab;

  const _HomeTab({required this.user, required this.onSwitchToTab});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<ServiceOffer>? _providers;
  List<EquipmentModel>? _equipment;
  bool _loadingProviders = true;
  bool _loadingEquipment = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<AuthProvider>().api;
    try {
      final providers = await api.searchDirectory();
      if (mounted) setState(() { _providers = providers; _loadingProviders = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProviders = false);
    }
    try {
      final equipment = await api.listEquipment();
      if (mounted) setState(() { _equipment = equipment; _loadingEquipment = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingEquipment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = widget.user.name.split(' ').first;
    final isWorker = widget.user.role == UserRole.worker;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final orderProvider = context.read<OrderProvider>();
          setState(() {
            _loadingProviders = true;
            _loadingEquipment = true;
          });
          await _loadData();
          if (mounted) {
            await orderProvider.loadOrders();
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text('Cześć, $firstName!'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroCard(theme, isWorker),
                  const SizedBox(height: 20),
                  _buildCategoryRow(theme),
                  const SizedBox(height: 24),
                  _buildProvidersSection(theme),
                  const SizedBox(height: 24),
                  _buildEquipmentSection(theme),
                  const SizedBox(height: 24),
                  _buildActivitySection(theme),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Hero action card --
  Widget _buildHeroCard(ThemeData theme, bool isWorker) {
    final color = theme.colorScheme.primary;
    return Card(
      color: color,
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isWorker) {
            widget.onSwitchToTab(2);
          } else {
            widget.onSwitchToTab(1);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWorker ? Icons.work_outline : Icons.support_agent,
                size: 40,
                color: Colors.white.withAlpha(220),
              ),
              const SizedBox(height: 12),
              Text(
                isWorker ? 'Szukasz zlecenia?' : 'Potrzebujesz pomocy?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                isWorker
                    ? 'Przeglądaj dostępne zlecenia'
                    : 'Znajdź usługodawcę lub pożycz sprzęt',
                style: TextStyle(fontSize: 15, color: Colors.white.withAlpha(210)),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  if (isWorker) {
                    widget.onSwitchToTab(2);
                  } else {
                    widget.onSwitchToTab(1);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(isWorker ? 'Przeglądaj zlecenia' : 'Szukaj pomocy'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Category chips row --
  Widget _buildCategoryRow(ThemeData theme) {
    final categories = <_CategoryChip>[
      _CategoryChip('🧹', 'Sprzątanie', OrderType.cleaning),
      _CategoryChip('🔧', 'Naprawy', OrderType.repair),
      _CategoryChip('🚗', 'Transport', OrderType.transport),
      _CategoryChip('🛒', 'Zakupy', OrderType.shopping),
      _CategoryChip('🏥', 'Opieka', OrderType.caregiving),
      _CategoryChip('🛠️', 'Sprzęt', OrderType.toolSharing),
      _CategoryChip('🤝', 'Wolontariat', OrderType.volunteer),
      _CategoryChip('🏠', 'Mieszkania', OrderType.housing),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          return ActionChip(
            avatar: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
            label: Text(cat.label),
            onPressed: () {
              widget.onSwitchToTab(1);
            },
          );
        },
      ),
    );
  }

  // -- Available providers section --
  Widget _buildProvidersSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dostępni usługodawcy',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => widget.onSwitchToTab(1),
              child: const Text('Zobacz wszystkich →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingProviders)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_providers == null || _providers!.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.storefront_outlined, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Brak ofert usługodawców', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          )
        else
          ..._providers!.take(4).map((offer) => _ProviderCard(offer: offer)),
      ],
    );
  }

  // -- Equipment to borrow section --
  Widget _buildEquipmentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sprzęt do wypożyczenia',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => widget.onSwitchToTab(1),
              child: const Text('Zobacz cały katalog →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingEquipment)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_equipment == null || _equipment!.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.handyman_outlined, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Brak dostępnego sprzętu', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _equipment!.take(4).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = _equipment![i];
                return _EquipmentMiniCard(
                  item: item,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EquipmentDetailScreen(equipment: item)),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // -- Your activity section --
  Widget _buildActivitySection(ThemeData theme) {
    final user = widget.user;
    final nextLevelPoints = user.level * 100;
    final progress = user.points / nextLevelPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Twoja aktywność',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => widget.onSwitchToTab(2),
              child: const Text('Zobacz wszystkie →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${user.points} ${S.points}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.withAlpha(40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${S.level} ${user.level}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Consumer<OrderProvider>(
          builder: (_, provider, __) {
            if (provider.loading) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            if (provider.orders.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Brak zleceń', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: provider.orders.take(3).map((order) => _OrderMiniCard(order: order)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryChip {
  final String emoji;
  final String label;
  final OrderType type;
  const _CategoryChip(this.emoji, this.label, this.type);
}

// ---------------------------------------------------------------------------
// Provider card widget
// ---------------------------------------------------------------------------
class _ProviderCard extends StatelessWidget {
  final ServiceOffer offer;
  const _ProviderCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = offer.provider?.verificationStatus == VerificationStatus.verified;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DirectoryScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withAlpha(30),
                child: Text(
                  offer.provider?.name.substring(0, 1).toUpperCase() ?? '?',
                  style: TextStyle(fontSize: 18, color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            offer.provider?.name ?? offer.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${offer.serviceType.icon} ${offer.serviceType.label}',
                            style: TextStyle(fontSize: 11, color: theme.primaryColor),
                          ),
                        ),
                        if (offer.averageRating != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            offer.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                    if (isVerified) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Zweryfikowany',
                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (offer.priceFrom != null || offer.priceTo != null)
                Text(
                  _priceRange(offer),
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _priceRange(ServiceOffer offer) {
    if (offer.priceFrom != null && offer.priceTo != null) {
      return '${offer.priceFrom!.toStringAsFixed(0)}-${offer.priceTo!.toStringAsFixed(0)} zł';
    }
    if (offer.priceFrom != null) return 'od ${offer.priceFrom!.toStringAsFixed(0)} zł';
    if (offer.priceTo != null) return 'do ${offer.priceTo!.toStringAsFixed(0)} zł';
    return '';
  }
}

// ---------------------------------------------------------------------------
// Equipment mini card (horizontal scroll)
// ---------------------------------------------------------------------------
class _EquipmentMiniCard extends StatelessWidget {
  final EquipmentModel item;
  final VoidCallback onTap;
  const _EquipmentMiniCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 64,
                width: double.infinity,
                color: theme.primaryColor.withAlpha(20),
                child: Center(
                  child: Text(item.category.icon, style: const TextStyle(fontSize: 30)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category.label,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _conditionBadge(item.condition),
                          const Spacer(),
                          Text(
                            '${item.pricePerUnit.toStringAsFixed(0)} zł',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      if (item.location != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 10, color: Colors.grey),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.location!,
                                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conditionBadge(EquipmentCondition c) {
    Color color;
    switch (c) {
      case EquipmentCondition.brandNew:
      case EquipmentCondition.likeNew:
        color = Colors.green;
      case EquipmentCondition.good:
        color = Colors.blue;
      case EquipmentCondition.fair:
        color = Colors.orange;
      case EquipmentCondition.worn:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        c.name,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order mini card
// ---------------------------------------------------------------------------
class _OrderMiniCard extends StatelessWidget {
  final OrderModel order;
  const _OrderMiniCard({required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
      case OrderStatus.accepted:
        statusColor = Colors.blue;
      case OrderStatus.inProgress:
        statusColor = Colors.purple;
      case OrderStatus.completed:
        statusColor = Colors.green;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          child: Text(order.type.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(order.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.status.label,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        trailing: order.price != null && order.price! > 0
            ? Text('${order.price!.toStringAsFixed(0)} zł', style: const TextStyle(fontWeight: FontWeight.bold))
            : const Text('Bezpłatne', style: TextStyle(color: Colors.green, fontSize: 13)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Orders Tab (with status filter tabs)
// ---------------------------------------------------------------------------
class _OrdersTab extends StatefulWidget {
  final UserModel user;
  const _OrdersTab({required this.user});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final isWorker = widget.user.role == UserRole.worker;
    _tabController = TabController(length: isWorker ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = widget.user.role == UserRole.worker;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zlecenia'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'Aktywne'),
            const Tab(text: 'Zakończone'),
            const Tab(text: 'Wszystkie'),
            if (isWorker) const Tab(text: 'Dostępne'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(filter: _OrderFilter.active),
          _OrdersList(filter: _OrderFilter.completed),
          _OrdersList(filter: _OrderFilter.all),
          if (isWorker) const _AvailableOrdersList(),
        ],
      ),
      floatingActionButton: !isWorker
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
}

enum _OrderFilter { active, completed, all }

class _OrdersList extends StatelessWidget {
  final _OrderFilter filter;
  const _OrdersList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.loading) return const Center(child: CircularProgressIndicator());

        List<OrderModel> filtered;
        switch (filter) {
          case _OrderFilter.active:
            filtered = provider.orders
                .where((o) => o.status == OrderStatus.pending ||
                    o.status == OrderStatus.accepted ||
                    o.status == OrderStatus.inProgress)
                .toList();
          case _OrderFilter.completed:
            filtered = provider.orders
                .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled)
                .toList();
          case _OrderFilter.all:
            filtered = provider.orders;
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Brak zleceń', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _OrderMiniCard(order: filtered[i]),
          ),
        );
      },
    );
  }
}

class _AvailableOrdersList extends StatelessWidget {
  const _AvailableOrdersList();

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.loading) return const Center(child: CircularProgressIndicator());

        if (provider.availableOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Brak dostępnych zleceń', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAvailableOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.availableOrders.length,
            itemBuilder: (_, i) => _OrderMiniCard(order: provider.availableOrders[i]),
          ),
        );
      },
    );
  }
}
