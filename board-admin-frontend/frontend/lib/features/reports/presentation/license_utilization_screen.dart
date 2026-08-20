import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/report_provider.dart';

class LicenseUtilizationScreen extends ConsumerWidget {
  const LicenseUtilizationScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(licenseUtilizationProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'License Utilization',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: asyncData.when(
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HeaderCard(),

            const SizedBox(height: 18),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: item.totalUsers.toString(),
                  icon: Icons.people_alt_outlined,
                  bgColor: primaryBlue.withValues(alpha: 0.08),
                  iconColor: primaryBlue,
                ),

                _StatCard(
                  title: 'Active Users',
                  value: item.activeUsers.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  bgColor: const Color(0xFFE0F8F1),
                  iconColor: const Color(0xFF20A67A),
                ),

                _StatCard(
                  title: 'Deactivated',
                  value: item.deactivatedUsers.toString(),
                  icon: Icons.block_outlined,
                  bgColor: const Color(0xFFFFF3DC),
                  iconColor: const Color(0xFFC88824),
                ),

                _StatCard(
                  title: 'Locked Users',
                  value: item.lockedUsers.toString(),
                  icon: Icons.lock_outline_rounded,
                  bgColor: const Color(0xFFFFEAEA),
                  iconColor: const Color(0xFFE74C3C),
                ),

                _StatCard(
                  title: 'Deleted Users',
                  value: item.deletedUsers.toString(),
                  icon: Icons.delete_outline_rounded,
                  bgColor: const Color(0xFFEAF0FF),
                  iconColor: const Color(0xFF233E8B),
                ),
              ],
            ),
          ],
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Failed to load license utilization: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        loading: () => const AppLoading(),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: darkBlue,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Analytics',
                  style: TextStyle(
                    color: Color(0xFFB9C4E2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'License Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Monitor user license utilization statistics',
                  style: TextStyle(
                    color: Color(0xFFFFD27A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  static const Color darkBlue = Color(0xFF00184A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7D8CB2),
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
