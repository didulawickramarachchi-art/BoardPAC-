import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/services/app_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../approvals/model/approval_request.dart';
import '../../approvals/provider/approval_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../papers/presentation/paper_detail_screen.dart';
import '../../papers/provider/paper_provider.dart';
import '../model/pending_approval_report_model.dart';
import '../provider/report_provider.dart';
import 'widgets/report_components.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  static const primaryBlue = AppColors.navy;

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  final _search = TextEditingController();
  String? _meeting;
  String? _reviewer;
  String? _paper;
  String _sortBy = 'date';
  bool _ascending = false;
  int _page = 0;
  int _pageSize = 10;

  bool get _hasFilters =>
      _search.text.trim().isNotEmpty ||
      _meeting != null ||
      _reviewer != null ||
      _paper != null;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PendingApprovalReportModel> _filtered(
    List<PendingApprovalReportModel> items,
  ) {
    final query = _search.text.trim().toLowerCase();
    final filtered = items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.paperTitle.toLowerCase().contains(query) ||
          item.meetingTitle.toLowerCase().contains(query) ||
          item.username.toLowerCase().contains(query);
      return matchesQuery &&
          (_meeting == null || item.meetingTitle == _meeting) &&
          (_reviewer == null || item.username == _reviewer) &&
          (_paper == null || item.paperTitle == _paper);
    }).toList();
    int compare(PendingApprovalReportModel a, PendingApprovalReportModel b) {
      return switch (_sortBy) {
        'meeting' => a.meetingTitle.toLowerCase().compareTo(
          b.meetingTitle.toLowerCase(),
        ),
        'reviewer' => a.username.toLowerCase().compareTo(
          b.username.toLowerCase(),
        ),
        _ =>
          (a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
      };
    }

    filtered.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
    return filtered;
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _meeting = null;
      _reviewer = null;
      _paper = null;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(pendingApprovalReportProvider);
    final auth = ref.watch(authProvider);
    final access = RoleAccess(auth.role ?? 'MEMBER', auth.accessProfile);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: PendingApprovalScreen.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pending Approvals',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: () => ref.invalidate(pendingApprovalReportProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: report.when(
        loading: () => const ReportLoadingSkeleton(),
        error: (error, _) => ReportErrorState(
          message: ApiErrorMessage.from(
            error,
            fallback: 'Could not load pending approvals.',
          ),
          onRetry: () => ref.invalidate(pendingApprovalReportProvider),
        ),
        data: (items) {
          final filtered = _filtered(items);
          final calculatedPages = (filtered.length / _pageSize).ceil();
          final pageCount = calculatedPages < 1 ? 1 : calculatedPages;
          final currentPage = _page.clamp(0, pageCount - 1);
          final start = currentPage * _pageSize;
          final pageItems = filtered.skip(start).take(_pageSize).toList();
          return RefreshIndicator(
            color: PendingApprovalScreen.primaryBlue,
            onRefresh: () => ref.refresh(pendingApprovalReportProvider.future),
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 90),
                      ReportEmptyState(
                        title: 'All caught up',
                        message:
                            'There are no papers waiting for approval right now.\nPull down to check again.',
                        icon: Icons.task_alt_rounded,
                      ),
                    ],
                  )
                : _ApprovalList(
                    items: pageItems,
                    allItems: items,
                    totalResults: filtered.length,
                    page: currentPage,
                    pageCount: pageCount,
                    pageSize: _pageSize,
                    searchController: _search,
                    selectedMeeting: _meeting,
                    selectedReviewer: _reviewer,
                    selectedPaper: _paper,
                    sortBy: _sortBy,
                    ascending: _ascending,
                    hasFilters: _hasFilters,
                    onSearchChanged: (_) => setState(() => _page = 0),
                    onMeetingChanged: (value) => setState(() {
                      _meeting = value;
                      _page = 0;
                    }),
                    onReviewerChanged: (value) => setState(() {
                      _reviewer = value;
                      _page = 0;
                    }),
                    onPaperChanged: (value) => setState(() {
                      _paper = value;
                      _page = 0;
                    }),
                    onSortChanged: (value) => setState(() {
                      _sortBy = value;
                      _page = 0;
                    }),
                    onDirectionChanged: () =>
                        setState(() => _ascending = !_ascending),
                    onClearFilters: _clearFilters,
                    onOpen: (item) => _openPaper(context, ref, item.paperId),
                    canDecide: (item) =>
                        access.canApprovePapers && item.userId == auth.userId,
                    onDecision: (item, status) =>
                        _recordDecision(context, ref, item, status),
                    onPageChanged: (value) => setState(() => _page = value),
                    onPageSizeChanged: (value) => setState(() {
                      _pageSize = value;
                      _page = 0;
                    }),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _openPaper(
    BuildContext context,
    WidgetRef ref,
    int paperId,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    try {
      final paper = await ref.read(paperRepositoryProvider).getPaper(paperId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaperDetailScreen(paper: paper)),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      AppNotificationService.error(
        context,
        ApiErrorMessage.from(error, fallback: 'Could not open this paper.'),
      );
    }
  }

  Future<void> _recordDecision(
    BuildContext context,
    WidgetRef ref,
    PendingApprovalReportModel item,
    String status,
  ) async {
    final comment = TextEditingController();
    final approve = status == 'APPROVE';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          approve ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: approve ? AppColors.success : AppColors.danger,
        ),
        title: Text(approve ? 'Approve this paper?' : 'Reject this paper?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.paperTitle),
            const SizedBox(height: 14),
            TextField(
              controller: comment,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: approve
                    ? 'Comment (optional)'
                    : 'Reason for rejection',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    final note = comment.text.trim();
    comment.dispose();
    if (confirmed != true) return;
    if (!approve && note.isEmpty) {
      if (!context.mounted) return;
      AppNotificationService.error(
        context,
        'Please provide a rejection reason.',
      );
      return;
    }
    try {
      await ref
          .read(approvalRepositoryProvider)
          .submitApproval(
            ApprovalRequest(
              paperId: item.paperId,
              approvalStatus: status,
              approvalComment: note,
            ),
          );
      ref.invalidate(pendingApprovalReportProvider);
      ref.invalidate(approvalListProvider(item.paperId));
      if (!context.mounted) return;
      AppNotificationService.success(
        context,
        approve ? 'Paper approved.' : 'Paper rejected.',
      );
    } catch (error) {
      if (!context.mounted) return;
      AppNotificationService.error(context, ApiErrorMessage.from(error));
    }
  }
}

class _ApprovalList extends StatelessWidget {
  final List<PendingApprovalReportModel> items;
  final List<PendingApprovalReportModel> allItems;
  final int totalResults;
  final int page;
  final int pageCount;
  final int pageSize;
  final TextEditingController searchController;
  final String? selectedMeeting;
  final String? selectedReviewer;
  final String? selectedPaper;
  final String sortBy;
  final bool ascending;
  final bool hasFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onMeetingChanged;
  final ValueChanged<String?> onReviewerChanged;
  final ValueChanged<String?> onPaperChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onDirectionChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<PendingApprovalReportModel> onOpen;
  final bool Function(PendingApprovalReportModel) canDecide;
  final void Function(PendingApprovalReportModel, String) onDecision;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  const _ApprovalList({
    required this.items,
    required this.allItems,
    required this.totalResults,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.searchController,
    required this.selectedMeeting,
    required this.selectedReviewer,
    required this.selectedPaper,
    required this.sortBy,
    required this.ascending,
    required this.hasFilters,
    required this.onSearchChanged,
    required this.onMeetingChanged,
    required this.onReviewerChanged,
    required this.onPaperChanged,
    required this.onSortChanged,
    required this.onDirectionChanged,
    required this.onClearFilters,
    required this.onOpen,
    required this.canDecide,
    required this.onDecision,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meetings = items.map((item) => item.meetingTitle).toSet().length;
    final reviewers = items.map((item) => item.userId).toSet().length;
    final meetingOptions =
        allItems
            .map((item) => item.meetingTitle)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final reviewerOptions =
        allItems
            .map((item) => item.username)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final paperOptions =
        allItems
            .map((item) => item.paperTitle)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth > 700 ? 32 : 16,
          18,
          constraints.maxWidth > 700 ? 32 : 16,
          32,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportHeaderCard(
                    title: 'Approval queue',
                    subtitle: 'Papers currently waiting for review',
                    icon: Icons.pending_actions_rounded,
                    metrics: [
                      ReportMetric('$totalResults', 'Approvals'),
                      ReportMetric('$meetings', 'Meetings'),
                      ReportMetric('$reviewers', 'Reviewers'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FilterPanel(
                    searchController: searchController,
                    meetingOptions: meetingOptions,
                    reviewerOptions: reviewerOptions,
                    paperOptions: paperOptions,
                    selectedMeeting: selectedMeeting,
                    selectedReviewer: selectedReviewer,
                    selectedPaper: selectedPaper,
                    sortBy: sortBy,
                    ascending: ascending,
                    hasFilters: hasFilters,
                    onSearchChanged: onSearchChanged,
                    onMeetingChanged: onMeetingChanged,
                    onReviewerChanged: onReviewerChanged,
                    onPaperChanged: onPaperChanged,
                    onSortChanged: onSortChanged,
                    onDirectionChanged: onDirectionChanged,
                    onClear: onClearFilters,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Awaiting action',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '$totalResults ${totalResults == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _NoResults(onClear: onClearFilters)
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ApprovalCard(
                          item: item,
                          onTap: () => onOpen(item),
                          canDecide: canDecide(item),
                          onDecision: (status) => onDecision(item, status),
                        ),
                      ),
                    ),
                  if (totalResults > 0) ...[
                    const SizedBox(height: 6),
                    _PaginationBar(
                      page: page,
                      pageCount: pageCount,
                      pageSize: pageSize,
                      onPageChanged: onPageChanged,
                      onPageSizeChanged: onPageSizeChanged,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int pageCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationBar({
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DropdownButton<int>(
        value: pageSize,
        items: const [10, 20, 50]
            .map(
              (size) =>
                  DropdownMenuItem(value: size, child: Text('$size rows')),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onPageSizeChanged(value);
        },
      ),
      const Spacer(),
      Text(
        'Page ${page + 1} of $pageCount',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      IconButton(
        tooltip: 'Previous page',
        onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      IconButton(
        tooltip: 'Next page',
        onPressed: page + 1 < pageCount ? () => onPageChanged(page + 1) : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> meetingOptions;
  final List<String> reviewerOptions;
  final List<String> paperOptions;
  final String? selectedMeeting;
  final String? selectedReviewer;
  final String? selectedPaper;
  final String sortBy;
  final bool ascending;
  final bool hasFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onMeetingChanged;
  final ValueChanged<String?> onReviewerChanged;
  final ValueChanged<String?> onPaperChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onDirectionChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.searchController,
    required this.meetingOptions,
    required this.reviewerOptions,
    required this.paperOptions,
    required this.selectedMeeting,
    required this.selectedReviewer,
    required this.selectedPaper,
    required this.sortBy,
    required this.ascending,
    required this.hasFilters,
    required this.onSearchChanged,
    required this.onMeetingChanged,
    required this.onReviewerChanged,
    required this.onPaperChanged,
    required this.onSortChanged,
    required this.onDirectionChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search paper, meeting, or reviewer',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 680
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _FilterDropdown(
                    label: 'Meeting',
                    icon: Icons.event_note_outlined,
                    value: selectedMeeting,
                    options: meetingOptions,
                    onChanged: onMeetingChanged,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _FilterDropdown(
                    label: 'Reviewer',
                    icon: Icons.person_outline_rounded,
                    value: selectedReviewer,
                    options: reviewerOptions,
                    onChanged: onReviewerChanged,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _FilterDropdown(
                    label: 'Paper',
                    icon: Icons.description_outlined,
                    value: selectedPaper,
                    options: paperOptions,
                    onChanged: onPaperChanged,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: sortBy,
                decoration: InputDecoration(
                  labelText: 'Sort by',
                  prefixIcon: const Icon(Icons.sort_rounded, size: 19),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'date',
                    child: Text('Submission date'),
                  ),
                  DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                  DropdownMenuItem(value: 'reviewer', child: Text('Reviewer')),
                ],
                onChanged: (value) {
                  if (value != null) onSortChanged(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: ascending ? 'Ascending order' : 'Descending order',
              child: IconButton.filledTonal(
                onPressed: onDirectionChanged,
                icon: Icon(
                  ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                ),
              ),
            ),
          ],
        ),
        if (hasFilters) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Clear all filters'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    icon: const Icon(Icons.keyboard_arrow_down_rounded),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
    ),
    items: [
      DropdownMenuItem<String?>(value: null, child: Text('All $label')),
      ...options.map(
        (option) => DropdownMenuItem<String?>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: onChanged,
  );
}

class _NoResults extends StatelessWidget {
  final VoidCallback onClear;
  const _NoResults({required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.search_off_rounded,
          size: 42,
          color: Color(0xFF8A97B3),
        ),
        const SizedBox(height: 12),
        Text(
          'No matching approvals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Try changing your search or filters.',
          style: TextStyle(color: Color(0xFF7D8CB2)),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onClear, child: const Text('Reset filters')),
      ],
    ),
  );
}

class _ApprovalCard extends StatelessWidget {
  final PendingApprovalReportModel item;
  final VoidCallback onTap;
  final bool canDecide;
  final ValueChanged<String> onDecision;
  const _ApprovalCard({
    required this.item,
    required this.onTap,
    required this.canDecide,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.paperTitle}, pending approval by ${item.username}',
    child: ReportCardShell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFC17A0A),
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.paperTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          children: [
                            _PendingBadge(),
                            SizedBox(height: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: Color(0xFF9AA6BE),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _InfoRow(
                      icon: Icons.event_note_outlined,
                      text: item.meetingTitle,
                    ),
                    const SizedBox(height: 7),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      text: item.username,
                    ),
                    if (item.submittedAt != null) ...[
                      const SizedBox(height: 7),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        text:
                            '${_formatDate(item.submittedAt!)} · ${_approvalAge(item.approvalAgeDays)}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (canDecide) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onDecision('REJECT'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: Color(0xFFF0BABA)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onDecision('APPROVE'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $hour:$minute $period';
  }

  String _approvalAge(int days) {
    if (days <= 0) return 'Pending today';
    if (days == 1) return 'Pending for 1 day';
    return 'Pending for $days days';
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3D8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'PENDING',
      style: TextStyle(
        color: Color(0xFFAA6800),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF8190AE)),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text.isEmpty ? 'Not specified' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF69758C),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
