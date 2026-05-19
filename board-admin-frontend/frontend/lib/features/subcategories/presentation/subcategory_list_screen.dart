import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../../categories/model/category_model.dart';
import '../../categories/provider/category_provider.dart';
import '../model/subcategory_request.dart';
import '../provider/subcategory_provider.dart';

class SubcategoryListScreen extends ConsumerWidget {
  const SubcategoryListScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    List<CategoryModel> loadedCategories = [];

    try {
      loadedCategories = await ref.read(categoryListProvider.future);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorMessage.from(
              e,
              fallback: 'Failed to load categories.',
            ),
          ),
        ),
      );
      return;
    }

    final categories = {
      for (final category in loadedCategories) category.id: category,
    }.values.toList();

    if (categories.isEmpty) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a category first.'),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final displayNameController = TextEditingController();
    final displayOrderController = TextEditingController();

    int selectedCategoryId = categories.first.id;

    final request = await showDialog<SubcategoryRequest>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            return AlertDialog(
              title: const Text('Create Subcategory'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(_categoryLabel(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setLocalState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: displayOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Display Order',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final displayName = displayNameController.text.trim();
                    final displayOrderText =
                        displayOrderController.text.trim();

                    if (name.isEmpty || displayName.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter all required details.',
                          ),
                        ),
                      );
                      return;
                    }

                    int? displayOrder;

                    if (displayOrderText.isNotEmpty) {
                      displayOrder = int.tryParse(displayOrderText);

                      if (displayOrder == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Display order must be a number.',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.pop(
                      dialogContext,
                      SubcategoryRequest(
                        name: name,
                        displayName: displayName,
                        displayOrder: displayOrder,
                        categoryId: selectedCategoryId,
                      ),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    displayNameController.dispose();
    displayOrderController.dispose();

    if (request == null) return;

    try {
      await ref
          .read(subcategoryRepositoryProvider)
          .createSubcategory(request)
          .timeout(const Duration(seconds: 10));

      ref.invalidate(categoryListProvider);
      ref.invalidate(subcategoryListProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subcategory created successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorMessage.from(
              e,
              fallback: 'Failed to create subcategory.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoryListProvider);
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.canManageBoardSetup) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('You do not have access to subcategories.'),
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
          'Subcategories',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: darkBlue,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subcategory'),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: subcategoriesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No subcategories found',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final sub = items[index];

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
                        child: const Icon(
                          Icons.account_tree_outlined,
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
                              sub.name,
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
                                  Icons.label_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF7D8CB2),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    sub.displayName,
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

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                sub.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: darkBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
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
        error: (error, _) => _SubcategoryErrorState(
          message: ApiErrorMessage.from(
            error,
            fallback: 'Failed to load subcategories.',
          ),
          onRetry: () => ref.invalidate(subcategoryListProvider),
        ),
        loading: () => const AppLoading(),
      ),
    );
  }
}

String _categoryLabel(CategoryModel category) {
  if (category.displayName.trim().isNotEmpty) {
    return category.displayName.trim();
  }

  if (category.name.trim().isNotEmpty) {
    return category.name.trim();
  }

  return 'Unnamed Category';
}

class _SubcategoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SubcategoryErrorState({
    required this.message,
    required this.onRetry,
  });

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                  color: gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 30,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
