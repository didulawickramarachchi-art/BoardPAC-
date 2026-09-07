import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../agendas/model/agenda_item_model.dart';
import '../../agendas/model/agenda_section_model.dart';
import '../../agendas/presentation/agenda_section_screen.dart';
import '../../agendas/provider/agenda_provider.dart';
import '../../approvals/model/approval_model.dart';
import '../../approvals/provider/approval_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../papers/model/paper_model.dart';
import '../../papers/presentation/paper_detail_screen.dart';
import '../../papers/presentation/paper_list_screen.dart';
import '../../papers/provider/paper_provider.dart';
import '../model/meeting_model.dart';
import '../model/meeting_participant_model.dart';
import '../model/meeting_minutes_model.dart';
import '../model/private_meeting_note_model.dart';
import '../provider/meeting_provider.dart';
import '../provider/meeting_workspace_provider.dart';
import 'participant_list_screen.dart';
import 'action_items_tab.dart';

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
    final sections = ref.watch(agendaSectionProvider(meeting.id));
    final items = ref.watch(agendaItemProvider(meeting.id));
    final participants = ref.watch(participantListProvider(meeting.id));
    final notes = ref.watch(privateMeetingNotesProvider(meeting.id));
    final minutes = ref.watch(meetingMinutesProvider(meeting.id));
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);

    Future<void> refreshWorkspace() async {
      // Read and invalidate everything before awaiting. The screen may be
      // closed while network requests are running, which disposes this ref.
      final paperNotifier = ref.read(paperListProvider(meeting.id).notifier);
      final sectionNotifier = ref.read(
        agendaSectionProvider(meeting.id).notifier,
      );
      final itemNotifier = ref.read(agendaItemProvider(meeting.id).notifier);
      final participantNotifier = ref.read(
        participantListProvider(meeting.id).notifier,
      );
      ref.invalidate(privateMeetingNotesProvider(meeting.id));
      ref.invalidate(meetingMinutesProvider(meeting.id));

      await Future.wait([
        paperNotifier.load(),
        sectionNotifier.load(),
        itemNotifier.load(),
        participantNotifier.load(),
      ]);
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          title: Text(
            isHistorical ? 'Meeting History' : 'Meeting Workspace',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            FavoriteButton(
              type: 'MEETING',
              targetId: meeting.id,
              color: Colors.white,
            ),
            if (access.canManageMeetings)
              PopupMenuButton<String>(
                tooltip: 'Manage workspace',
                onSelected: (value) async {
                  final route = switch (value) {
                    'agenda' => MaterialPageRoute<void>(
                      builder: (_) => AgendaSectionScreen(
                        meetingId: meeting.id,
                        meetingTitle: meeting.title,
                      ),
                    ),
                    'papers' => MaterialPageRoute<void>(
                      builder: (_) => PaperListScreen(
                        meetingId: meeting.id,
                        meetingTitle: meeting.title,
                      ),
                    ),
                    _ => MaterialPageRoute<void>(
                      builder: (_) => ParticipantListScreen(
                        meetingId: meeting.id,
                        meetingTitle: meeting.title,
                      ),
                    ),
                  };
                  await Navigator.push(context, route);
                  if (!context.mounted) return;
                  await refreshWorkspace();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'agenda', child: Text('Manage agenda')),
                  PopupMenuItem(value: 'papers', child: Text('Manage papers')),
                  PopupMenuItem(
                    value: 'participants',
                    child: Text('Manage participants'),
                  ),
                ],
              ),
            IconButton(
              tooltip: 'Refresh workspace',
              onPressed: refreshWorkspace,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFFFFB52E),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFBBC7E5),
            tabs: [
              Tab(icon: Icon(Icons.info_outline_rounded), text: 'Overview'),
              Tab(icon: Icon(Icons.format_list_numbered), text: 'Agenda'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Participants'),
              Tab(icon: Icon(Icons.note_alt_outlined), text: 'Notes'),
              Tab(icon: Icon(Icons.task_alt_outlined), text: 'Actions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              meeting: meeting,
              historical: isHistorical,
              papers: papers,
              participants: participants,
              currentUserId: auth.userId,
              showRsvp: access.isMember && !isHistorical,
              onRefresh: refreshWorkspace,
            ),
            _AgendaTab(
              meeting: meeting,
              sections: sections,
              items: items,
              papers: papers,
              onRefresh: refreshWorkspace,
            ),
            _ParticipantsTab(
              participants: participants,
              onRefresh: refreshWorkspace,
            ),
            _NotesMinutesTab(
              meetingId: meeting.id,
              notes: notes,
              minutes: minutes,
              canManageMinutes: access.canManageMeetings,
            ),
            ActionItemsTab(
              meetingId: meeting.id,
              participants: participants.value ?? const [],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final MeetingModel meeting;
  final bool historical;
  final AsyncValue<List<PaperModel>> papers;
  final AsyncValue<List<MeetingParticipantModel>> participants;
  final int? currentUserId;
  final bool showRsvp;
  final Future<void> Function() onRefresh;

  const _OverviewTab({
    required this.meeting,
    required this.historical,
    required this.papers,
    required this.participants,
    required this.currentUserId,
    required this.showRsvp,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(meeting: meeting, historical: historical),
        if (showRsvp && currentUserId != null) ...[
          const SizedBox(height: 12),
          _RsvpCard(
            meetingId: meeting.id,
            currentUserId: currentUserId!,
            participants: participants,
          ),
        ],
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
          loading: () =>
              const Padding(padding: EdgeInsets.all(24), child: AppLoading()),
          error: (error, _) => _PaperError(error: error, retry: onRefresh),
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
                              builder: (_) => PaperDetailScreen(paper: paper),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    ),
  );
}

class _AgendaTab extends StatelessWidget {
  final MeetingModel meeting;
  final AsyncValue<List<AgendaSectionModel>> sections;
  final AsyncValue<List<AgendaItemModel>> items;
  final AsyncValue<List<PaperModel>> papers;
  final Future<void> Function() onRefresh;

  const _AgendaTab({
    required this.meeting,
    required this.sections,
    required this.items,
    required this.papers,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isLoading || items.isLoading || papers.isLoading) {
      return const AppLoading();
    }
    if (sections.hasError || items.hasError || papers.hasError) {
      return _WorkspaceError(
        message: 'Could not load the complete meeting agenda.',
        onRetry: onRefresh,
      );
    }
    final sectionList = [...?sections.valueOrNull]
      ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
    final itemList = [...?items.valueOrNull]
      ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
    final paperList = papers.valueOrNull ?? const <PaperModel>[];
    if (sectionList.isEmpty && itemList.isEmpty) {
      return const AppEmptyState(message: 'No agenda has been published yet');
    }

    final unassigned = itemList
        .where((item) => item.sectionId == null)
        .toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _AgendaSummary(
            sectionCount: sectionList.length,
            itemCount: itemList.length,
            paperCount: paperList.length,
          ),
          const SizedBox(height: 14),
          for (final section in sectionList)
            _AgendaSectionCard(
              section: section,
              items: itemList
                  .where((item) => item.sectionId == section.id)
                  .toList(),
              papers: paperList,
            ),
          if (unassigned.isNotEmpty)
            _AgendaSectionCard(
              section: AgendaSectionModel(id: -1, title: 'Other agenda items'),
              items: unassigned,
              papers: paperList,
            ),
        ],
      ),
    );
  }
}

