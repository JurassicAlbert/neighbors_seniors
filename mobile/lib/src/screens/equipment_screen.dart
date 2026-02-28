import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'equipment_detail_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  EquipmentCategory? _selectedCategory;
  late Future<List<EquipmentModel>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  void _loadEquipment() {
    final api = context.read<AuthProvider>().api;
    _equipmentFuture = api.listEquipment(
      category: _selectedCategory?.name,
    );
  }

  void _onCategoryChanged(EquipmentCategory? cat) {
    setState(() {
      _selectedCategory = cat;
      _loadEquipment();
    });
  }

  Future<void> _showAddEquipmentDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    var category = EquipmentCategory.handTools;
    var condition = EquipmentCondition.good;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Dodaj sprzęt'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Nazwa'),
                    validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Opis'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EquipmentCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Kategoria'),
                    items: EquipmentCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text('${c.icon} ${c.label}')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EquipmentCondition>(
                    value: condition,
                    decoration: const InputDecoration(labelText: 'Stan'),
                    items: EquipmentCondition.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => condition = v!),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Cena / dzień (PLN)'),
                    keyboardType: TextInputType.number,
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
                  await api.createEquipment({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'category': category.name,
                    'condition': condition.name,
                    'pricePerUnit': double.tryParse(priceCtrl.text) ?? 0,
                    'priceUnit': 'day',
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
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => _loadEquipment());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: Text(S.equipment)),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Wszystko'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => _onCategoryChanged(null),
                  ),
                ),
                ...EquipmentCategory.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('${cat.icon} ${cat.label}'),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => _onCategoryChanged(cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EquipmentModel>>(
              future: _equipmentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => setState(() => _loadEquipment()),
                          child: const Text('Ponów'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handyman_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Brak sprzętu', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loadEquipment());
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _EquipmentCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EquipmentDetailScreen(equipment: item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: user != null && user.hasCapability(UserCapability.equipmentProvider)
          ? FloatingActionButton.extended(
              onPressed: _showAddEquipmentDialog,
              icon: const Icon(Icons.add),
              label: Text(S.addEquipment),
            )
          : null,
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentModel item;
  final VoidCallback onTap;

  const _EquipmentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              color: Theme.of(context).primaryColor.withAlpha(20),
              child: Center(
                child: Text(item.category.icon, style: const TextStyle(fontSize: 36)),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _conditionColor(item.condition).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.condition.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: _conditionColor(item.condition),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${item.pricePerUnit.toStringAsFixed(0)} zł/${item.priceUnit.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _conditionColor(EquipmentCondition c) {
    switch (c) {
      case EquipmentCondition.brandNew:
      case EquipmentCondition.likeNew:
        return Colors.green;
      case EquipmentCondition.good:
        return Colors.blue;
      case EquipmentCondition.fair:
        return Colors.orange;
      case EquipmentCondition.worn:
        return Colors.red;
    }
  }
}
