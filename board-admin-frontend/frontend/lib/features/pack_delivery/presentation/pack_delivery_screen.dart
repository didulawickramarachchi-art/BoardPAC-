import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../provider/pack_delivery_provider.dart';

class PackDeliveryScreen extends ConsumerWidget {
  final int? paperId;
  final int? userId;
  final String title;

  const PackDeliveryScreen({
    super.key,
    this.paperId,
    this.userId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = paperId != null
        ? ref.watch(packDeliveryByPaperProvider(paperId!))
        : ref.watch(packDeliveryByUserProvider(userId!));

    return Scaffold(
      appBar: AppBar(title: Text('Pack Delivery - $title')),
      body: asyncData.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No pack delivery records found',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.username),
                  subtitle: Text(
                    '${item.paperTitle}\nStatus: ${item.deliveryStatus}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        error: (error, _) =>
            Center(child: Text('Failed to load pack delivery: $error')),
        loading: () => const AppLoading(),
      ),
    );
  }
}