class _AgendaSummary extends StatelessWidget {
  final int sectionCount;
  final int itemCount;
  final int paperCount;
  const _AgendaSummary({
    required this.sectionCount,
    required this.itemCount,
    required this.paperCount,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF12275B),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _AgendaCount(value: sectionCount, label: 'Sections'),
        _AgendaCount(value: itemCount, label: 'Items'),
        _AgendaCount(value: paperCount, label: 'Papers'),
      ],
    ),
  );
}

class _AgendaCount extends StatelessWidget {
  final int value;
  final String label;
  const _AgendaCount({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: const TextStyle(
          color: Color(0xFFFFB52E),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white)),
    ],
  );
}

class _AgendaSectionCard extends StatelessWidget {
  final AgendaSectionModel section;
  final List<AgendaItemModel> items;
  final List<PaperModel> papers;
  const _AgendaSectionCard({
    required this.section,
    required this.items,
    required this.papers,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: true,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAF0FF),
        child: Text(
          section.numberLabel?.trim().isNotEmpty == true
              ? section.numberLabel!
              : '${section.displayOrder ?? ''}',
          style: const TextStyle(
            color: Color(0xFF233E8B),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        section.title,
        style: const TextStyle(
          color: Color(0xFF00184A),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        '${items.length} agenda item${items.length == 1 ? '' : 's'}',
      ),
      children: items.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.all(18),
                child: Text('No items in this section'),
              ),
            ]
          : items
                .map(
                  (item) => _AgendaItemTile(
                    item: item,
                    papers: papers
                        .where((paper) => paper.agendaItemId == item.id)
                        .toList(),
                  ),
                )
                .toList(),
    ),
  );
}

