import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/setting_request.dart';
import '../provider/setting_provider.dart';

class SettingGroupScreen extends ConsumerWidget {
  final String group;

  const SettingGroupScreen({super.key, required this.group});

  static const Color navy = Color(0xFF14275B);
  static const Color bgColor = Color(0xFFF6F7FC);
  static const Color cardColor = Colors.white;
  static const Color iconBg = Color(0xFFE9ECF3);
  static const Color arrowBg = Color(0xFFFFF1D8);
  static const Color subTextColor = Color(0xFF6E7FA8);

  String _formatTitle(String value) {
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Add / Update ${_formatTitle(group)} Setting',
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogTextField(
                controller: keyController,
                label: 'Setting Key',
                icon: Icons.key_rounded,
              ),
              const SizedBox(height: 14),
              _DialogTextField(
                controller: valueController,
                label: 'Setting Value',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 14),
              _DialogTextField(
                controller: descController,
                label: 'Description',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: subTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await ref
                  .read(settingGroupProvider(group).notifier)
                  .save(
                    SettingRequest(
                      settingGroup: group,
                      settingKey: keyController.text.trim(),
                      settingValue: valueController.text.trim(),
                      description: descController.text.trim(),
                    ),
                  );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(settingGroupProvider(group));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _formatTitle(group),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () => _showEditDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => _showEditDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: asyncData.when(
        data: (items) {
          if (items.isEmpty) {
            return const _EmptySettingsView();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        color: navy,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.settingKey,
                            style: const TextStyle(
                              color: navy,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: arrowBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.settingValue,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if ((item.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.description!,
                              style: const TextStyle(
                                color: subTextColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load settings:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        loading: () => const AppLoading(),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: navy),
        filled: true,
        fillColor: iconBg.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: navy, width: 1.4),
        ),
      ),
    );
  }
}

class _EmptySettingsView extends StatelessWidget {
  const _EmptySettingsView();

  static const Color navy = Color(0xFF14275B);
  static const Color subTextColor = Color(0xFF6E7FA8);
  static const Color iconBg = Color(0xFFE9ECF3);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.settings_rounded, color: navy, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'No settings found',
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the + button to add a new setting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
