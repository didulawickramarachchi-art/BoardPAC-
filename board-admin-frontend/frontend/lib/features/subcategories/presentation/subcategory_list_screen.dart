import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/subcategory_provider.dart';

class SubcategoryListScreen extends ConsumerWidget {
  const SubcategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subcategories')),
      body: subcategoriesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No subcategories found');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final sub = items[index];
              return Card(
                child: ListTile(
                  title: Text(sub.name),
                  subtitle: Text(
                    '${sub.displayName}\nCategory: ${sub.categoryName}',
                  ),
                  isThreeLine: true,
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

class _SubcategoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SubcategoryErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
