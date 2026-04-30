import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/provider/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = [
      _DashboardTileData('Users', Icons.people_outline),
      _DashboardTileData('Devices', Icons.devices_other_outlined),
      _DashboardTileData('Authorization', Icons.admin_panel_settings_outlined),
      _DashboardTileData('Meetings', Icons.event_note_outlined),
      _DashboardTileData('Papers', Icons.picture_as_pdf_outlined),
      _DashboardTileData('Reports', Icons.bar_chart_outlined),
      _DashboardTileData('Settings', Icons.settings_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final item = tiles[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {},
              child: AppCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 40),
                    const SizedBox(height: 14),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardTileData {
  final String title;
  final IconData icon;

  _DashboardTileData(this.title, this.icon);
}
