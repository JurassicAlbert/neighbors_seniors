import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final EquipmentModel equipment;
  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(equipment.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(equipment.category.icon, style: const TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(context),
                        const SizedBox(width: 8),
                        _buildConditionChip(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (equipment.description.isNotEmpty) ...[
                      Text(equipment.description, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 12),
                    ],
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${equipment.category.icon} ${equipment.category.label}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          '${equipment.pricePerUnit.toStringAsFixed(2)} zł / ${equipment.priceUnit.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    if (equipment.depositAmount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Kaucja: ${equipment.depositAmount!.toStringAsFixed(2)} zł'),
                        ],
                      ),
                    ],
                    if (equipment.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(equipment.location!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (equipment.owner != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                    child: Text(
                      equipment.owner!.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  title: Text(equipment.owner!.name),
                  subtitle: const Text('Właściciel'),
                  trailing: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildStatusLifecycle(context),
            const SizedBox(height: 24),
            if (equipment.status == EquipmentStatus.available)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showReservationDialog(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Zarezerwuj'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    switch (equipment.status) {
      case EquipmentStatus.available:
        color = Colors.green;
      case EquipmentStatus.reserved:
        color = Colors.orange;
      case EquipmentStatus.inUse:
        color = Colors.blue;
      case EquipmentStatus.returned:
        color = Colors.teal;
      case EquipmentStatus.underReview:
        color = Colors.purple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        equipment.status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildConditionChip() {
    Color color;
    switch (equipment.condition) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        equipment.condition.name,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildStatusLifecycle(BuildContext context) {
    final statuses = EquipmentStatus.values;
    final currentIdx = statuses.indexOf(equipment.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(statuses.length, (i) {
                final isActive = i <= currentIdx;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isActive
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withAlpha(50),
                        child: Icon(
                          isActive ? Icons.check : Icons.circle,
                          size: 14,
                          color: isActive ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statuses[i].label,
                        style: TextStyle(
                          fontSize: 8,
                          color: isActive ? Theme.of(context).primaryColor : Colors.grey,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReservationDialog(BuildContext context) async {
    DateTime? startDate;
    DateTime? endDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rezerwacja sprzętu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(startDate != null
                    ? '${startDate!.day}.${startDate!.month}.${startDate!.year}'
                    : 'Wybierz datę rozpoczęcia'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(endDate != null
                    ? '${endDate!.day}.${endDate!.month}.${endDate!.year}'
                    : 'Wybierz datę zakończenia'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => endDate = picked);
                  }
                },
              ),
              if (startDate != null && endDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Koszt: ${_calculatePrice(startDate!, endDate!).toStringAsFixed(2)} zł',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
            FilledButton(
              onPressed: startDate != null && endDate != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Rezerwuj'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && startDate != null && endDate != null && context.mounted) {
      try {
        final api = context.read<AuthProvider>().api;
        await api.reserveEquipment(equipment.id, {
          'startDate': startDate!.toIso8601String(),
          'endDate': endDate!.toIso8601String(),
          'totalPrice': _calculatePrice(startDate!, endDate!),
          'depositAmount': equipment.depositAmount,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zarezerwowano!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }

  double _calculatePrice(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    return (days < 1 ? 1 : days) * equipment.pricePerUnit;
  }
}
