import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../categories/model/category_model.dart';
import '../../categories/provider/category_provider.dart';
import '../../subcategories/model/subcategory_model.dart';
import '../../subcategories/provider/subcategory_provider.dart';
import '../../users/model/user_model.dart';
import '../../users/provider/user_provider.dart';
import '../model/privilege_model.dart';
import '../provider/privilege_provider.dart';

class PrivilegeListScreen extends ConsumerWidget {
  const PrivilegeListScreen({super.key});

  static const primaryBlue = Color(0xFF12275B);
  static const darkBlue = Color(0xFF00184A);
  static const gold = Color(0xFFFFB52E);
  static const bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');
    if (!access.canManagePrivileges) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('Only secretaries can manage privileges.')),
      );
    }

    final categories = ref.watch(categoryListProvider);
    final subcategories = ref.watch(subcategoryListProvider);
    final privileges = ref.watch(privilegeListProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Category Privileges',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: categories.when(
        loading: () => const AppLoading(),
        error: (error, _) => _ErrorMessage('Failed to load categories: $error'),
        data: (categoryItems) => subcategories.when(
          loading: () => const AppLoading(),
          error: (error, _) =>
              _ErrorMessage('Failed to load subcategories: $error'),
          data: (subcategoryItems) => privileges.when(
            loading: () => const AppLoading(),
            error: (error, _) =>
                _ErrorMessage('Failed to load privileges: $error'),
            data: (privilegeItems) {
              if (categoryItems.isEmpty) {
                return const AppEmptyState(message: 'No categories found');
              }
              final sorted = [...categoryItems]
                ..sort((a, b) => (a.displayOrder ?? 0)
                    .compareTo(b.displayOrder ?? 0));
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 178,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: sorted.length,
                itemBuilder: (_, index) {
                  final category = sorted[index];
                  final categorySubcategories = subcategoryItems
                      .where((item) => item.categoryId == category.id)
                      .toList();
                  final ids = categorySubcategories.map((item) => item.id).toSet();
                  final userCount = privilegeItems
                      .where((item) => ids.contains(item.subcategoryId))
                      .map((item) => item.userId)
                      .toSet()
                      .length;
                  return _CategoryCard(
                    category: category,
                    subcategoryCount: categorySubcategories.length,
                    userCount: userCount,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CategoryUsersScreen(
                          category: category,
                          subcategories: categorySubcategories,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryUsersScreen extends ConsumerWidget {
  final CategoryModel category;
  final List<SubcategoryModel> subcategories;

  const _CategoryUsersScreen({required this.category, required this.subcategories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeListProvider);
    final userState = ref.watch(userListProvider);
    final subcategoryIds = subcategories.map((item) => item.id).toSet();
    final title = category.displayName.trim().isNotEmpty
        ? category.displayName.trim()
        : category.name;

    return Scaffold(
      backgroundColor: PrivilegeListScreen.bgColor,
      appBar: AppBar(
        backgroundColor: PrivilegeListScreen.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PrivilegeListScreen.gold,
        foregroundColor: PrivilegeListScreen.darkBlue,
        onPressed: subcategories.isEmpty
            ? null
            : () => _showAddUserDialog(context, ref, subcategoryIds),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add user'),
      ),
      body: subcategories.isEmpty
          ? const AppEmptyState(
              message: 'Add a subcategory before assigning users.')
          : privileges.when(
              loading: () => const AppLoading(),
              error: (error, _) => _ErrorMessage('Failed to load users: $error'),
              data: (items) {
                final assigned = <int, PrivilegeModel>{};
                for (final item in items) {
                  if (subcategoryIds.contains(item.subcategoryId)) {
                    assigned[item.userId] = item;
                  }
                }
                if (assigned.isEmpty) {
                  return const AppEmptyState(
                      message: 'No users assigned to this category');
                }
                final users = assigned.values.toList()
                  ..sort((a, b) => a.username.compareTo(b.username));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = users[index];
                    final matchingUsers = (userState.valueOrNull ?? [])
                        .where((user) => user.id == item.userId);
                    final user =
                        matchingUsers.isEmpty ? null : matchingUsers.first;
                    final role = normalizeRole(user?.role ?? item.assignedRole);
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF0FF),
                          child: Icon(Icons.person_outline,
                              color: PrivilegeListScreen.primaryBlue),
                        ),
                        title: Text(item.username,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          'Role type: ${_roleLabel(role)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove from category',
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () async {
                            await ref
                                .read(privilegeListProvider.notifier)
                                .removeUserFromCategory(
                                  userId: item.userId,
                                  subcategoryIds: subcategoryIds,
                                );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _showAddUserDialog(
    BuildContext context,
    WidgetRef ref,
    Set<int> subcategoryIds,
  ) async {
    final usersState = ref.read(userListProvider);
    if (!usersState.hasValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Users are still loading. Please try again.')),
      );
      return;
    }
    final privileges = ref.read(privilegeListProvider).valueOrNull ?? [];
    final assignedUserIds = privileges
        .where((item) => subcategoryIds.contains(item.subcategoryId))
        .map((item) => item.userId)
        .toSet();
    final available = usersState.value!
        .where(
          (user) =>
              user.isActive &&
              normalizeRole(user.role) == 'MEMBER' &&
              !assignedUserIds.contains(user.id),
        )
        .toList()
      ..sort((a, b) => a.username.compareTo(b.username));
    int? selectedUserId;

    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add user to category'),
          content: available.isEmpty
              ? const Text(
                  'No active Member accounts are available for this category.',
                )
              : DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Member participant',
                    helperText: 'Only active users with the Member role are shown.',
                  ),
                  items: available.map(_userOption).toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedUserId = value),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedUserId == null
                  ? null
                  : () => Navigator.pop(dialogContext, selectedUserId),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    try {
      await ref.read(privilegeListProvider.notifier).assignUserToCategory(
            userId: selected,
            subcategoryIds: subcategoryIds,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add user: $error')),
        );
      }
    }
  }

  DropdownMenuItem<int> _userOption(UserModel user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final name = fullName.isEmpty ? user.username : '$fullName (${user.username})';
    return DropdownMenuItem(
      value: user.id,
      child: Text(
        '$name — ${_roleLabel(normalizeRole(user.role))}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _roleLabel(String role) {
    return role
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int subcategoryCount;
  final int userCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.subcategoryCount,
    required this.userCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = category.displayName.trim().isNotEmpty
        ? category.displayName.trim()
        : category.name;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.category_rounded,
                  color: PrivilegeListScreen.primaryBlue, size: 32),
              const Spacer(),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: PrivilegeListScreen.darkBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('$userCount users  •  $subcategoryCount subcategories',
                  style: const TextStyle(color: Color(0xFF7D8CB2))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage(this.message);

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
}
