import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late Future<List<FriendshipModel>> _friendsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() {
    final api = context.read<AuthProvider>().api;
    _friendsFuture = api.listFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.friends),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FriendshipModel>>(
              future: _friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                final friends = snapshot.data ?? [];
                final pending = friends
                    .where((f) => f.status == FriendshipStatus.pending)
                    .toList();
                final accepted = friends
                    .where((f) => f.status == FriendshipStatus.accepted)
                    .where((f) =>
                        _searchQuery.isEmpty ||
                        (f.friend?.name.toLowerCase().contains(_searchQuery) ?? false))
                    .toList();

                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Brak znajomych', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _loadFriends()),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      if (pending.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Oczekujące zaproszenia (${pending.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ...pending.map((f) => _buildPendingTile(f)),
                        const Divider(height: 24),
                      ],
                      if (accepted.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Znajomi (${accepted.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ...accepted.map((f) => _buildFriendTile(f)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTile(FriendshipModel f) {
    final friend = f.friend;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withAlpha(30),
          child: Text(
            friend?.name.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.orange),
          ),
        ),
        title: Text(friend?.name ?? 'Nieznany'),
        subtitle: const Text('Oczekujące'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                final api = context.read<AuthProvider>().api;
                try {
                  await api.acceptFriendRequest(f.id);
                  setState(() => _loadFriends());
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removeFriend(f.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile(FriendshipModel f) {
    final friend = f.friend;
    return Dismissible(
      key: Key(f.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Usunąć znajomego?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nie')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tak')),
            ],
          ),
        );
      },
      onDismissed: (_) => _removeFriend(f.id),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
            child: Text(
              friend?.name.substring(0, 1).toUpperCase() ?? '?',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          title: Text(friend?.name ?? 'Nieznany'),
          subtitle: Row(
            children: [
              if (f.tag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(f.tag!, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ),
                const SizedBox(width: 8),
              ],
              if (friend != null) ...[
                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                const SizedBox(width: 2),
                Text('${friend.points} pkt • Lv ${friend.level}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Future<void> _removeFriend(String id) async {
    final api = context.read<AuthProvider>().api;
    try {
      await api.removeFriend(id);
      setState(() => _loadFriends());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _showAddFriendDialog() async {
    final idCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dodaj znajomego'),
        content: TextField(
          controller: idCtrl,
          decoration: const InputDecoration(
            labelText: 'ID użytkownika',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, idCtrl.text.trim()),
            child: const Text('Wyślij'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final api = context.read<AuthProvider>().api;
      try {
        await api.sendFriendRequest(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zaproszenie wysłane!'), backgroundColor: Colors.green),
          );
          setState(() => _loadFriends());
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }
}
