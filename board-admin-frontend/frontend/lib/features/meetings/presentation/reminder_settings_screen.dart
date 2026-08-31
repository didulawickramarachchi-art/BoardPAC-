import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/device_notification_service.dart';
import '../provider/meeting_provider.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  static const options = {
    10080: '1 week before',
    2880: '2 days before',
    1440: '1 day before',
    120: '2 hours before',
    60: '1 hour before',
    30: '30 minutes before',
  };
  Set<int> selected = {};
  bool loading = true, saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    selected = (await DeviceNotificationService.instance.reminderOffsets())
        .toSet();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await DeviceNotificationService.instance.setReminderOffsets(
      selected.toList(),
    );
    await ref.read(meetingListProvider.notifier).loadMeetings();
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder schedule updated.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meeting reminders')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose when this device should remind you before each upcoming meeting.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 14),
              ...options.entries.map(
                (e) => CheckboxListTile(
                  value: selected.contains(e.key),
                  title: Text(e.value),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  onChanged: (checked) => setState(
                    () => checked == true
                        ? selected.add(e.key)
                        : selected.remove(e.key),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save and reschedule'),
              ),
            ],
          ),
  );
}
