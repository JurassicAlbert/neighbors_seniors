import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWorker = auth.user?.role == UserRole.worker;

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegóły zlecenia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.type.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(order.type.label, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildStatusRow(order.status),
                    const SizedBox(height: 12),
                    if (order.description.isNotEmpty) ...[
                      const Text('Opis:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(order.description),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(order.address)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payments, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          order.price != null && order.price! > 0
                              ? '${order.price!.toStringAsFixed(2)} zł'
                              : 'Bezpłatne',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (order.commission != null && order.commission! > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(prowizja: ${order.commission!.toStringAsFixed(2)} zł)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (order.requester != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(order.requester!.name),
                  subtitle: const Text('Zamawiający'),
                  trailing: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            ],
            if (order.worker != null) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withAlpha(50),
                    child: const Icon(Icons.handyman, color: Colors.green),
                  ),
                  title: Text(order.worker!.name),
                  subtitle: const Text('Wykonawca'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (isWorker && order.status == OrderStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _acceptOrder(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Przyjmij zlecenie'),
                ),
              ),
            ],
            if (isWorker && order.status == OrderStatus.accepted) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _completeOrder(context),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Oznacz jako zakończone'),
                ),
              ),
            ],
            if (!isWorker && order.status == OrderStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Anuluj zlecenie'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
      case OrderStatus.accepted:
        color = Colors.blue;
      case OrderStatus.inProgress:
        color = Colors.purple;
      case OrderStatus.completed:
        color = Colors.green;
      case OrderStatus.cancelled:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _acceptOrder(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    final success = await provider.acceptOrder(order.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zlecenie przyjęte!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  void _completeOrder(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    final success = await provider.completeOrder(order.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zlecenie zakończone!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  void _cancelOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anulować zlecenie?'),
        content: const Text('Czy na pewno chcesz anulować to zlecenie?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nie')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tak, anuluj')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final provider = context.read<OrderProvider>();
    final success = await provider.cancelOrder(order.id);
    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
