import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../providers/auth_provider.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Future<_BadgesData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final api = context.read<AuthProvider>().api;
    _dataFuture = Future.wait([
      api.listBadges(),
      api.listMyBadges(),
    ]).then((results) => _BadgesData(
          allBadges: results[0],
          myBadges: results[1],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final nextLevelPoints = user.level * 100;
    final progress = user.points / nextLevelPoints;

    return Scaffold(
      appBar: AppBar(title: Text(S.badges)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 32),
                        const SizedBox(width: 8),
                        Text(
                          '${user.points}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(S.points, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${S.level} ${user.level}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: Colors.grey.withAlpha(40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${S.level} ${user.level + 1}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${user.points}/$nextLevelPoints pkt',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(S.badges, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder<_BadgesData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                final data = snapshot.data!;
                final myBadgeIds = data.myBadges.map((b) => b.id).toSet();

                if (data.allBadges.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Brak odznak', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: data.allBadges.length,
                  itemBuilder: (context, index) {
                    final badge = data.allBadges[index];
                    final earned = myBadgeIds.contains(badge.id);
                    return _buildBadgeCard(badge, earned);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, bool earned) {
    return Card(
      color: earned ? null : Colors.grey.withAlpha(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBadgeDetail(badge, earned),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 32,
                  color: earned ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: earned ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${badge.requiredPoints} pkt',
                style: TextStyle(
                  fontSize: 10,
                  color: earned ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BadgeModel badge, bool earned) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(child: Text(badge.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 12),
            Text('Wymagane punkty: ${badge.requiredPoints}'),
            const SizedBox(height: 8),
            if (earned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Zdobyta!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Nie zdobyta', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _BadgesData {
  final List<BadgeModel> allBadges;
  final List<BadgeModel> myBadges;
  const _BadgesData({required this.allBadges, required this.myBadges});
}
