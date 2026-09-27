import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_glass_surface.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/report_provider.dart';

class LoginHistoryScreen extends ConsumerWidget {
  const LoginHistoryScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(loginHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Login History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: DecoratedBox(
        decoration: AppGlassDecoration.backgroundFor(context),
        child: asyncData.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'No login history found',
                  style: TextStyle(
                    color: Color(0xFF7D8CB2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = items[index];

                final scheme = Theme.of(context).colorScheme;
                return AppGlassSurface(
                  enableBackdropBlur: false,
                  borderRadius: BorderRadius.circular(22),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: .72),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _deviceIcon(item.deviceInfo ?? ''),
                          color: scheme.onPrimaryContainer,
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    item.loginTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                Icon(
                                  Icons.devices_other_rounded,
                                  size: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    item.deviceInfo ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            _StatusChip(status: item.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load login history: $e',
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final lowerStatus = status.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;

    if (lowerStatus.contains('success') ||
        lowerStatus.contains('active') ||
        lowerStatus.contains('approved')) {
      bgColor = const Color(0xFFE0F8F1);
      textColor = const Color(0xFF20A67A);
    } else if (lowerStatus.contains('pending')) {
      bgColor = const Color(0xFFFFF3DC);
      textColor = const Color(0xFFC88824);
    } else if (lowerStatus.contains('fail') ||
        lowerStatus.contains('error') ||
        lowerStatus.contains('blocked')) {
      bgColor = const Color(0xFFFFEAEA);
      textColor = const Color(0xFFE74C3C);
    } else {
      bgColor = const Color(0xFFEAF0FF);
      textColor = const Color(0xFF233E8B);
    }

    if (isDark) {
      bgColor = textColor.withValues(alpha: .18);
      textColor = switch (lowerStatus) {
        final value
            when value.contains('success') ||
                value.contains('active') ||
                value.contains('approved') =>
          const Color(0xFF6EE7B7),
        final value when value.contains('pending') => const Color(0xFFFFD27A),
        final value
            when value.contains('fail') ||
                value.contains('error') ||
                value.contains('blocked') =>
          const Color(0xFFFF9C96),
        _ => const Color(0xFFADC6FF),
      };
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: textColor.withValues(alpha: .28)),
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

IconData _deviceIcon(String deviceInfo) {
  final info = deviceInfo.toLowerCase();

  if (info.contains('mobile') ||
      info.contains('android') ||
      info.contains('iphone') ||
      info.contains('ios')) {
    return Icons.smartphone_rounded;
  }

  if (info.contains('windows') ||
      info.contains('pc') ||
      info.contains('desktop') ||
      info.contains('laptop') ||
      info.contains('mac')) {
    return Icons.computer_rounded;
  }

  if (info.contains('tablet') || info.contains('ipad')) {
    return Icons.tablet_mac_rounded;
  }

  return Icons.devices_other_rounded;
}
