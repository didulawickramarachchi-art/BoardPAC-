import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/audit_log_model.dart';
import '../provider/report_provider.dart';

class PersonalActivityScreen extends ConsumerStatefulWidget {
  const PersonalActivityScreen({super.key});
  @override
  ConsumerState<PersonalActivityScreen> createState() =>
      _PersonalActivityScreenState();
}

class _PersonalActivityScreenState
    extends ConsumerState<PersonalActivityScreen> {
  String filter = 'ALL';
  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(personalActivityProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My activity'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(personalActivityProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children:
                  [
                        'ALL',
                        'MEETING',
                        'PAPER',
                        'APPROVAL',
                        'COMMENT',
                        'ACTION_ITEM',
                        'PACK_DELIVERY',
                      ]
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(_moduleLabel(value)),
                            selected: filter == value,
                            backgroundColor: const Color(0xFF12275B),
                            selectedColor: const Color(0xFFFFB52E),
                            checkmarkColor: const Color(0xFF12275B),
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: filter == value
                                  ? const Color(0xFF12275B)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() => filter = value),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: activity.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Could not load activity: $e')),
              data: (items) {
                final visible = filter == 'ALL'
                    ? items
                    : items.where((item) => item.moduleName == filter).toList();
                if (visible.isEmpty) {
                  return const Center(
                    child: Text('No activity recorded for this filter.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(personalActivityProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _ActivityTile(item: visible[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AuditLogModel item;
  const _ActivityTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final time = DateTime.tryParse(item.actionTime)?.toLocal();
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_icon(item.moduleName))),
        title: Text(
          _actionLabel(item.actionName),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item.parameters?.trim().isNotEmpty == true ? item.parameters : 'Activity recorded'}\n${time == null ? item.actionTime : _date(time)}',
        ),
        isThreeLine: true,
        trailing: Tooltip(
          message: item.device ?? 'Unknown device',
          child: Icon(
            item.device == 'WEB' ? Icons.language : Icons.phone_android,
          ),
        ),
      ),
    );
  }
}

String _moduleLabel(String value) => value == 'ALL'
    ? 'All'
    : value
          .toLowerCase()
          .split('_')
          .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
          .join(' ');
String _actionLabel(String value) => value
    .toLowerCase()
    .split('_')
    .map((e) => e.isEmpty ? '' : '${e[0].toUpperCase()}${e.substring(1)}')
    .join(' ');
String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
IconData _icon(String m) => switch (m) {
  'MEETING' => Icons.event_outlined,
  'PAPER' => Icons.description_outlined,
  'APPROVAL' => Icons.approval_outlined,
  'COMMENT' => Icons.comment_outlined,
  'ACTION_ITEM' => Icons.task_alt_outlined,
  'PACK_DELIVERY' => Icons.download_done_outlined,
  _ => Icons.history,
};