class _AgendaItemTile extends StatelessWidget {
  final AgendaItemModel item;
  final List<PaperModel> papers;
  const _AgendaItemTile({required this.item, required this.papers});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE8EBF2))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.numberLabel ?? '',
              style: const TextStyle(
                color: Color(0xFF233E8B),
                fontWeight: FontWeight.w900,
              ),
            ),
            if ((item.numberLabel ?? '').isNotEmpty) const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _ItemTypeChip(type: item.itemType),
          ],
        ),
        if ((item.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            item.description!,
            style: const TextStyle(color: Color(0xFF7D8CB2)),
          ),
        ],
        if (papers.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...papers.map((paper) => _AgendaPaperTile(paper: paper)),
        ],
      ],
    ),
  );
}

class _ItemTypeChip extends StatelessWidget {
  final String type;
  const _ItemTypeChip({required this.type});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFB52E).withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      type,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _AgendaPaperTile extends StatelessWidget {
  final PaperModel paper;
  const _AgendaPaperTile({required this.paper});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF6F7FB),
    borderRadius: BorderRadius.circular(12),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: Text(paper.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 3,
        runSpacing: 2,
        children: [
          Text('Version ${paper.versionNumber ?? 1}'),
          const Text('·'),
          _PaperReadStatus(paperId: paper.id),
          if (paper.requiresApproval) ...[
            const Text('·'),
            _PaperApprovalStatus(paperId: paper.id),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaperDetailScreen(paper: paper)),
      ),
    ),
  );
}

