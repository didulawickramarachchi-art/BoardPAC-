import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../provider/access_provider.dart';

class AccessValidationScreen extends ConsumerStatefulWidget {
  const AccessValidationScreen({super.key});

  @override
  ConsumerState<AccessValidationScreen> createState() => _AccessValidationScreenState();
}

class _AccessValidationScreenState extends ConsumerState<AccessValidationScreen> {
  final userIdController = TextEditingController(text: '1');
  String channel = 'WEB';

  @override
  Widget build(BuildContext context) {
    final args = (userId: int.tryParse(userIdController.text) ?? 1, channel: channel);
    final asyncData = ref.watch(accessValidationProvider(args));

    return Scaffold(
      appBar: AppBar(title: const Text('Access Validation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(labelText: 'User ID'),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: channel,
              items: const [
                DropdownMenuItem(value: 'WEB', child: Text('WEB')),
                DropdownMenuItem(value: 'DEVICE', child: Text('DEVICE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => channel = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asyncData.when(
                data: (item) => Card(
                  child: ListTile(
                    title: Text(item.username),
                    subtitle: Text(
                      'Board Type: ${item.boardType ?? '-'}\n'
                      'Requested Channel: ${item.requestedChannel}\n'
                      'Reason: ${item.reason}',
                    ),
                    isThreeLine: true,
                    trailing: AppStatusChip(label: item.allowed ? 'ALLOWED' : 'DENIED'),
                  ),
                ),
                error: (e, _) => Center(child: Text('Failed to validate access: $e')),
                loading: () => const AppLoading(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}