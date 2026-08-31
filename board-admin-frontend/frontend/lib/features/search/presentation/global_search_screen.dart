import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../agendas/provider/agenda_provider.dart';
import '../../agendas/model/agenda_item_model.dart';
import '../../meetings/model/meeting_model.dart';
import '../../meetings/presentation/meeting_detail_screen.dart';
import '../../meetings/provider/meeting_provider.dart';
import '../../papers/model/paper_model.dart';
import '../../papers/presentation/paper_detail_screen.dart';
import '../../papers/provider/paper_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final controller = TextEditingController();
  List<_Entry> index = [];
  bool loading = true;
  String? error;
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    _buildIndex();
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _buildIndex() async {
    try {
      var meetings = ref.read(meetingListProvider).valueOrNull;
      if (meetings == null) {
        await ref.read(meetingListProvider.notifier).loadMeetings();
        meetings = ref.read(meetingListProvider).valueOrNull ?? [];
      }
      final papers = ref.read(paperRepositoryProvider),
          agendas = ref.read(agendaRepositoryProvider);
      final groups = await Future.wait(
        meetings.map((meeting) async {
          final paperFuture = papers.getPapersByMeeting(meeting.id);
          final agendaFuture = agendas.getItems(meeting.id);
          return _meetingEntries(
            meeting,
            await paperFuture,
            await agendaFuture,
          );
        }),
      );
      if (mounted) {
        setState(() {
          index = groups.expand((e) => e).toList();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  List<_Entry> _meetingEntries(
    MeetingModel meeting,
    List<PaperModel> papers,
    List<AgendaItemModel> agendaItems,
  ) => [
    _Entry(
      type: _ResultType.meeting,
      title: meeting.title,
      subtitle:
          '${meeting.categoryName ?? 'Board'} · ${meeting.meetingDateTime}',
      keywords:
          '${meeting.description ?? ''} ${meeting.location ?? ''} ${meeting.subcategoryName ?? ''}',
      meeting: meeting,
    ),
    ...papers.map(
      (paper) => _Entry(
        type: _ResultType.paper,
        title: paper.title,
        subtitle: 'Paper · ${meeting.title}',
        keywords:
            '${paper.referenceNumber ?? ''} ${paper.paperType} ${paper.fileName ?? ''}',
        meeting: meeting,
        paper: paper,
      ),
    ),
    ...agendaItems.map(
      (item) => _Entry(
        type: _ResultType.agenda,
        title: item.title,
        subtitle: 'Agenda · ${meeting.title}',
        keywords: '${item.description ?? ''} ${item.numberLabel ?? ''}',
        meeting: meeting,
      ),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final terms = controller.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final results = terms.isEmpty
        ? <_Entry>[]
        : index
              .where((e) => terms.every(e.searchable.contains))
              .take(100)
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search meetings, agendas and papers',
            border: InputBorder.none,
          ),
          onChanged: (_) {
            debounce?.cancel();
            debounce = Timer(
              const Duration(milliseconds: 180),
              () => mounted ? setState(() {}) : null,
            );
          },
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Search index could not be loaded: $error'))
          : terms.isEmpty
          ? const _Hint()
          : results.isEmpty
          ? const Center(child: Text('No matching board content found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final result = results[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(result.type.icon)),
                    title: Text(result.title),
                    subtitle: Text(result.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => result.paper == null
                            ? MeetingDetailScreen(meeting: result.meeting)
                            : PaperDetailScreen(paper: result.paper!),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _ResultType {
  meeting,
  agenda,
  paper;

  IconData get icon => switch (this) {
    meeting => Icons.event_outlined,
    agenda => Icons.format_list_numbered,
    paper => Icons.description_outlined,
  };
}

class _Entry {
  final _ResultType type;
  final String title, subtitle, keywords;
  final MeetingModel meeting;
  final PaperModel? paper;
  const _Entry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.meeting,
    this.paper,
  });
  String get searchable => '$title $subtitle $keywords'.toLowerCase();
}

class _Hint extends StatelessWidget {
  const _Hint();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search, size: 64),
          SizedBox(height: 12),
          Text(
            'Search your accessible board content',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Try a meeting title, paper reference, agenda topic, board, location, or document name.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
