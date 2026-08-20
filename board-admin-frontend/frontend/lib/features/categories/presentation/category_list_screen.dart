import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_glass_surface.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../meetings/provider/meeting_provider.dart';
import '../../privileges/provider/privilege_provider.dart';
import '../../subcategories/provider/subcategory_provider.dart';
import '../provider/category_provider.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  Future<void> _openCreateScreen(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
    );

    if (created == true) {
      ref.invalidate(categoryListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully.')),
        );
      }
    }
  }

  Future<void> _openEditScreen(
    BuildContext context,
    WidgetRef ref,
    category,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );

    if (updated == true) {
      ref.invalidate(categoryListProvider);
      ref.invalidate(meetingListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully.')),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String title,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: Text(
            'Delete "$title"? This permanently deletes every subcategory in '
            'it and all related privileges, meetings, agendas, papers, '
            'attachments, comments, participants, notes, approvals, and '
            'sharing records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    category,
  ) async {
    final confirmed = await _showDeleteConfirmation(context, category.name);
    if (confirmed != true) return;

    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(categoryListProvider);
      ref.invalidate(subcategoryListProvider);
      ref.invalidate(privilegeListProvider);
      ref.invalidate(meetingListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category and all related data deleted.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete category: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);

    if (!access.canViewCategories) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('You do not have access to categories.')),
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
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: access.canManageCategories
          ? FloatingActionButton.extended(
              backgroundColor: gold,
              foregroundColor: darkBlue,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Category'),
              onPressed: () => _openCreateScreen(context, ref),
            )
          : null,
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const AppEmptyState(message: 'No categories found');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];

              return Container(
                height: 132,
                clipBehavior: Clip.antiAlias,
                decoration: AppGlassDecoration.surface(
                  borderRadius: BorderRadius.circular(26),
                  tint: const Color(0xFFBFC9E2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        width: 112,
                        height: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: (category.imageUrl ?? '').trim().isNotEmpty
                            ? Image.network(
                                category.imageUrl!.trim(),
                                fit: BoxFit.cover,
                                cacheWidth: 440,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) =>
                                    const _CategoryPlaceholder(),
                              )
                            : const _CategoryPlaceholder(),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.displayName.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 19,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Row(
                              children: [
                                const Icon(
                                  Icons.label_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF7D8CB2),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7D8CB2),
                                      fontSize: 12,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 7),
                            const _CategoryGlassBadge(),
                          ],
                        ),
                      ),

                      if (access.canManageCategories)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip:
                                    (category.imageUrl ?? '').trim().isEmpty
                                    ? 'Add category image'
                                    : 'Edit category',
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryBlue.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    _openEditScreen(context, ref, category),
                                icon: Icon(
                                  (category.imageUrl ?? '').trim().isEmpty
                                      ? Icons.add_photo_alternate_outlined
                                      : Icons.edit_outlined,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 5),
                              IconButton(
                                tooltip: 'Delete category',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFEAEA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    _deleteCategory(context, ref, category),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 30,
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Failed to load categories:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const AppLoading(),
      ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9EDF7),
      child: Center(
        child: Icon(
          Icons.category_outlined,
          color: CategoryListScreen.primaryBlue,
          size: 38,
        ),
      ),
    );
  }
}

class _CategoryGlassBadge extends StatelessWidget {
  const _CategoryGlassBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB000), Color(0xFFFFC538)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.58),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB000).withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.45),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: const Text(
        'CATEGORY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
