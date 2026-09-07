import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../core/widgets/app_glass_surface.dart';
import '../../approvals/provider/approval_provider.dart';
import '../../papers/provider/paper_provider.dart';
import '../../papers/data/offline_file_store.dart';
import '../model/annotation_request.dart';
import '../provider/annotation_provider.dart';

class PdfAnnotationScreen extends ConsumerStatefulWidget {
  final int paperId;
  final int userId;
  final String documentKey;
  final String documentTitle;
  final String filePath;
  final bool editable;

  const PdfAnnotationScreen({
    super.key,
    required this.paperId,
    required this.userId,
    required this.documentKey,
    required this.documentTitle,
    required this.filePath,
    this.editable = true,
  });

  @override
  ConsumerState<PdfAnnotationScreen> createState() =>
      _PdfAnnotationScreenState();
}

class _PdfAnnotationScreenState extends ConsumerState<PdfAnnotationScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final UndoHistoryController _undoController = UndoHistoryController();
  final TextEditingController _pageController = TextEditingController(
    text: '1',
  );
  late Future<String> _documentUrl;
  late Future<Uint8List?> _localDocumentBytes;
  PdfAnnotationMode _mode = PdfAnnotationMode.none;
  Color _highlightColor = Colors.yellow;
  bool _saving = false;
  bool _savingVoice = false;
  bool _changed = false;
  int _resumePage = 1;
  int _totalPages = 1;
  Timer? _readStateDebounce;
  PdfTextSearchResult? _searchResult;
  int _currentPage = 1;
  double _zoomLevel = 1;
  bool _fullScreen = false;
  bool _documentLoaded = false;
  bool _penMode = false;
  final Map<int, List<_InkStroke>> _inkStrokes = {};
  _InkStroke? _activeStroke;
  Set<int> _bookmarkedPages = <int>{};

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
    _localDocumentBytes = _documentUrl.then(OfflineFileStore().read);
    _applyHighlightColor();
    _loadReadState();
    _loadBookmarks();
  }

  String get _bookmarkKey =>
      'paper_bookmarks_${widget.userId}_${widget.paperId}';

  Future<void> _loadBookmarks() async {
    final stored = await SecureStorageService().read(_bookmarkKey);
    final pages = (stored ?? '')
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .where((page) => page > 0)
        .toSet();
    if (mounted) setState(() => _bookmarkedPages = pages);
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      if (!_bookmarkedPages.add(_currentPage)) {
        _bookmarkedPages.remove(_currentPage);
      }
    });
    await SecureStorageService().write(
      _bookmarkKey,
      (_bookmarkedPages.toList()..sort()).join(','),
    );
  }

  void _jumpToPage(String value) {
    final page = int.tryParse(value)?.clamp(1, _totalPages);
    if (page == null) return;
    _controller.jumpToPage(page);
  }

  void _changeZoom(double change) {
    final zoom = (_controller.zoomLevel + change).clamp(1.0, 5.0);
    _controller.zoomLevel = zoom;
    setState(() => _zoomLevel = zoom);
  }

  Future<void> _startSearch() async {
    final query = await showDialog<String>(
      context: context,
      builder: (_) => const _DocumentSearchDialog(),
    );
    if (query == null || query.isEmpty || !mounted) return;
    if (!_documentLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the document to load.')),
      );
      return;
    }
    try {
      _searchResult?.removeListener(_onSearchChanged);
      _searchResult?.clear();
      _searchResult = _controller.searchText(query)
        ..addListener(_onSearchChanged);
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not search this document.')),
        );
      }
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _showBookmarks() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final pages = _bookmarkedPages.toList()..sort();
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: pages.isEmpty
                ? const Center(child: Text('No bookmarked pages'))
                : ListView.builder(
                    itemCount: pages.length,
                    itemBuilder: (_, index) => ListTile(
                      leading: const Icon(Icons.bookmark_rounded),
                      title: Text('Page ${pages[index]}'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _controller.jumpToPage(pages[index]);
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _showAnnotations() async {
    final annotations = _controller.getAnnotations()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    final voiceNotes = <_SavedVoiceNote>[];
    try {
      final records = await ref
          .read(annotationRepositoryProvider)
          .getByPaperAndUser(widget.paperId, widget.userId);
      for (final record in records) {
        if (record.annotationType != 'AUDIO') continue;
        try {
          final data = jsonDecode(record.annotationDataJson);
          if (data is! Map || data['kind'] != 'voice_note') continue;
          final audioUrl = data['audioUrl']?.toString().trim() ?? '';
          if (audioUrl.isEmpty) continue;
          voiceNotes.add(
            _SavedVoiceNote(
              audioUrl: audioUrl,
              fileName: data['fileName']?.toString() ?? 'Voice note',
              pageNumber: record.pageNumber ?? 1,
            ),
          );
        } catch (_) {
          // Ignore malformed legacy annotation data.
        }
      }
    } catch (_) {
      // Local PDF annotations remain available while offline.
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 380,
          child: annotations.isEmpty && voiceNotes.isEmpty
              ? const Center(child: Text('No annotations in this document'))
              : ListView.builder(
                  itemCount: voiceNotes.length + annotations.length,
                  itemBuilder: (_, index) {
                    if (index < voiceNotes.length) {
                      final voiceNote = voiceNotes[index];
                      return ListTile(
                        leading: const Icon(Icons.graphic_eq_rounded),
                        title: Text(voiceNote.fileName),
                        subtitle: Text(
                          'Voice note · Page ${voiceNote.pageNumber}',
                        ),
                        trailing: const Icon(Icons.play_circle_outline_rounded),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _controller.jumpToPage(voiceNote.pageNumber);
                          _showVoiceNotePlayer(
                            voiceNote.audioUrl,
                            voiceNote.fileName,
                          );
                        },
                      );
                    }
                    final annotation = annotations[index - voiceNotes.length];
                    return ListTile(
                      leading: const Icon(Icons.edit_note_rounded),
                      title: Text(
                        annotation.subject?.trim().isNotEmpty == true
                            ? annotation.subject!
                            : annotation.runtimeType.toString(),
                      ),
                      subtitle: Text('Page ${annotation.pageNumber}'),
                      trailing: IconButton(
                        tooltip: 'Remove annotation',
                        onPressed: () {
                          _controller.removeAnnotation(annotation);
                          Navigator.pop(sheetContext);
                          _showAnnotations();
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _controller.jumpToPage(annotation.pageNumber);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _loadReadState() async {
    try {
      final state = await ref.read(
        paperReadStateProvider(widget.paperId).future,
      );
      _resumePage = state.lastPage;
    } catch (_) {
      _resumePage = 1;
    }
  }

  void _trackPage(int page) {
    _readStateDebounce?.cancel();
    _readStateDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await ref
            .read(paperRepositoryProvider)
            .updateReadState(
              paperId: widget.paperId,
              lastPage: page,
              totalPages: _totalPages,
            );
        ref.invalidate(paperReadStateProvider(widget.paperId));
      } catch (_) {
        // Reading must remain available if progress synchronization is offline.
      }
    });
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
      _penMode = false;
      _mode = _mode == mode ? PdfAnnotationMode.none : mode;
      _controller.annotationMode = _mode;
    });
  }

  void _setPenMode() {
    _controller.annotationMode = PdfAnnotationMode.none;
    setState(() {
      _mode = PdfAnnotationMode.none;
      _penMode = true;
    });
  }

  void _startInk(PointerDownEvent event, Size size) {
    final point = Offset(
      event.localPosition.dx / size.width,
      event.localPosition.dy / size.height,
    );
    setState(() {
      _activeStroke = _InkStroke(color: _highlightColor, points: [point]);
      (_inkStrokes[_currentPage] ??= []).add(_activeStroke!);
    });
  }

  void _updateInk(PointerMoveEvent event, Size size) {
    final stroke = _activeStroke;
    if (stroke == null) return;
    setState(
      () => stroke.points.add(
        Offset(
          (event.localPosition.dx / size.width).clamp(0, 1),
          (event.localPosition.dy / size.height).clamp(0, 1),
        ),
      ),
    );
  }

  void _finishInk(PointerEvent _) {
    if (_activeStroke != null) _changed = true;
    _activeStroke = null;
  }

  Uint8List _flattenInk(Uint8List bytes) {
    if (_inkStrokes.isEmpty) return bytes;
    final document = PdfDocument(inputBytes: bytes);
    for (final entry in _inkStrokes.entries) {
      if (entry.key < 1 || entry.key > document.pages.count) continue;
      final page = document.pages[entry.key - 1];
      final size = page.getClientSize();
      for (final stroke in entry.value) {
        if (stroke.points.length < 2) continue;
        final color = stroke.color;
        final pen = PdfPen(
          PdfColor(
            (color.r * 255).round(),
            (color.g * 255).round(),
            (color.b * 255).round(),
          ),
          width: 2.2,
        );
        for (var index = 1; index < stroke.points.length; index++) {
          final from = stroke.points[index - 1];
          final to = stroke.points[index];
          page.graphics.drawLine(
            pen,
            Offset(from.dx * size.width, from.dy * size.height),
            Offset(to.dx * size.width, to.dy * size.height),
          );
        }
      }
    }
    final result = Uint8List.fromList(document.saveSync());
    document.dispose();
    return result;
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

  void _showAnnotationMessage(Annotation annotation) {
    final message = annotation.subject?.trim() ?? '';
    if (message.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Message on this highlight',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SelectableText(message),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showVoiceNotePlayer(String audioUrl, String fileName) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VoiceNotePlayer(audioUrl: audioUrl, title: fileName),
    );
  }

  Future<void> _addVoiceNote() async {
    if (_savingVoice) return;
    final result = await showModalBottomSheet<_VoiceNoteResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _VoiceNoteRecorder(),
    );
    if (result == null || !mounted) return;

    setState(() => _savingVoice = true);
    final paperRepository = ref.read(paperRepositoryProvider);
    final annotationNotifier = ref.read(
      annotationListProvider((
        paperId: widget.paperId,
        userId: widget.userId,
      )).notifier,
    );
    try {
      final now = DateTime.now();
      final fileName = 'voice_note_${now.millisecondsSinceEpoch}.wav';
      final audioUrl = await paperRepository.uploadAttachment(
        fileName: fileName,
        paperId: widget.paperId,
        fileBytes: result.bytes,
      );
      await annotationNotifier.create(
        AnnotationRequest(
          paperId: widget.paperId,
          userId: widget.userId,
          annotationType: 'AUDIO',
          pageNumber: _controller.pageNumber,
          annotationDataJson: jsonEncode({
            'kind': 'voice_note',
            'documentKey': widget.documentKey,
            'audioUrl': audioUrl,
            'fileName': fileName,
            'durationSeconds': result.duration.inSeconds,
            'pageNumber': _controller.pageNumber,
            'createdAt': now.toUtc().toIso8601String(),
          }),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voice note added to this page.'),
            action: SnackBarAction(
              label: 'Play',
              onPressed: () => _showVoiceNotePlayer(audioUrl, fileName),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add voice note: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingVoice = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final paperRepository = ref.read(paperRepositoryProvider);
    final annotationNotifier = ref.read(
      annotationListProvider((
        paperId: widget.paperId,
        userId: widget.userId,
      )).notifier,
    );

    try {
      final viewerBytes = Uint8List.fromList(await _controller.saveDocument());
      final bytes = _flattenInk(viewerBytes);
      final safeName = widget.documentTitle
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final fileName =
          '${safeName.isEmpty ? 'document' : safeName}_annotated_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final uploadedPath = await paperRepository.uploadAttachment(
        fileName: fileName,
        paperId: widget.paperId,
        fileBytes: bytes,
      );

      await annotationNotifier.create(
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
    _readStateDebounce?.cancel();
    _searchResult?.removeListener(_onSearchChanged);
    _searchResult?.clear();
    _pageController.dispose();
    _undoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _localPdfViewer(Uint8List bytes) => SfPdfViewer.memory(
    bytes,
    controller: _controller,
    undoController: _undoController,
    canShowTextSelectionMenu: true,
    onAnnotationAdded: _onAnnotationAdded,
    onAnnotationSelected: _showAnnotationMessage,
    onAnnotationEdited: (_) => _changed = true,
    onAnnotationRemoved: (_) => _changed = true,
    onDocumentLoaded: (details) {
      _documentLoaded = true;
      _totalPages = details.document.pages.count;
      final page = _resumePage.clamp(1, _totalPages);
      _currentPage = page;
      _pageController.text = '$page';
      if (page > 1) _controller.jumpToPage(page);
      _trackPage(page);
    },
    onPageChanged: (details) {
      setState(() {
        _currentPage = details.newPageNumber;
        _pageController.text = '${details.newPageNumber}';
      });
      _trackPage(details.newPageNumber);
    },
    onZoomLevelChanged: (details) =>
        setState(() => _zoomLevel = details.newZoomLevel),
    onDocumentLoadFailed: (details) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(details.description)));
    },
  );

  @override
  Widget build(BuildContext context) {
    final approvals = ref.watch(approvalListProvider(widget.paperId));
    final decisions = approvals.valueOrNull ?? const [];
    final approvedBy = decisions
        .where((item) => item.approvalStatus == 'APPROVE')
        .map((item) => item.username)
        .toList();
    final rejectedBy = decisions
        .where((item) => item.approvalStatus == 'REJECT')
        .map((item) => item.username)
        .toList();
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldLeave = await _canLeave();
          if (shouldLeave && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF0FA),
        appBar: _fullScreen
            ? null
            : AppBar(
                backgroundColor: const Color(0xEA12275B),
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(widget.documentTitle),
                actions: [
                  IconButton(
                    tooltip: 'Search document',
                    onPressed: _startSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: 'Bookmarked pages',
                    onPressed: _showBookmarks,
                    icon: const Icon(Icons.bookmarks_outlined),
                  ),
                  if (widget.editable)
                    IconButton(
                      tooltip: 'Annotation list',
                      onPressed: _showAnnotations,
                      icon: const Icon(Icons.edit_note_rounded),
                    ),
                  if (widget.editable)
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
        body: Container(
          decoration: AppGlassDecoration.background,
          child: Column(
            children: [
              if (widget.editable)
                _AnnotationToolbar(
                  mode: _mode,
                  penMode: _penMode,
                  selectedColor: _highlightColor,
                  colors: _colors,
                  onPan: () => _setMode(PdfAnnotationMode.none),
                  onPen: _setPenMode,
                  onHighlight: () => _setMode(PdfAnnotationMode.highlight),
                  onUnderline: () => _setMode(PdfAnnotationMode.underline),
                  onStrikeout: () => _setMode(PdfAnnotationMode.strikethrough),
                  onSquiggly: () => _setMode(PdfAnnotationMode.squiggly),
                  onNote: () => _setMode(PdfAnnotationMode.stickyNote),
                  onVoice: _addVoiceNote,
                  savingVoice: _savingVoice,
                  onColor: (color) {
                    setState(() => _highlightColor = color);
                    _applyHighlightColor();
                    if (_mode != PdfAnnotationMode.highlight) {
                      _setMode(PdfAnnotationMode.highlight);
                    }
                  },
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FutureBuilder<String>(
                        future: _documentUrl,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return FutureBuilder<Uint8List?>(
                            future: _localDocumentBytes,
                            builder: (context, local) {
                              if (local.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (local.data != null) {
                                return _localPdfViewer(local.data!);
                              }
                              return SfPdfViewer.network(
                                snapshot.data!,
                                controller: _controller,
                                undoController: _undoController,
                                canShowTextSelectionMenu: true,
                                onAnnotationAdded: _onAnnotationAdded,
                                onAnnotationSelected: _showAnnotationMessage,
                                onAnnotationEdited: (_) => _changed = true,
                                onAnnotationRemoved: (_) => _changed = true,
                                onDocumentLoaded: (details) {
                                  _documentLoaded = true;
                                  _totalPages = details.document.pages.count;
                                  final page = _resumePage.clamp(
                                    1,
                                    _totalPages,
                                  );
                                  _currentPage = page;
                                  _pageController.text = '$page';
                                  if (page > 1) _controller.jumpToPage(page);
                                  _trackPage(page);
                                },
                                onPageChanged: (details) {
                                  setState(() {
                                    _currentPage = details.newPageNumber;
                                    _pageController.text =
                                        '${details.newPageNumber}';
                                  });
                                  _trackPage(details.newPageNumber);
                                },
                                onZoomLevelChanged: (details) => setState(
                                  () => _zoomLevel = details.newZoomLevel,
                                ),
                                onDocumentLoadFailed: (details) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(details.description),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (_penMode)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) => Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) =>
                                _startInk(event, constraints.biggest),
                            onPointerMove: (event) =>
                                _updateInk(event, constraints.biggest),
                            onPointerUp: _finishInk,
                            onPointerCancel: _finishInk,
                            child: CustomPaint(
                              painter: _InkPainter(
                                _inkStrokes[_currentPage] ?? const [],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (approvedBy.isNotEmpty && _currentPage == 1)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IgnorePointer(
                          child: _ApprovedPaperSeal(
                            approvedBy: approvedBy,
                            rejectedBy: rejectedBy,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _ReaderControls(
                currentPage: _currentPage,
                totalPages: _totalPages,
                pageController: _pageController,
                zoomLevel: _zoomLevel,
                bookmarked: _bookmarkedPages.contains(_currentPage),
                fullScreen: _fullScreen,
                searchResult: _searchResult,
                editable: widget.editable,
                undoController: _undoController,
                onPreviousPage: _controller.previousPage,
                onNextPage: _controller.nextPage,
                onPageSubmitted: _jumpToPage,
                onSliderChanged: (value) =>
                    _controller.jumpToPage(value.round()),
                onZoomOut: () => _changeZoom(-0.25),
                onZoomIn: () => _changeZoom(0.25),
                onBookmark: _toggleBookmark,
                onFullScreen: () => setState(() => _fullScreen = !_fullScreen),
                onSearch: _startSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovedPaperSeal extends StatelessWidget {
  final List<String> approvedBy;
  final List<String> rejectedBy;

  const _ApprovedPaperSeal({
    required this.approvedBy,
    required this.rejectedBy,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8EE).withValues(alpha: .94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF218A43), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFF167137),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'APPROVED',
                    style: TextStyle(
                      color: Color(0xFF12602E),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    'Approved by: ${approvedBy.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF277442),
                      fontSize: 10,
                    ),
                  ),
                  if (rejectedBy.isNotEmpty)
                    Text(
                      'Rejected by: ${rejectedBy.join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9A3030),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final TextEditingController pageController;
  final double zoomLevel;
  final bool bookmarked;
  final bool fullScreen;
  final PdfTextSearchResult? searchResult;
  final bool editable;
  final UndoHistoryController undoController;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<String> onPageSubmitted;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onBookmark;
  final VoidCallback onFullScreen;
  final VoidCallback onSearch;

  const _ReaderControls({
    required this.currentPage,
    required this.totalPages,
    required this.pageController,
    required this.zoomLevel,
    required this.bookmarked,
    required this.fullScreen,
    required this.searchResult,
    required this.editable,
    required this.undoController,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageSubmitted,
    required this.onSliderChanged,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onBookmark,
    required this.onFullScreen,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: AppGlassDecoration.surface(
      borderRadius: BorderRadius.zero,
      tint: const Color(0xFF8EA7E0),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: currentPage.clamp(1, totalPages).toDouble(),
            min: 1,
            max: totalPages.toDouble().clamp(1, double.infinity),
            divisions: totalPages > 1 ? totalPages - 1 : null,
            label: 'Page $currentPage',
            onChanged: totalPages > 1 ? onSliderChanged : null,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: currentPage > 1 ? onPreviousPage : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                SizedBox(
                  width: 48,
                  child: TextField(
                    controller: pageController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    onSubmitted: onPageSubmitted,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Text(' / $totalPages'),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: currentPage < totalPages ? onNextPage : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: zoomLevel > 1 ? onZoomOut : null,
                  icon: const Icon(Icons.zoom_out_rounded),
                ),
                Text('${(zoomLevel * 100).round()}%'),
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: zoomLevel < 5 ? onZoomIn : null,
                  icon: const Icon(Icons.zoom_in_rounded),
                ),
                IconButton(
                  tooltip: bookmarked
                      ? 'Remove page bookmark'
                      : 'Bookmark this page',
                  onPressed: onBookmark,
                  icon: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
                if (searchResult != null) ...[
                  IconButton(
                    tooltip: 'Previous result',
                    onPressed: searchResult!.previousInstance,
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  Text(
                    '${searchResult!.currentInstanceIndex}/${searchResult!.totalInstanceCount}',
                  ),
                  IconButton(
                    tooltip: 'Next result',
                    onPressed: searchResult!.nextInstance,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
                if (editable)
                  ValueListenableBuilder<UndoHistoryValue>(
                    valueListenable: undoController,
                    builder: (_, value, _) => Row(
                      children: [
                        IconButton(
                          tooltip: 'Undo',
                          onPressed: value.canUndo ? undoController.undo : null,
                          icon: const Icon(Icons.undo_rounded),
                        ),
                        IconButton(
                          tooltip: 'Redo',
                          onPressed: value.canRedo ? undoController.redo : null,
                          icon: const Icon(Icons.redo_rounded),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  tooltip: fullScreen ? 'Exit full screen' : 'Full screen',
                  onPressed: onFullScreen,
                  icon: Icon(
                    fullScreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DocumentSearchDialog extends StatefulWidget {
  const _DocumentSearchDialog();

  @override
  State<_DocumentSearchDialog> createState() => _DocumentSearchDialogState();
}

class _DocumentSearchDialogState extends State<_DocumentSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) Navigator.pop(context, query);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Search document'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(hintText: 'Enter words to find'),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Search')),
    ],
  );
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

class _SavedVoiceNote {
  final String audioUrl;
  final String fileName;
  final int pageNumber;

  const _SavedVoiceNote({
    required this.audioUrl,
    required this.fileName,
    required this.pageNumber,
  });
}

class _VoiceNotePlayer extends StatefulWidget {
  final String audioUrl;
  final String title;

  const _VoiceNotePlayer({required this.audioUrl, required this.title});

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _play() async {
    try {
      setState(() => _error = null);
      await _player.play(UrlSource(widget.audioUrl));
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to play this voice note.');
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMilliseconds = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final positionMilliseconds = _position.inMilliseconds
        .clamp(0, maxMilliseconds.toInt())
        .toDouble();
    final isPlaying = _state == PlayerState.playing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, size: 42),
            const SizedBox(height: 8),
            Text('Voice note', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Slider(
              value: positionMilliseconds,
              max: maxMilliseconds,
              onChanged: _duration == Duration.zero
                  ? null
                  : (value) =>
                        _player.seek(Duration(milliseconds: value.round())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(_position)),
                IconButton.filled(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: isPlaying ? _player.pause : _play,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
                Text(_format(_duration)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoiceNoteResult {
  final Uint8List bytes;
  final Duration duration;

  const _VoiceNoteResult({required this.bytes, required this.duration});
}

class _VoiceNoteRecorder extends StatefulWidget {
  const _VoiceNoteRecorder();

  @override
  State<_VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<_VoiceNoteRecorder> {
  static const _sampleRate = 16000;
  static const _channels = 1;
  static const _bitsPerSample = 16;

  final AudioRecorder _recorder = AudioRecorder();
  final BytesBuilder _audio = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _recording = false;
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission was not granted.');
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _channels,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _audioSubscription = stream.listen(_audio.add);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _duration += const Duration(seconds: 1));
      });
      if (mounted) setState(() => _recording = true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (!_recording || _busy) return;
    setState(() => _busy = true);
    try {
      await _recorder.stop();
      await _audioSubscription?.cancel();
      _timer?.cancel();
      final pcm = _audio.takeBytes();
      if (pcm.isEmpty) throw StateError('No audio was recorded.');
      if (mounted) {
        Navigator.pop(
          context,
          _VoiceNoteResult(bytes: _asWaveFile(pcm), duration: _duration),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  Uint8List _asWaveFile(Uint8List pcm) {
    final output = BytesBuilder(copy: false);
    final header = ByteData(44);
    void textAt(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        header.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    final byteRate = _sampleRate * _channels * (_bitsPerSample ~/ 8);
    textAt(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    textAt(8, 'WAVE');
    textAt(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, _channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, _channels * (_bitsPerSample ~/ 8), Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    textAt(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    output.add(header.buffer.asUint8List());
    output.add(pcm);
    return output.takeBytes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_duration.inSeconds % 60).toString().padLeft(2, '0');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voice note', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Record a note for the current page. No text selection is needed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recording
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                _recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$minutes:$seconds',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : (_recording ? _finish : _start),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(
                  _recording ? 'Stop and add note' : 'Start recording',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnotationToolbar extends StatelessWidget {
  final PdfAnnotationMode mode;
  final bool penMode;
  final Color selectedColor;
  final List<Color> colors;
  final VoidCallback onPan;
  final VoidCallback onPen;
  final VoidCallback onHighlight;
  final VoidCallback onUnderline;
  final VoidCallback onStrikeout;
  final VoidCallback onSquiggly;
  final VoidCallback onNote;
  final VoidCallback onVoice;
  final bool savingVoice;
  final ValueChanged<Color> onColor;

  const _AnnotationToolbar({
    required this.mode,
    required this.penMode,
    required this.selectedColor,
    required this.colors,
    required this.onPan,
    required this.onPen,
    required this.onHighlight,
    required this.onUnderline,
    required this.onStrikeout,
    required this.onSquiggly,
    required this.onNote,
    required this.onVoice,
    required this.savingVoice,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeLabel = penMode
        ? 'Pen'
        : switch (mode) {
            PdfAnnotationMode.highlight => 'Highlight',
            PdfAnnotationMode.underline => 'Underline',
            PdfAnnotationMode.strikethrough => 'Strikeout',
            PdfAnnotationMode.squiggly => 'Squiggly',
            PdfAnnotationMode.stickyNote => 'Message',
            _ => 'Pan & read',
          };
    return Container(
      decoration: AppGlassDecoration.surface(
        borderRadius: BorderRadius.zero,
        tint: const Color(0xFF8EA7E0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF12275B).withValues(alpha: .06),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: mode == PdfAnnotationMode.none && !penMode
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$activeLabel mode',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  penMode
                      ? 'Write with Pencil or finger'
                      : mode == PdfAnnotationMode.none
                      ? 'Drag to navigate'
                      : 'Select text to apply',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                _AnnotationToolButton(
                  icon: Icons.pan_tool_alt_outlined,
                  label: 'Pan',
                  selected: mode == PdfAnnotationMode.none && !penMode,
                  onTap: onPan,
                ),
                _AnnotationToolButton(
                  icon: Icons.draw_rounded,
                  label: 'Pen',
                  selected: penMode,
                  onTap: onPen,
                ),
                _AnnotationToolButton(
                  icon: Icons.highlight_alt,
                  label: 'Highlight',
                  selected: mode == PdfAnnotationMode.highlight,
                  onTap: onHighlight,
                ),
                _AnnotationToolButton(
                  icon: Icons.format_underlined_rounded,
                  label: 'Underline',
                  selected: mode == PdfAnnotationMode.underline,
                  onTap: onUnderline,
                ),
                _AnnotationToolButton(
                  icon: Icons.format_strikethrough_rounded,
                  label: 'Strike',
                  selected: mode == PdfAnnotationMode.strikethrough,
                  onTap: onStrikeout,
                ),
                _AnnotationToolButton(
                  icon: Icons.gesture_rounded,
                  label: 'Squiggly',
                  selected: mode == PdfAnnotationMode.squiggly,
                  onTap: onSquiggly,
                ),
                _AnnotationToolButton(
                  icon: Icons.add_comment_outlined,
                  label: 'Message',
                  selected: mode == PdfAnnotationMode.stickyNote,
                  onTap: onNote,
                ),
                _AnnotationToolButton(
                  icon: Icons.mic_none_rounded,
                  label: savingVoice ? 'Saving' : 'Voice',
                  selected: false,
                  loading: savingVoice,
                  onTap: savingVoice ? null : onVoice,
                ),
                Tooltip(
                  message: 'Choose any color',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickColor(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('Color', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorWheelPicker(initialColor: selectedColor),
    );
    if (color != null) onColor(color);
  }
}

class _ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  const _ColorWheelPicker({required this.initialColor});

  @override
  State<_ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<_ColorWheelPicker> {
  late HSVColor _color;

  @override
  void initState() {
    super.initState();
    _color = HSVColor.fromColor(widget.initialColor);
  }

  void _select(Offset position, Size size) {
    final center = size.center(Offset.zero);
    final delta = position - center;
    final radius = size.shortestSide / 2;
    final saturation = (delta.distance / radius).clamp(0.0, 1.0);
    var hue = delta.direction * 180 / 3.141592653589793;
    if (hue < 0) hue += 360;
    setState(() => _color = _color.withHue(hue).withSaturation(saturation));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose highlight color'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 230,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (details) =>
                  _select(details.localPosition, constraints.biggest),
              onPanUpdate: (details) =>
                  _select(details.localPosition, constraints.biggest),
              child: CustomPaint(painter: _ColorWheelPainter(_color)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.brightness_6_outlined),
            Expanded(
              child: Slider(
                value: _color.value,
                onChanged: (value) =>
                    setState(() => _color = _color.withValue(value)),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _color.toColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _color.toColor()),
        child: const Text('Use color'),
      ),
    ],
  );
}

class _ColorWheelPainter extends CustomPainter {
  final HSVColor selected;
  const _ColorWheelPainter(this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Color(0xFFFF00FF),
            Colors.red,
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0x00FFFFFF)],
        ).createShader(rect),
    );

    final angle = selected.hue * 3.141592653589793 / 180;
    final marker =
        center + Offset.fromDirection(angle, radius * selected.saturation);
    canvas.drawCircle(marker, 10, Paint()..color = Colors.white);
    canvas.drawCircle(
      marker,
      8,
      Paint()
        ..color = selected.toColor()
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      marker,
      9,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.selected != selected;
}

class _InkStroke {
  final Color color;
  final List<Offset> points;
  _InkStroke({required this.color, required this.points});
}

class _InkPainter extends CustomPainter {
  final List<_InkStroke> strokes;
  const _InkPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(
        stroke.points.first.dx * size.width,
        stroke.points.first.dy * size.height,
      );
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

class _AnnotationToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;

  const _AnnotationToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 3),
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
