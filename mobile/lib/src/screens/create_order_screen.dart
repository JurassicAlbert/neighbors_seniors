import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/order_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  final OrderType? preselectedType;
  const CreateOrderScreen({super.key, this.preselectedType});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  late OrderType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType ?? OrderType.shopping;
    if (_selectedType.isFree) _priceController.text = '0';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<OrderProvider>();
    final success = await provider.createOrder({
      'type': _selectedType.name,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'address': _addressController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zlecenie utworzone!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowe zlecenie')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Typ usługi:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<OrderType>(
                value: _selectedType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: OrderType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text('${t.icon} ${t.label}'),
                )).toList(),
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  if (v.isFree) _priceController.text = '0';
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł zlecenia',
                  border: OutlineInputBorder(),
                  hintText: 'np. Zakupy spożywcze',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Podaj tytuł' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                  hintText: 'Opisz szczegóły zlecenia...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'ul. Przykładowa 1, Warszawa',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Podaj adres' : null,
              ),
              const SizedBox(height: 12),
              if (!_selectedType.isFree)
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Cena (PLN)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                    suffixText: 'zł',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Podaj cenę';
                    if (double.tryParse(v) == null) return 'Nieprawidłowa kwota';
                    return null;
                  },
                ),
              if (_selectedType.isFree)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volunteer_activism, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Usługa wolontariacka - bezpłatna', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Utwórz zlecenie', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
