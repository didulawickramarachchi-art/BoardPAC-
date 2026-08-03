import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/user_model.dart';
import '../provider/user_provider.dart';
import 'user_form_screen.dart';
import 'add_user_screen.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.canViewUsers) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('You do not have access to users.'),
        ),
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
          'Users',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: access.canManageUsers
          ? FloatingActionButton.extended(
              backgroundColor: gold,
              foregroundColor: darkBlue,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add User'),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen()),
                );
                if (created == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created successfully.')),
                  );
                }
              },
            )
          : null,
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const AppEmptyState(message: 'No users found');
          }

          final entries = _categorizedEntries(users);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final entry = entries[index];
              if (entry is _UserSection) {
                return _UserSectionHeader(section: entry);
              }
              final user = entry as UserModel;
              final fullName = '${user.firstName} ${user.lastName}'.trim();
              final initials = _getInitials(fullName);

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
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: gold.withOpacity(0.18),
                        backgroundImage: user.profilePictureUrl != null &&
                                user.profilePictureUrl!.isNotEmpty
                            ? ResizeImage(
                                NetworkImage(user.profilePictureUrl!),
                                width: 128,
                                height: 128,
                              )
                            : null,
                        child: user.profilePictureUrl == null ||
                                user.profilePictureUrl!.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: darkBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Unknown User' : fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF7D8CB2),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    user.username,
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

                            if ((user.status?.trim().isNotEmpty ?? false) ||
                                (user.role?.trim().isNotEmpty ?? false)) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  if (user.role?.trim().isNotEmpty ?? false)
                                    _RoleChip(role: user.role!),
                                  if (user.status?.trim().isNotEmpty ?? false)
                                    AppStatusChip(label: user.status!),
                                ],
                              ),
                            ],

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 15,
                                  color: Color(0xFF7D8CB2),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    user.boardEmail,
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
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      if (access.canManageUsers)
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
                            final notifier =
                                ref.read(userListProvider.notifier);

                            if (value == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserFormScreen(user: user),
                                ),
                              );
                              return;
                            }

                            final actionLabel = _actionLabel(value);
                            if (actionLabel == null) return;

                            if (value == 'activate' || value == 'deactivate') {
                              final confirmed = await _confirmStatusChange(
                                context,
                                userName: fullName.isEmpty
                                    ? user.username
                                    : fullName,
                                activate: value == 'activate',
                              );
                              if (!confirmed || !context.mounted) return;
                            }

                            try {
                              switch (value) {
                                case 'deactivate':
                                  await notifier.deactivateUser(user.id);
                                  break;
                                case 'activate':
                                  await notifier.activateUser(user.id);
                                  break;
                                case 'lock':
                                  await notifier.lockUser(user.id);
                                  break;
                                case 'unlock':
                                  await notifier.unlockUser(user.id);
                                  break;
                                case 'reset':
                                  await notifier.resetPassword(user.id);
                                  break;
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$actionLabel successful'),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not ${actionLabel.toLowerCase()}. '
                                      'Please try again.',
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: _PopupItem(
                                icon: Icons.edit_outlined,
                                text: 'Edit',
                              ),
                            ),
                            if (user.isDeactivated)
                              const PopupMenuItem(
                                value: 'activate',
                                child: _PopupItem(
                                  icon: Icons.check_circle_outline,
                                  text: 'Activate',
                                ),
                              ),
                            if (!user.isDeactivated)
                              const PopupMenuItem(
                                value: 'deactivate',
                                child: _PopupItem(
                                  icon: Icons.block_outlined,
                                  text: 'Deactivate',
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'lock',
                              child: _PopupItem(
                                icon: Icons.lock_outline,
                                text: 'Lock',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'unlock',
                              child: _PopupItem(
                                icon: Icons.lock_open_outlined,
                                text: 'Unlock',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'reset',
                              child: _PopupItem(
                                icon: Icons.restart_alt_rounded,
                                text: 'Reset Password',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(userListProvider.notifier).loadUsers(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const AppLoading(),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PopupItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Color(0xFF12275B),
        ),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Color(0xFF00184A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _getInitials(String name) {
  final cleanName = name.trim();

  if (cleanName.isEmpty) return 'U';

  final parts = cleanName.split(RegExp(r'\s+'));

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

List<Object> _categorizedEntries(List<UserModel> users) {
  const categories = [
    ('ADMIN', 'Admins', Icons.admin_panel_settings_outlined),
    ('SECRETARY', 'Secretaries', Icons.business_center_outlined),
    ('MEMBER', 'Members', Icons.groups_outlined),
  ];
  final entries = <Object>[];
  for (final category in categories) {
    final categoryUsers = users.where((user) {
      final role = normalizeRole(user.role);
      return category.$1 == 'MEMBER'
          ? role != 'ADMIN' && role != 'SECRETARY'
          : role == category.$1;
    }).toList()
      ..sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    entries.add(_UserSection(category.$2, categoryUsers.length, category.$3));
    entries.addAll(categoryUsers);
  }
  return entries;
}

class _UserSection {
  final String title;
  final int count;
  final IconData icon;
  const _UserSection(this.title, this.count, this.icon);
}

class _UserSectionHeader extends StatelessWidget {
  final _UserSection section;
  const _UserSectionHeader({required this.section});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(section.icon, color: UserListScreen.primaryBlue, size: 21),
      const SizedBox(width: 9),
      Text(section.title, style: const TextStyle(color: UserListScreen.darkBlue, fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: UserListScreen.primaryBlue.withOpacity(0.09), borderRadius: BorderRadius.circular(20)),
        child: Text('${section.count}', style: const TextStyle(color: UserListScreen.primaryBlue, fontWeight: FontWeight.w800)),
      ),
    ],
  );
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeRole(role);
    final label = normalized
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: UserListScreen.primaryBlue.withOpacity(0.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.badge_outlined,
            size: 13,
            color: UserListScreen.primaryBlue,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: UserListScreen.primaryBlue,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String? _actionLabel(String value) {
  return switch (value) {
    'activate' => 'User activation',
    'deactivate' => 'User deactivation',
    'lock' => 'User lock',
    'unlock' => 'User unlock',
    'reset' => 'Password reset',
    _ => null,
  };
}

Future<bool> _confirmStatusChange(
  BuildContext context, {
  required String userName,
  required bool activate,
}) async {
  final verb = activate ? 'activate' : 'deactivate';
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${activate ? 'Activate' : 'Deactivate'} user?'),
          content: Text('Are you sure you want to $verb $userName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(activate ? 'Activate' : 'Deactivate'),
            ),
          ],
        ),
      ) ??
      false;
}
