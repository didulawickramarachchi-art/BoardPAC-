import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../papers/provider/paper_provider.dart';
import '../model/annotation_request.dart';
import '../provider/annotation_provider.dart';

class PdfAnnotationScreen extends ConsumerStatefulWidget {
  final int paperId;
  final int userId;
  final String documentKey;
  final String documentTitle;
  final String filePath;

  const PdfAnnotationScreen({
    super.key,
    required this.paperId,
    required this.userId,
    required this.documentKey,
    required this.documentTitle,
    required this.filePath,
  });

  @override
  ConsumerState<PdfAnnotationScreen> createState() =>
      _PdfAnnotationScreenState();
}

class _PdfAnnotationScreenState extends ConsumerState<PdfAnnotationScreen> {
  final PdfViewerController _controller = PdfViewerController();
  late Future<String> _documentUrl;
  PdfAnnotationMode _mode = PdfAnnotationMode.none;
  Color _highlightColor = Colors.yellow;
  bool _saving = false;
  bool _changed = false;

  static const _colors = <Color>[
    Colors.yellow,
    Color(0xFF80DEEA),
    Color(0xFFA5D6A7),
    Color(0xFFF48FB1),
    Color(0xFFFFAB91),
    Color(0xFFCE93D8),
  ];

  @override
  void initState() {
    super.initState();
    _documentUrl = _findLatestDocument();
    _applyHighlightColor();
  }

  Future<String> _findLatestDocument() async {
    try {
      final records = await ref
          .read(annotationRepositoryProvider)
          .getByPaperAndUser(widget.paperId, widget.userId);
      String? latestPath;
      DateTime? latestSavedAt;
      for (final record in records) {
        try {
          final data = jsonDecode(record.annotationDataJson);
          if (data is Map &&
              data['kind'] == 'pdf_snapshot' &&
              data['documentKey'] == widget.documentKey) {
            final path = data['annotatedFilePath']?.toString().trim();
            final savedAt = DateTime.tryParse(
              data['savedAt']?.toString() ?? '',
            );
            if (path != null &&
                path.isNotEmpty &&
                (latestSavedAt == null ||
                    (savedAt != null && savedAt.isAfter(latestSavedAt)))) {
              latestPath = path;
              latestSavedAt = savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            }
          }
        } catch (_) {
          // Older free-form annotation records are intentionally ignored.
        }
      }
      if (latestPath != null) return latestPath;
    } catch (_) {
      // The original PDF can still be edited if annotation history is offline.
    }
    return widget.filePath;
  }

  void _applyHighlightColor() {
    _controller.annotationSettings.highlight.color = _highlightColor;
  }

  void _setMode(PdfAnnotationMode mode) {
    setState(() {
      _mode = _mode == mode ? PdfAnnotationMode.none : mode;
      _controller.annotationMode = _mode;
    });
  }

  Future<void> _onAnnotationAdded(Annotation annotation) async {
    _changed = true;
    if (annotation is StickyNoteAnnotation) return;

    // Syncfusion fires this callback while its selection overlay is still being
    // rebuilt. Opening a route in the same frame can leave an inherited overlay
    // dependency attached and trigger Flutter's `_dependents.isEmpty` assertion.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _controller.annotationMode = PdfAnnotationMode.none;
    setState(() => _mode = PdfAnnotationMode.none);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final text = await _askForMessage();
    if (!mounted) return;
    if (text != null && text.isNotEmpty) {
      annotation.subject = text;
      annotation.author = 'User ${widget.userId}';
    }
  }

  Future<String?> _askForMessage() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _AnnotationMessageDialog(),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final bytes = Uint8List.fromList(await _controller.saveDocument());
      final safeName = widget.documentTitle
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final fileName =
          '${safeName.isEmpty ? 'document' : safeName}_annotated_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final uploadedPath = await ref
          .read(paperRepositoryProvider)
          .uploadAttachment(fileName: fileName, fileBytes: bytes);

      await ref
          .read(
            annotationListProvider((
              paperId: widget.paperId,
              userId: widget.userId,
            )).notifier,
          )
          .create(
            AnnotationRequest(
              paperId: widget.paperId,
              userId: widget.userId,
              annotationType: 'HIGHLIGHT',
              pageNumber: _controller.pageNumber,
              annotationDataJson: jsonEncode({
                'kind': 'pdf_snapshot',
                'documentKey': widget.documentKey,
                'sourceFilePath': widget.filePath,
                'annotatedFilePath': uploadedPath,
                'fileName': fileName,
                'savedAt': DateTime.now().toUtc().toIso8601String(),
              }),
            ),
          );

      _changed = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annotated PDF saved successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save annotations: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _canLeave() async {
    if (!_changed || _saving) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard unsaved annotations?'),
            content: const Text(
              'Your latest highlights and notes have not been saved yet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldLeave = await _canLeave();
          if (shouldLeave && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.documentTitle),
          actions: [
            IconButton(
              tooltip: 'Save annotated PDF',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            _AnnotationToolbar(
              mode: _mode,
              selectedColor: _highlightColor,
              colors: _colors,
              onHighlight: () => _setMode(PdfAnnotationMode.highlight),
              onNote: () => _setMode(PdfAnnotationMode.stickyNote),
              onColor: (color) {
                setState(() => _highlightColor = color);
                _applyHighlightColor();
                if (_mode != PdfAnnotationMode.highlight) {
                  _setMode(PdfAnnotationMode.highlight);
                }
              },
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: _documentUrl,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SfPdfViewer.network(
                    snapshot.data!,
                    controller: _controller,
                    canShowTextSelectionMenu: true,
                    onAnnotationAdded: _onAnnotationAdded,
                    onAnnotationEdited: (_) => _changed = true,
                    onAnnotationRemoved: (_) => _changed = true,
                    onDocumentLoadFailed: (details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(details.description)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnotationMessageDialog extends StatefulWidget {
  const _AnnotationMessageDialog();

  @override
  State<_AnnotationMessageDialog> createState() =>
      _AnnotationMessageDialogState();
}

class _AnnotationMessageDialogState extends State<_AnnotationMessageDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Message for highlighted text'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'Optional note about this section',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add message')),
      ],
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, _textController.text.trim());
  }
}

class _AnnotationToolbar extends StatelessWidget {
  final PdfAnnotationMode mode;
  final Color selectedColor;
  final List<Color> colors;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final ValueChanged<Color> onColor;

  const _AnnotationToolbar({
    required this.mode,
    required this.selectedColor,
    required this.colors,
    required this.onHighlight,
    required this.onNote,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            FilterChip(
              selected: mode == PdfAnnotationMode.highlight,
              avatar: const Icon(Icons.highlight_alt, size: 18),
              label: const Text('Highlight / text color'),
              onSelected: (_) => onHighlight(),
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: mode == PdfAnnotationMode.stickyNote,
              avatar: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('Section message'),
              onSelected: (_) => onNote(),
            ),
            const SizedBox(width: 12),
            ...colors.map(
              (color) => Padding(
                padding: const EdgeInsets.only(right: 7),
                child: InkWell(
                  onTap: () => onColor(color),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: color == selectedColor
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                        width: color == selectedColor ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