class _PaperApprovalStatus extends ConsumerWidget {
  final int paperId;
  const _PaperApprovalStatus({required this.paperId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(approvalListProvider(paperId));
    return Text(
      approvals.maybeWhen(
        data: _approvalSummary,
        orElse: () => 'Approval pending',
      ),
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}

class _PaperReadStatus extends ConsumerWidget {
  final int paperId;
  const _PaperReadStatus({required this.paperId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paperReadStateProvider(paperId));
    return state.maybeWhen(
      data: (value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value.seen
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 14,
            color: value.seen
                ? const Color(0xFF168A68)
                : const Color(0xFF7D8CB2),
          ),
          const SizedBox(width: 3),
          Text(
            value.completed
                ? 'Completed'
                : value.seen
                ? 'Page ${value.lastPage}'
                : 'Unseen',
            style: TextStyle(
              color: value.seen
                  ? const Color(0xFF168A68)
                  : const Color(0xFF7D8CB2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      orElse: () => const Text('Unseen'),
    );
  }
}

String _approvalSummary(List<ApprovalModel> approvals) {
  if (approvals.isEmpty) return 'Approval pending';
  final statuses = approvals
      .map((approval) => approval.approvalStatus.trim().toUpperCase())
      .toList();
  if (statuses.any((status) => status == 'REJECTED')) return 'Rejected';
  if (statuses.every((status) => status == 'APPROVED')) return 'Approved';
  return 'Approval pending';
}

class _RsvpCard extends ConsumerWidget {
  final int meetingId;
  final int currentUserId;
  final AsyncValue<List<MeetingParticipantModel>> participants;
  const _RsvpCard({
    required this.meetingId,
    required this.currentUserId,
    required this.participants,
  });

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          status == 'DECLINED' ? 'Decline invitation' : 'RSVP response',
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: status == 'DECLINED'
                ? 'Reason (recommended)'
                : 'Note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, reasonController.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await ref
        .read(participantListProvider(meetingId).notifier)
        .rsvp(status, reason);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => participants.maybeWhen(
    data: (items) {
      final mine = items
          .where((item) => item.userId == currentUserId)
          .firstOrNull;
      if (mine == null) return const SizedBox.shrink();
      return Card(
        color: const Color(0xFFFFF8E8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your invitation: ${mine.participantStatus}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              if (mine.statusReason?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(mine.statusReason!),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _respond(context, ref, 'ACCEPTED'),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _respond(context, ref, 'TENTATIVE'),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Tentative'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _respond(context, ref, 'CONCALL'),
                    icon: const Icon(Icons.phone_in_talk_outlined),
                    label: const Text('Join remotely'),
                  ),
                  TextButton.icon(
                    onPressed: () => _respond(context, ref, 'DECLINED'),
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
    orElse: () => const SizedBox.shrink(),
  );
}

class _ParticipantsTab extends StatelessWidget {
  final AsyncValue<List<MeetingParticipantModel>> participants;
  final Future<void> Function() onRefresh;
  const _ParticipantsTab({required this.participants, required this.onRefresh});

  @override
  Widget build(BuildContext context) => participants.when(
    loading: () => const AppLoading(),
    error: (_, _) => _WorkspaceError(
      message: 'Could not load meeting participants.',
      onRetry: onRefresh,
    ),
    data: (items) => RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              children: const [
                SizedBox(
                  height: 300,
                  child: AppEmptyState(
                    message: 'No participants have been assigned',
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (_, index) {
                final participant = items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF0FF),
                      child: Text(
                        participant.username.isEmpty
                            ? '?'
                            : participant.username[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      participant.username,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle:
                        participant.statusReason?.trim().isNotEmpty == true
                        ? Text(participant.statusReason!)
                        : null,
                    trailing: _ParticipantStatus(
                      status: participant.participantStatus,
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

class _ParticipantStatus extends StatelessWidget {
  final String status;
  const _ParticipantStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final color = normalized.contains('ACCEPT') || normalized.contains('ATTEND')
        ? const Color(0xFF168A68)
        : normalized.contains('DECLIN')
        ? const Color(0xFFC43D3D)
        : const Color(0xFFC88824);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotesMinutesTab extends ConsumerWidget {
  final int meetingId;
  final AsyncValue<List<PrivateMeetingNoteModel>> notes;
  final AsyncValue<List<MeetingMinutesModel>> minutes;
  final bool canManageMinutes;

  const _NotesMinutesTab({
    required this.meetingId,
    required this.notes,
    required this.minutes,
    required this.canManageMinutes,
  });

  Future<String?> _editText(
    BuildContext context, {
    required String title,
    String initialValue = '',
    String hint = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 12,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value?.trim().isEmpty == true ? null : value;
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final text = await _editText(
      context,
      title: 'New private note',
      hint: 'Only you can see this note',
    );
    if (text == null) return;
    await ref.read(meetingWorkspaceRepositoryProvider).addNote(meetingId, text);
    ref.invalidate(privateMeetingNotesProvider(meetingId));
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    PrivateMeetingNoteModel note,
  ) async {
    final text = await _editText(
      context,
      title: 'Edit private note',
      initialValue: note.noteText,
    );
    if (text == null) return;
    await ref
        .read(meetingWorkspaceRepositoryProvider)
        .updateNote(note.id, text);
    ref.invalidate(privateMeetingNotesProvider(meetingId));
  }

  Future<void> _createMinutes(BuildContext context, WidgetRef ref) async {
    final text = await _editText(
      context,
      title: 'Create minutes draft',
      hint: 'Enter the official meeting minutes',
    );
    if (text == null) return;
    await ref
        .read(meetingWorkspaceRepositoryProvider)
        .createMinutes(meetingId, text);
    ref.invalidate(meetingMinutesProvider(meetingId));
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    PrivateMeetingNoteModel note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete private note?'),
        content: const Text('This note cannot be recovered after deletion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(meetingWorkspaceRepositoryProvider).deleteNote(note.id);
    ref.invalidate(privateMeetingNotesProvider(meetingId));
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    MeetingMinutesModel item,
    String action,
  ) async {
    String? comment;
    if (action == 'reject') {
      comment = await _editText(
        context,
        title: 'Reject minutes',
        hint: 'Explain what must be corrected',
      );
      if (comment == null) return;
    }
    await ref
        .read(meetingWorkspaceRepositoryProvider)
        .transitionMinutes(item.id, action, comment: comment);
    ref.invalidate(meetingMinutesProvider(meetingId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(privateMeetingNotesProvider(meetingId));
      ref.invalidate(meetingMinutesProvider(meetingId));
    },
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.lock_outline_rounded,
                title: 'My private notes',
              ),
            ),
            FilledButton.icon(
              onPressed: () => _addNote(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Private notes are visible only to you.',
          style: TextStyle(color: Color(0xFF7D8CB2)),
        ),
        const SizedBox(height: 10),
        notes.when(
          loading: () => const AppLoading(),
          error: (error, _) => Text('Could not load private notes: $error'),
          data: (items) => items.isEmpty
              ? const AppEmptyState(message: 'No private notes yet')
              : Column(
                  children: items
                      .map(
                        (note) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.lock_outline_rounded),
                            title: Text(note.noteText),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _editNote(context, ref, note);
                                } else {
                                  await _deleteNote(context, ref, note);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.fact_check_outlined,
                title: 'Official minutes',
              ),
            ),
            if (canManageMinutes)
              OutlinedButton.icon(
                onPressed: () => _createMinutes(context, ref),
                icon: const Icon(Icons.post_add_rounded),
                label: const Text('New draft'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        minutes.when(
          loading: () => const AppLoading(),
          error: (error, _) => Text('Could not load meeting minutes: $error'),
          data: (items) => items.isEmpty
              ? const AppEmptyState(message: 'No minutes have been published')
              : Column(
                  children: items
                      .map(
                        (item) => _MinutesCard(
                          item: item,
                          canManage: canManageMinutes,
                          onAction: (action) =>
                              _transition(context, ref, item, action),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    ),
  );
}

class _MinutesCard extends StatelessWidget {
  final MeetingMinutesModel item;
  final bool canManage;
  final ValueChanged<String> onAction;
  const _MinutesCard({
    required this.item,
    required this.canManage,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      leading: CircleAvatar(child: Text('v${item.versionNumber}')),
      title: Text(
        'Minutes version ${item.versionNumber}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('${item.status.replaceAll('_', ' ')} - ${item.createdBy}'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(item.content),
        ),
        if ((item.reviewComment ?? '').trim().isNotEmpty) ...[
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Review: ${item.reviewComment}'),
          ),
        ],
        if (canManage) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.status == 'DRAFT')
                FilledButton(
                  onPressed: () => onAction('submit'),
                  child: const Text('Submit for review'),
                ),
              if (item.status == 'IN_REVIEW') ...[
                FilledButton(
                  onPressed: () => onAction('approve'),
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: () => onAction('reject'),
                  child: const Text('Reject'),
                ),
              ],
              if (item.status == 'APPROVED')
                FilledButton(
                  onPressed: () => onAction('publish'),
                  child: const Text('Publish'),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _WorkspaceError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _WorkspaceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 42),
        const SizedBox(height: 10),
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
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

class _PaperCard extends ConsumerWidget {
  final PaperModel paper;
  final VoidCallback onTap;
  const _PaperCard({required this.paper, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${paper.paperType} - Ref: ${paper.referenceNumber ?? '-'}'),
          _PaperReadStatus(paperId: paper.id),
        ],
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
