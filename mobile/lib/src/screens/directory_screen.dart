import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchCtrl = TextEditingController();
  OrderType? _selectedType;
  late Future<List<ServiceOffer>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadOffers() {
    final api = context.read<AuthProvider>().api;
    _offersFuture = api.searchDirectory(
      type: _selectedType?.name,
      query: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.directory)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: S.searchDirectory,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => setState(() => _loadOffers()),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<OrderType?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) => setState(() {
                    _selectedType = v;
                    _loadOffers();
                  }),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Wszystkie')),
                    ...OrderType.values.map(
                      (t) => PopupMenuItem(value: t, child: Text('${t.icon} ${t.label}')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Chip(
                label: Text('${_selectedType!.icon} ${_selectedType!.label}'),
                onDeleted: () => setState(() {
                  _selectedType = null;
                  _loadOffers();
                }),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<ServiceOffer>>(
              future: _offersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                final offers = snapshot.data ?? [];
                if (offers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Brak ofert', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _loadOffers()),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: offers.length,
                    itemBuilder: (context, index) => _buildOfferCard(offers[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOfferDialog,
        icon: const Icon(Icons.add),
        label: Text(S.createOffer),
      ),
    );
  }

  Widget _buildOfferCard(ServiceOffer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOfferDetail(offer),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                    child: Text(
                      offer.provider?.name.substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          offer.provider?.name ?? 'Nieznany',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (offer.averageRating != null) ...[
                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 2),
                    Text(
                      offer.averageRating!.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${offer.serviceType.icon} ${offer.serviceType.label}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const Spacer(),
                  if (offer.priceFrom != null || offer.priceTo != null)
                    Text(
                      _priceRange(offer),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              if (offer.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: offer.skills.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
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

  void _showOfferDetail(ServiceOffer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(offer.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (offer.provider != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(offer.provider!.name.substring(0, 1))),
                title: Text(offer.provider!.name),
                subtitle: Text('${offer.completedOrders ?? 0} ukończonych zleceń'),
              ),
            ],
            const SizedBox(height: 8),
            Text(offer.description),
            const SizedBox(height: 16),
            if (offer.skills.isNotEmpty) ...[
              const Text('Umiejętności:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: offer.skills.map((s) => Chip(label: Text(s))).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (offer.priceFrom != null || offer.priceTo != null)
              Text(
                'Zakres cenowy: ${_priceRange(offer)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zapytanie wysłane!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Wyślij zapytanie'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateOfferDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();
    var serviceType = OrderType.cleaning;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(S.createOffer),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Tytuł'),
                    validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Opis'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<OrderType>(
                    value: serviceType,
                    decoration: const InputDecoration(labelText: 'Typ usługi'),
                    items: OrderType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text('${t.icon} ${t.label}')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => serviceType = v!),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: skillsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Umiejętności (oddzielone przecinkiem)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final api = context.read<AuthProvider>().api;
                try {
                  await api.createOffer({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'serviceType': serviceType.name,
                    'skills': skillsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on ApiException catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
              child: const Text('Utwórz'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => _loadOffers());
    }
  }
}
