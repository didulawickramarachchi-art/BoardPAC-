import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/category_image_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../categories/provider/category_provider.dart';
import '../../subcategories/model/subcategory_model.dart';
import '../../subcategories/provider/subcategory_provider.dart';
import '../../users/provider/user_provider.dart';
import '../model/privilege_request.dart';
import '../provider/privilege_provider.dart';

class PrivilegeListScreen extends ConsumerWidget {
  const PrivilegeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');
    if (!access.canManagePrivileges) {
      return const Scaffold(
        body: Center(child: Text('Only secretaries can manage privileges.')),
      );
    }
    final subcategories = ref.watch(subcategoryListProvider);
    final categoryModels = ref.watch(categoryListProvider).valueOrNull ?? [];
    final privileges = ref.watch(privilegeListProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF12275B),
        foregroundColor: Colors.white,
        title: const Text('Privilege Categories'),
      ),
      body: subcategories.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (items) => privileges.when(
          loading: () => const AppLoading(),
          error: (error, _) => Center(child: Text('Failed to load: $error')),
          data: (assigned) {
            if (items.isEmpty) {
              return const AppEmptyState(message: 'No subcategories found');
            }
            final categories =
                items.map((item) => item.categoryName).toSet().toList()..sort();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final category = categories[index];
                final categorySubcategories = items
                    .where((item) => item.categoryName == category)
                    .toList();
                final count = assigned
                    .where(
                      (privilege) => categorySubcategories.any(
                        (subcategory) =>
                            subcategory.id == privilege.subcategoryId,
                      ),
                    )
                    .map((item) => item.userId)
                    .toSet()
                    .length;
                final matching = categoryModels.where(
                  (item) =>
                      item.name == category || item.displayName == category,
                );
                return CategoryImageCard(
                  title: category,
                  subtitle:
                      '${categorySubcategories.length} subcategories • $count members',
                  imageUrl: matching.isEmpty ? null : matching.first.imageUrl,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _CategorySubcategoriesScreen(
                        categoryName: category,
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
    );
  }
}

class _CategorySubcategoriesScreen extends ConsumerWidget {
  final String categoryName;
  final List<SubcategoryModel> subcategories;

  const _CategorySubcategoriesScreen({
    required this.categoryName,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeListProvider);
    final sorted = [...subcategories]
      ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF12275B),
        foregroundColor: Colors.white,
        title: Text(categoryName),
      ),
      body: privileges.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (assigned) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final subcategory = sorted[index];
            final count = assigned
                .where((item) => item.subcategoryId == subcategory.id)
                .map((item) => item.userId)
                .toSet()
                .length;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.account_tree_rounded),
                title: Text(_subcategoryName(subcategory)),
                subtitle: Text('$count members with privileges'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SubcategoryUsersScreen(subcategory),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SubcategoryUsersScreen extends ConsumerWidget {
  final SubcategoryModel subcategory;
  const _SubcategoryUsersScreen(this.subcategory);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_subcategoryName(subcategory))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addUser(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add user'),
      ),
      body: privileges.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (items) {
          final assigned =
              items
                  .where((item) => item.subcategoryId == subcategory.id)
                  .toList()
                ..sort((a, b) => a.username.compareTo(b.username));
          if (assigned.isEmpty) {
            return const AppEmptyState(
              message: 'No users assigned to this subcategory',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: assigned.length,
            itemBuilder: (_, index) {
              final privilege = assigned[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(privilege.username),
                  subtitle: Text('Role: ${privilege.assignedRole}'),
                  trailing: IconButton(
                    tooltip: 'Remove from subcategory',
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => ref
                        .read(privilegeListProvider.notifier)
                        .remove(
                          userId: privilege.userId,
                          subcategoryId: subcategory.id,
                        ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addUser(BuildContext context, WidgetRef ref) async {
    final users = ref.read(userListProvider).valueOrNull;
    if (users == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Users are still loading.')));
      return;
    }
    final assignedIds = (ref.read(privilegeListProvider).valueOrNull ?? [])
        .where((item) => item.subcategoryId == subcategory.id)
        .map((item) => item.userId)
        .toSet();
    final available = users
        .where(
          (user) =>
              user.isActive &&
              normalizeRole(user.role) == 'MEMBER' &&
              !assignedIds.contains(user.id),
        )
        .toList();
    int? selectedId;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Add user to subcategory'),
          content: available.isEmpty
              ? const Text('No active Member accounts are available.')
              : DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Member'),
                  items: available
                      .map(
                        (user) => DropdownMenuItem(
                          value: user.id,
                          child: Text(user.username),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedId = value),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.pop(dialogContext, selectedId),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(privilegeListProvider.notifier)
          .assign(
            PrivilegeRequest(
              userId: result,
              subcategoryId: subcategory.id,
              assignedRole: 'MEMBER',
            ),
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add user: $error')));
      }
    }
  }
}

String _subcategoryName(SubcategoryModel item) =>
    item.displayName.trim().isEmpty ? item.name : item.displayName.trim();
