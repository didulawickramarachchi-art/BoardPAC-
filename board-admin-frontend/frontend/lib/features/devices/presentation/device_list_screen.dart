import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/device_provider.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.isAdmin) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('You do not have access to devices.')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Devices',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh device requests',
            onPressed: () =>
                ref.read(deviceListProvider.notifier).loadDevices(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const AppEmptyState(message: 'No devices found');
          }

          final orderedDevices = [...devices]
            ..sort((a, b) {
              if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
              return a.deviceId.compareTo(b.deviceId);
            });

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(deviceListProvider.notifier).loadDevices(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orderedDevices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final device = orderedDevices[index];

                final deviceInfo = device.deviceInfo ?? 'Unknown device';
                final status = device.status ?? '-';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _deviceIcon(deviceInfo),
                            color: primaryBlue,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.deviceId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: darkBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF7D8CB2),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      deviceInfo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF7D8CB2),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (device.username != null &&
                                  device.username!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Requested by ${device.username}',
                                  style: const TextStyle(
                                    color: Color(0xFF52648F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),

                              _StatusChip(status: status),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        PopupMenuButton<String>(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.more_vert_rounded,
                              color: primaryBlue,
                              size: 22,
                            ),
                          ),
                          onSelected: (value) async {
                            final notifier = ref.read(
                              deviceListProvider.notifier,
                            );

                            if (value == 'approve') {
                              await notifier.approve(device.id);
                            }

                            if (value == 'deactivate') {
                              await notifier.deactivate(device.id);
                            }

                            if (value == 'activate') {
                              await notifier.activate(device.id);
                            }

                            if (value == 'wipe') {
                              await notifier.wipe(device.id);
                            }

                            if (value == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete device?'),
                                  content: const Text(
                                    'This permanently removes the wiped device record.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await notifier.delete(device.id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            if (device.isPending)
                              const PopupMenuItem(
                                value: 'approve',
                                child: _PopupItem(
                                  icon: Icons.check_circle_outline_rounded,
                                  text: 'Approve request',
                                ),
                              ),
                            if (device.isApproved)
                              const PopupMenuItem(
                                value: 'deactivate',
                                child: _PopupItem(
                                  icon: Icons.block_outlined,
                                  text: 'Deactivate',
                                ),
                              ),
                            if (device.isDeactivated)
                              const PopupMenuItem(
                                value: 'activate',
                                child: _PopupItem(
                                  icon: Icons.restart_alt_rounded,
                                  text: 'Activate again',
                                ),
                              ),
                            if (!device.isWiped) ...[
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'wipe',
                                child: _PopupItem(
                                  icon: Icons.delete_outline_rounded,
                                  text: 'Wipe',
                                  isDanger: true,
                                ),
                              ),
                            ],
                            if (device.isWiped)
                              const PopupMenuItem(
                                value: 'delete',
                                child: _PopupItem(
                                  icon: Icons.delete_forever_rounded,
                                  text: 'Delete permanently',
                                  isDanger: true,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Failed to load devices: $error',
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final lowerStatus = status.toLowerCase();

    Color bgColor;
    Color textColor;

    if (lowerStatus.contains('active') || lowerStatus.contains('approved')) {
      bgColor = const Color(0xFFE0F8F1);
      textColor = const Color(0xFF20A67A);
    } else if (lowerStatus.contains('pending')) {
      bgColor = const Color(0xFFFFF3DC);
      textColor = const Color(0xFFC88824);
    } else if (lowerStatus.contains('deactivate') ||
        lowerStatus.contains('inactive') ||
        lowerStatus.contains('blocked')) {
      bgColor = const Color(0xFFFFEAEA);
      textColor = const Color(0xFFE74C3C);
    } else {
      bgColor = const Color(0xFFEAF0FF);
      textColor = const Color(0xFF233E8B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDanger;

  const _PopupItem({
    required this.icon,
    required this.text,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red : const Color(0xFF12275B);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isDanger ? Colors.red : const Color(0xFF00184A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
