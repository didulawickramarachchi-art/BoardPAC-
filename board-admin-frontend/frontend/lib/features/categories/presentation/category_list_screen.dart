import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/category_request.dart';
import '../provider/category_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  static const Color primaryBlue = Color(0xFF12275B);
  static const Color darkBlue = Color(0xFF00184A);
  static const Color gold = Color(0xFFFFB52E);
  static const Color bgColor = Color(0xFFF6F7FB);

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final displayNameController = TextEditingController();
    final displayOrderController = TextEditingController();

    final request = await showDialog<CategoryRequest>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final displayName = displayNameController.text.trim();
              final displayOrder = displayOrderController.text.trim();

              if (name.isEmpty || displayName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter name and display name.'),
                  ),
                );
                return;
              }

              Navigator.pop(
                context,
                CategoryRequest(
                  name: name,
                  displayName: displayName,
                  displayOrder:
                      displayOrder.isEmpty ? null : int.tryParse(displayOrder),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    nameController.dispose();
    displayNameController.dispose();
    displayOrderController.dispose();

    if (request == null) return;

    try {
      await ref
          .read(categoryRepositoryProvider)
          .createCategory(request)
          .timeout(const Duration(seconds: 10));

      ref.invalidate(categoryListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMessage.from(
                e,
                fallback: 'Failed to create category.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.canManageBoardSetup) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('You do not have access to categories.'),
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
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: darkBlue,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const AppEmptyState(
              message: 'No categories found',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final category = categories[index];

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
                          Icons.category_outlined,
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
                              category.name,
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
                                    category.displayName,
                                    maxLines: 2,
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

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'Category',
                                style: TextStyle(
                                  color: darkBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryBlue,
                          size: 16,
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
