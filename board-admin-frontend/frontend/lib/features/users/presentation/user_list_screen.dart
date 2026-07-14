import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/user_provider.dart';
import 'user_form_screen.dart';

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
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const AppEmptyState(message: 'No users found');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final user = users[index];
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
                            ? NetworkImage(user.profilePictureUrl!)
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

                            switch (value) {
                              case 'edit':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserFormScreen(user: user),
                                  ),
                                );
                                break;

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

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset sent'),
                                    ),
                                  );
                                }
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: _PopupItem(
                                icon: Icons.edit_outlined,
                                text: 'Edit',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'activate',
                              child: _PopupItem(
                                icon: Icons.check_circle_outline,
                                text: 'Activate',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'deactivate',
                              child: _PopupItem(
                                icon: Icons.block_outlined,
                                text: 'Deactivate',
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
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
