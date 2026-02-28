import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'equipment_detail_screen.dart';
import 'order_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchToTab;
  const BrowseScreen({super.key, this.onSwitchToTab});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Providers tab state
  List<ServiceOffer>? _providers;
  bool _loadingProviders = true;
  OrderType? _providerFilter;

  // Equipment tab state
  List<EquipmentModel>? _equipment;
  bool _loadingEquipment = true;
  EquipmentCategory? _equipmentFilter;

  // Housing tab state
  List<OrderModel>? _housingOrders;
  bool _loadingHousing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadProviders();
    _loadEquipment();
    _loadHousingOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _loadingProviders = true);
    final api = context.read<AuthProvider>().api;
    try {
      final query = _searchController.text.trim();
      final results = await api.searchDirectory(
        type: _providerFilter?.name,
        query: query.isNotEmpty ? query : null,
      );
      if (mounted) setState(() { _providers = results; _loadingProviders = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProviders = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  Future<void> _loadEquipment() async {
    setState(() => _loadingEquipment = true);
    final api = context.read<AuthProvider>().api;
    try {
      final results = await api.listEquipment(
        category: _equipmentFilter?.name,
      );
      if (mounted) setState(() { _equipment = results; _loadingEquipment = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEquipment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  Future<void> _loadHousingOrders() async {
    setState(() => _loadingHousing = true);
    try {
      final provider = context.read<OrderProvider>();
      await provider.loadAvailableOrders();
      if (mounted) {
        setState(() {
          _housingOrders = provider.availableOrders
              .where((o) =>
                  o.type == OrderType.housing ||
                  o.type == OrderType.caregiving ||
                  o.type == OrderType.paramedical)
              .toList();
          _loadingHousing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingHousing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  void _onSearch() {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      _loadProviders();
    } else if (tabIndex == 1) {
      _loadEquipment();
    } else {
      _loadHousingOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szukaj'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Czego szukasz?',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Usługodawcy'),
                  Tab(text: 'Sprzęt'),
                  Tab(text: 'Mieszkania & inne'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProvidersTab(),
          _buildEquipmentTab(),
          _buildHousingTab(),
        ],
      ),
    );
  }

  // ---- Tab 1: Providers ----
  Widget _buildProvidersTab() {
    return Column(
      children: [
        _buildProviderFilterChips(),
        Expanded(
          child: _loadingProviders
              ? const Center(child: CircularProgressIndicator())
              : _providers == null || _providers!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_outlined, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Brak ofert', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Spróbuj zmienić filtry', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProviders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _providers!.length,
                        itemBuilder: (context, index) => _BrowseProviderCard(
                          offer: _providers![index],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildProviderFilterChips() {
    final filters = <OrderType?>[
      null,
      OrderType.cleaning,
      OrderType.repair,
      OrderType.transport,
      OrderType.shopping,
      OrderType.caregiving,
      OrderType.plumbing,
      OrderType.gardening,
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = _providerFilter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(f == null ? 'Wszystko' : '${f.icon} ${f.label}'),
              selected: selected,
              onSelected: (_) {
                setState(() => _providerFilter = f);
                _loadProviders();
              },
            ),
          );
        },
      ),
    );
  }

  // ---- Tab 2: Equipment ----
  Widget _buildEquipmentTab() {
    return Column(
      children: [
        _buildEquipmentFilterChips(),
        Expanded(
          child: _loadingEquipment
              ? const Center(child: CircularProgressIndicator())
              : _equipment == null || _equipment!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handyman_outlined, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Brak sprzętu', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEquipment,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _equipment!.length,
                        itemBuilder: (context, index) => _BrowseEquipmentCard(
                          item: _equipment![index],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEquipmentFilterChips() {
    final filters = <EquipmentCategory?>[
      null,
      ...EquipmentCategory.values,
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = _equipmentFilter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(f == null ? 'Wszystko' : '${f.icon} ${f.label}'),
              selected: selected,
              onSelected: (_) {
                setState(() => _equipmentFilter = f);
                _loadEquipment();
              },
            ),
          );
        },
      ),
    );
  }

  // ---- Tab 3: Housing & other ----
  Widget _buildHousingTab() {
    if (_loadingHousing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_housingOrders == null || _housingOrders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Brak ogłoszeń', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mieszkania, opieka i usługi paramedyczne', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHousingOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _housingOrders!.length,
        itemBuilder: (context, index) => _BrowseHousingCard(
          order: _housingOrders![index],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider card for browse
// ---------------------------------------------------------------------------
class _BrowseProviderCard extends StatelessWidget {
  final ServiceOffer offer;
  const _BrowseProviderCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = offer.provider?.verificationStatus == VerificationStatus.verified;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                              offer.provider?.name ?? 'Nieznany',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Colors.green),
                                  SizedBox(width: 3),
                                  Text('Zweryfikowany', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        offer.provider?.role.label ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (offer.averageRating != null) ...[
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 18, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            offer.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${offer.serviceType.icon} ${offer.serviceType.label}',
                    style: TextStyle(fontSize: 12, color: theme.primaryColor),
                  ),
                ),
                const Spacer(),
                if (offer.priceFrom != null || offer.priceTo != null)
                  Text(
                    _priceRange(offer),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
              ],
            ),
            if (offer.skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: offer.skills
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (offer.location != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(offer.location!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zapytanie wysłane!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Wyślij zapytanie'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
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
// Equipment card for browse
// ---------------------------------------------------------------------------
class _BrowseEquipmentCard extends StatelessWidget {
  final EquipmentModel item;
  const _BrowseEquipmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color condColor;
    switch (item.condition) {
      case EquipmentCondition.brandNew:
      case EquipmentCondition.likeNew:
        condColor = Colors.green;
      case EquipmentCondition.good:
        condColor = Colors.blue;
      case EquipmentCondition.fair:
        condColor = Colors.orange;
      case EquipmentCondition.worn:
        condColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EquipmentDetailScreen(equipment: item)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(item.category.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: condColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.condition.name,
                            style: TextStyle(fontSize: 10, color: condColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(item.category.label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    if (item.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.location!,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.pricePerUnit.toStringAsFixed(0)} zł',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primaryColor),
                  ),
                  Text(
                    '/ ${item.priceUnit.name}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (item.depositAmount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'kaucja ${item.depositAmount!.toStringAsFixed(0)} zł',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Housing order card for browse
// ---------------------------------------------------------------------------
class _BrowseHousingCard extends StatelessWidget {
  final OrderModel order;
  const _BrowseHousingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.price != null && order.price! > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(order.type.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.type.label,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.blue.withAlpha(20) : Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? '${order.price!.toStringAsFixed(0)} zł' : 'Wolontariat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isPaid ? Colors.blue : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  order.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
