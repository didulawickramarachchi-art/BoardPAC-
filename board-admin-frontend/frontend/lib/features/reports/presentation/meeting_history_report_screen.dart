import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../categories/provider/category_provider.dart';
import '../../subcategories/provider/subcategory_provider.dart';
import '../model/meeting_history_report_model.dart';
import '../provider/report_provider.dart';

class MeetingHistoryReportScreen extends ConsumerStatefulWidget {
  const MeetingHistoryReportScreen({super.key});

  @override
  ConsumerState<MeetingHistoryReportScreen> createState() =>
      _MeetingHistoryReportScreenState();
}

class _MeetingHistoryReportScreenState
    extends ConsumerState<MeetingHistoryReportScreen> {
  static const _blue = Color(0xFF12275B);
  int? _categoryId;
  int? _subcategoryId;
  DateTime? _from;
  DateTime? _to;
  bool _loading = false;
  bool _exporting = false;
  List<MeetingHistoryReportModel>? _results;

  Future<void> _pickDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => start ? _from = value : _to = value);
  }

  Future<void> _generate() async {
    if (_from != null && _to != null && _from!.isAfter(_to!)) {
      _message('The start date must be before the end date.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(reportRepositoryProvider)
          .getMeetingHistory(
            categoryId: _categoryId,
            subcategoryId: _subcategoryId,
            from: _from,
            to: _to,
          );
      if (mounted) setState(() => _results = data);
    } catch (error) {
      _message(
        ApiErrorMessage.from(error, fallback: 'Could not generate report.'),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(reportRepositoryProvider)
          .downloadMeetingHistoryPdf(
            categoryId: _categoryId,
            subcategoryId: _subcategoryId,
            from: _from,
            to: _to,
          );
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save meeting history report',
        fileName: 'meeting-history-report.pdf',
        bytes: Uint8List.fromList(bytes),
      );
      _message(
        savedPath == null
            ? 'PDF save cancelled.'
            : 'Meeting history PDF generated successfully.',
      );
    } catch (error) {
      _message(
        ApiErrorMessage.from(error, fallback: 'Could not generate PDF.'),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  String _date(DateTime? value) => value == null
      ? 'Any date'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider).valueOrNull ?? const [];
    final allSubcategories =
        ref.watch(subcategoryListProvider).valueOrNull ?? const [];
    final subcategories = allSubcategories
        .where((item) => _categoryId == null || item.categoryId == _categoryId)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Meeting History Report',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...categories.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _categoryId = value;
                      _subcategoryId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: _subcategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All subcategories'),
                      ),
                      ...subcategories.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _subcategoryId = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: 'From',
                          value: _date(_from),
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateButton(
                          label: 'To',
                          value: _date(_to),
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _generate,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.analytics_outlined),
                          label: const Text('View Report'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exporting ? null : _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(_exporting ? 'Generating...' : 'PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_results != null) ...[
            Text(
              '${_results!.length} historical meetings',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (_results!.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No meetings match these filters.'),
                  ),
                ),
              )
            else
              ..._results!.map(
                (meeting) => _MeetingReportCard(meeting: meeting),
              ),
          ],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    ),
  );
}

class _MeetingReportCard extends StatelessWidget {
  final MeetingHistoryReportModel meeting;
  const _MeetingReportCard({required this.meeting});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      title: Text(
        meeting.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${meeting.meetingDateTime.replaceFirst('T', ' ')} • ${meeting.categoryName} / ${meeting.subcategoryName}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Status: ${meeting.status}\nLocation: ${meeting.location ?? '-'}\nBoard papers: ${meeting.papers.length}',
          ),
        ),
        if (meeting.papers.isNotEmpty) ...[
          const Divider(),
          ...meeting.papers.map(
            (paper) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(paper.title),
              subtitle: Text(
                '${paper.paperType} • Ref: ${paper.referenceNumber ?? '-'} • Version ${paper.versionNumber ?? 1}',
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
