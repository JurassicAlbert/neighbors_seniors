import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notifFuture;
  final Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final api = context.read<AuthProvider>().api;
    _notifFuture = api.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.notifications)),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notifFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Brak powiadomień', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadNotifications()),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final notif = items[index];
                final isRead = notif.read || _readIds.contains(notif.id);
                return _buildNotificationTile(notif, isRead);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notif, bool isRead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isRead ? null : Theme.of(context).primaryColor.withAlpha(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _typeColor(notif.type).withAlpha(30),
          child: Icon(_typeIcon(notif.type), color: _typeColor(notif.type), size: 20),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              _timeAgo(notif.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: () {
          setState(() => _readIds.add(notif.id));
        },
      ),
    );
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reservationConfirmed:
        return Icons.check_circle;
      case NotificationType.accessCodeDelivered:
        return Icons.vpn_key;
      case NotificationType.serviceStarted:
        return Icons.play_circle;
      case NotificationType.serviceCompleted:
        return Icons.done_all;
      case NotificationType.overdueReturn:
        return Icons.warning;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.verificationUpdate:
        return Icons.verified;
      case NotificationType.disputeUpdate:
        return Icons.gavel;
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.badgeEarned:
        return Icons.emoji_events;
      case NotificationType.paymentUpdate:
        return Icons.payment;
    }
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.reservationConfirmed:
      case NotificationType.serviceCompleted:
      case NotificationType.badgeEarned:
        return Colors.green;
      case NotificationType.serviceStarted:
        return Colors.blue;
      case NotificationType.overdueReturn:
      case NotificationType.disputeUpdate:
        return Colors.orange;
      case NotificationType.newMessage:
      case NotificationType.friendRequest:
        return Colors.indigo;
      case NotificationType.verificationUpdate:
        return Colors.teal;
      case NotificationType.accessCodeDelivered:
        return Colors.purple;
      case NotificationType.paymentUpdate:
        return Colors.deepOrange;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Teraz';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
    if (diff.inHours < 24) return '${diff.inHours} godz. temu';
    if (diff.inDays < 7) return '${diff.inDays} dni temu';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}
