import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../devices/presentation/device_list_screen.dart';
import '../../privileges/presentation/privilege_list_screen.dart';
import '../../subcategories/presentation/subcategory_list_screen.dart';
import '../../users/presentation/user_list_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = [
      _DashboardTileData(
        'Users',
        Icons.people_outline,
        const UserListScreen(),
      ),
      _DashboardTileData(
        'Devices',
        Icons.devices_other_outlined,
        const DeviceListScreen(),
      ),
      _DashboardTileData(
        'Categories',
        Icons.category_outlined,
        const CategoryListScreen(),
      ),
      _DashboardTileData(
        'Subcategories',
        Icons.account_tree_outlined,
        const SubcategoryListScreen(),
      ),
      _DashboardTileData(
        'Privileges',
        Icons.admin_panel_settings_outlined,
        const PrivilegeListScreen(),
      ),
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
          )
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
            childAspectRatio: 1.12,
          ),
          itemBuilder: (context, index) {
            final item = tiles[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.screen),
                );
              },
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
                    )
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
  final Widget screen;

  _DashboardTileData(this.title, this.icon, this.screen);
}