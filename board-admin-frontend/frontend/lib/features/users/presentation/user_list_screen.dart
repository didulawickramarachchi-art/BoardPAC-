import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/user_provider.dart';
import 'user_form_screen.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const AppEmptyState(message: 'No users found');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];

              return Card(
                child: ListTile(
                  title: Text('${user.firstName} ${user.lastName}'),
                  subtitle: Text('${user.username}\n${user.boardEmail}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final notifier = ref.read(userListProvider.notifier);

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
                              const SnackBar(content: Text('Password reset sent')),
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                      PopupMenuItem(value: 'activate', child: Text('Activate')),
                      PopupMenuItem(value: 'lock', child: Text('Lock')),
                      PopupMenuItem(value: 'unlock', child: Text('Unlock')),
                      PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) => Center(child: Text('Failed to load users: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}