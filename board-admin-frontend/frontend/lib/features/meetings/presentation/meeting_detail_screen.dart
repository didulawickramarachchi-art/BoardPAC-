import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../papers/model/paper_model.dart';
import '../../papers/presentation/paper_detail_screen.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../../papers/provider/paper_provider.dart';
import '../model/meeting_model.dart';

class MeetingDetailScreen extends ConsumerWidget {
  static const _primaryBlue = Color(0xFF12275B);
  static const _background = Color(0xFFF6F7FB);

  final MeetingModel meeting;
  final bool isHistorical;

  const MeetingDetailScreen({
    super.key,
    required this.meeting,
    this.isHistorical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papers = ref.watch(paperListProvider(meeting.id));

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          isHistorical ? 'Meeting History Details' : 'Meeting Details',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh board papers',
            onPressed: () =>
                ref.read(paperListProvider(meeting.id).notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(paperListProvider(meeting.id).notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(meeting: meeting, historical: isHistorical),
            const SizedBox(height: 16),
            const _SectionTitle(
              icon: Icons.info_outline_rounded,
              title: 'Meeting information',
            ),
            const SizedBox(height: 10),
            _DetailsCard(meeting: meeting),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: _SectionTitle(
                    icon: Icons.description_outlined,
                    title: 'Board papers',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaperListScreen(
                        meetingId: meeting.id,
                        meetingTitle: meeting.title,
                      ),
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            papers.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: AppLoading(),
              ),
              error: (error, _) => _PaperError(
                error: error,
                retry: () =>
                    ref.read(paperListProvider(meeting.id).notifier).load(),
              ),
              data: (items) => items.isEmpty
                  ? const SizedBox(
                      height: 150,
                      child: AppEmptyState(
                        message: 'No board papers for this meeting',
                      ),
                    )
                  : Column(
                      children: items
                          .map(
                            (paper) => _PaperCard(
                              paper: paper,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PaperDetailScreen(paper: paper),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MeetingModel meeting;
  final bool historical;
  const _Header({required this.meeting, required this.historical});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12275B), Color(0xFF233E8B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            meeting.type == 'CIRCULAR'
                ? Icons.campaign_outlined
                : Icons.event_note_outlined,
            color: const Color(0xFFFFB52E),
            size: 34,
          ),
          const SizedBox(height: 14),
          Text(
            meeting.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(label: meeting.type),
              _HeaderChip(label: meeting.status),
              if (historical) const _HeaderChip(label: 'HISTORY'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  const _HeaderChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label.isEmpty ? '-' : label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  final MeetingModel meeting;
  const _DetailsCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final details = <(IconData, String, String)>[
      (Icons.tag_rounded, 'Meeting ID', meeting.id.toString()),
      (Icons.schedule_rounded, 'Meeting date & time', meeting.meetingDateTime),
      if ((meeting.targetDateTime ?? '').trim().isNotEmpty)
        (Icons.flag_outlined, 'Target date & time', meeting.targetDateTime!),
      (Icons.location_on_outlined, 'Location', meeting.location ?? ''),
      (Icons.category_outlined, 'Category', meeting.categoryName ?? ''),
      (
        Icons.account_tree_outlined,
        'Subcategory',
        meeting.subcategoryName ?? '',
      ),
      (Icons.notes_rounded, 'Description', meeting.description ?? ''),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _DetailRow(
              icon: details[index].$1,
              label: details[index].$2,
              value: details[index].$3,
            ),
            if (index != details.length - 1)
              const Divider(height: 1, color: Color(0xFFE8EBF2)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF233E8B), size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF7D8CB2), fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? 'Not provided' : value,
                style: const TextStyle(
                  color: Color(0xFF00184A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF12275B), size: 21),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00184A),
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _PaperCard extends StatelessWidget {
  final PaperModel paper;
  final VoidCallback onTap;
  const _PaperCard({required this.paper, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE8EBF2)),
    ),
    child: ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEAF0FF),
        child: Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF233E8B)),
      ),
      title: Text(
        paper.title,
        style: const TextStyle(
          color: Color(0xFF00184A),
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${paper.paperType}  •  Ref: ${paper.referenceNumber ?? '-'}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _PaperError extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const _PaperError({required this.error, required this.retry});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Could not load board papers: $error',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
