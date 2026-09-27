import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_glass_surface.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/device_model.dart';
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
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);

    if (!access.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to devices.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

          final entries = _groupedDeviceEntries(devices);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(deviceListProvider.notifier).loadDevices(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final entry = entries[index];
                if (entry is _DeviceUserGroup) {
                  return _DeviceUserHeader(group: entry);
                }
                final device = entry as DeviceModel;

                final deviceInfo = device.deviceInfo ?? 'Unknown device';
                final status = device.status ?? '-';
                final scheme = Theme.of(context).colorScheme;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Container(
                  decoration: isDark
                      ? AppGlassDecoration.surface(
                          borderRadius: BorderRadius.circular(22),
                          tint: scheme.surface,
                          darkMode: true,
                        )
                      : BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
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
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _deviceIcon(deviceInfo),
                            color: scheme.primary,
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
                                    Icons.info_outline_rounded,
                                    size: 15,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      deviceInfo,
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

                              if (device.username != null &&
                                  device.username!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Requested by ${device.username}',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
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
                          color: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: scheme.primary,
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
                              if (!context.mounted) return;
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete device?'),
                                  content: const Text(
                                    'This permanently removes the wiped device record.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
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

class _DeviceUserGroup {
  final int? userId;
  final String username;
  final int pendingCount;
  final int approvedCount;

  const _DeviceUserGroup({
    required this.userId,
    required this.username,
    required this.pendingCount,
    required this.approvedCount,
  });
}

List<Object> _groupedDeviceEntries(List<DeviceModel> devices) {
  final grouped = <String, List<DeviceModel>>{};
  for (final device in devices) {
    final key = device.userId != null
        ? 'id:${device.userId}'
        : 'username:${device.username ?? 'unknown'}';
    grouped.putIfAbsent(key, () => []).add(device);
  }

  final groups = grouped.values.toList()
    ..sort((a, b) {
      final aName = a.first.username ?? 'Unknown user';
      final bName = b.first.username ?? 'Unknown user';
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

  final entries = <Object>[];
  for (final groupDevices in groups) {
    groupDevices.sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      return a.deviceId.compareTo(b.deviceId);
    });
    final first = groupDevices.first;
    entries.add(
      _DeviceUserGroup(
        userId: first.userId,
        username: first.username?.trim().isNotEmpty == true
            ? first.username!.trim()
            : 'Unknown user',
        pendingCount: groupDevices.where((device) => device.isPending).length,
        approvedCount: groupDevices.where((device) => device.isApproved).length,
      ),
    );
    entries.addAll(groupDevices);
  }
  return entries;
}

class _DeviceUserHeader extends StatelessWidget {
  final _DeviceUserGroup group;

  const _DeviceUserHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: scheme.onSurface, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.username,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  group.userId == null
                      ? 'User ID unavailable'
                      : 'User ID: ${group.userId}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _DeviceCountChip(
            label: 'Pending',
            count: group.pendingCount,
            color: const Color(0xFFFFB52E),
          ),
          const SizedBox(width: 7),
          _DeviceCountChip(
            label: 'Approved',
            count: group.approvedCount,
            color: const Color(0xFF20A67A),
          ),
        ],
      ),
    );
  }
}

class _DeviceCountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _DeviceCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      '$label $count',
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
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
    final scheme = Theme.of(context).colorScheme;
    final color = isDanger ? scheme.error : scheme.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isDanger ? scheme.error : scheme.onSurface,
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
