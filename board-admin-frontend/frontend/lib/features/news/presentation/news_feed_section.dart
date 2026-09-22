import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/widgets/app_glass_surface.dart';
import '../model/news_post.dart';
import '../provider/news_provider.dart';

/// Keeps the large news request out of the dashboard's critical first frame.
class DeferredNewsFeedSection extends StatefulWidget {
  final bool canCreate;
  const DeferredNewsFeedSection({super.key, required this.canCreate});

  @override
  State<DeferredNewsFeedSection> createState() =>
      _DeferredNewsFeedSectionState();
}

class _DeferredNewsFeedSectionState extends State<DeferredNewsFeedSection> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ready
      ? NewsFeedSection(canCreate: widget.canCreate)
      : const SizedBox.shrink();
}

class NewsFeedSection extends ConsumerWidget {
  final bool canCreate;
  const NewsFeedSection({super.key, required this.canCreate});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(newsFeedProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Board news',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Updates and conversations from your board',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (canCreate) ...[
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(36),
              onTap: () => _create(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xD91A2741)
                      : Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: .14)
                        : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: .36)
                          : const Color(0x16001B4D),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFDDE5F7),
                      child: Icon(
                        Icons.newspaper_rounded,
                        color: Color(0xFF12275B),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Text(
                      'Create News',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _NewsLoadError(message: ApiErrorMessage.from(e)),
          data: (items) => items.isEmpty
              ? const _Empty()
              : Column(
                  children: items
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _Post(
                            post: entry.value,
                            canManage: canCreate,
                            index: entry.key,
                            total: items.length,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<_NewsDraft>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _CreatePostScreen(),
      ),
    );
    if (result == null) return;
    try {
      final repository = ref.read(newsRepositoryProvider);
      final uploaded = await Future.wait(
        result.photos.map(
          (photo) => repository.uploadPhoto(photo.bytes, photo.name),
        ),
      );
      if (!context.mounted) return;
      await ref.read(newsFeedProvider.notifier).create(
        result.title,
        result.content,
        result.badgeLabel,
        [...result.existingUrls, ...uploaded],
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMessage.from(error))));
    }
  }
}

class _NewsDraft {
  final String title;
  final String content;
  final String badgeLabel;
  final List<_PendingPhoto> photos;
  final List<String> existingUrls;
  const _NewsDraft(
    this.title,
    this.content,
    this.badgeLabel,
    this.photos,
    this.existingUrls,
  );
}

class _PendingPhoto {
  final Uint8List bytes;
  final String name;
  const _PendingPhoto(this.bytes, this.name);
}

class _CreatePostScreen extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String initialBadgeLabel;
  final List<String> initialImageUrls;
  const _CreatePostScreen({
    this.initialTitle = '',
    this.initialContent = '',
    this.initialBadgeLabel = 'BOARD NEWS',
    this.initialImageUrls = const [],
  });
  @override
  State<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<_CreatePostScreen> {
  static const _maxImages = 10;
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _badge;
  final List<_PendingPhoto> _photos = [];
  late final List<String> _existingUrls;

  int get _imageCount => _existingUrls.length + _photos.length;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _body = TextEditingController(text: widget.initialContent);
    _badge = TextEditingController(text: widget.initialBadgeLabel);
    _existingUrls = [...widget.initialImageUrls];
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _badge.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final available = _maxImages - _imageCount;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 10 images.')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    if (result != null && mounted) {
      final selected = result.files
          .where((file) => file.bytes != null)
          .take(available)
          .map((file) => _PendingPhoto(file.bytes!, file.name));
      setState(() {
        _photos.addAll(selected);
      });
      if (result.files.length > available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can add up to 10 images.')),
        );
      }
    }
  }

  void _post() {
    final title = _title.text.trim();
    final content = _body.text.trim();
    final badgeLabel = _badge.text.trim();
    if (title.isEmpty || content.isEmpty || badgeLabel.isEmpty) return;
    Navigator.pop(
      context,
      _NewsDraft(title, content, badgeLabel, [..._photos], [..._existingUrls]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.viewInsetsOf(context).bottom > 0;
    final enabled =
        _title.text.trim().isNotEmpty &&
        _body.text.trim().isNotEmpty &&
        _badge.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Create Post',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Positioned(
                    left: 5,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: FilledButton(
                      onPressed: enabled ? _post : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16C784),
                        disabledBackgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        disabledForegroundColor: const Color(0xFF929299),
                        minimumSize: const Size(64, 38),
                      ),
                      child: const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFFFE8B8),
                          child: Icon(Icons.person, color: Color(0xFF12275B)),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Board Secretary',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified, size: 15, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _ComposerSectionLabel(
                      icon: Icons.title_rounded,
                      label: 'News title',
                    ),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _title,
                      autofocus: true,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter a clear headline',
                        counterText: '',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _ComposerSectionLabel(
                      icon: Icons.label_outline_rounded,
                      label: 'Card badge',
                    ),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _badge,
                      maxLength: 30,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'BOARD NEWS',
                        helperText: 'Shown above the news title',
                        counterText: '${_badge.text.length}/30',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _ComposerSectionLabel(
                      icon: Icons.notes_rounded,
                      label: 'News body',
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _body,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                            hintText: 'Write the news body...',
                          ),
                        ),
                      ),
                    ),
                    if (_existingUrls.isNotEmpty || _photos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ComposerSectionLabel(
                        icon: Icons.photo_library_outlined,
                        label: 'Photos ($_imageCount)',
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: compact ? 100 : 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingUrls.length + _photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final existing = index < _existingUrls.length;
                            final image = existing
                                ? Image.network(
                                    _existingUrls[index],
                                    fit: BoxFit.cover,
                                  )
                                : Image.memory(
                                    _photos[index - _existingUrls.length].bytes,
                                    fit: BoxFit.cover,
                                  );
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(width: 180, child: image),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => setState(() {
                                        if (existing) {
                                          _existingUrls.removeAt(index);
                                        } else {
                                          _photos.removeAt(
                                            index - _existingUrls.length,
                                          );
                                        }
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _PostOptions(
              compact: compact,
              imageCount: _imageCount,
              maxImages: _maxImages,
              onPhoto: _pickPhoto,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ComposerSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF2457D6)),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: .2,
        ),
      ),
    ],
  );
}

class _PostOptions extends StatelessWidget {
  final bool compact;
  final int imageCount;
  final int maxImages;
  final VoidCallback onPhoto;
  const _PostOptions({
    required this.compact,
    required this.imageCount,
    required this.maxImages,
    required this.onPhoto,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14, compact ? 4 : 14, 14, 10),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: compact
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: imageCount < maxImages ? onPhoto : null,
                tooltip: 'Add multiple photos',
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF28A9E2),
                ),
              ),
              Text(
                '$imageCount/$maxImages photos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to your post',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: imageCount < maxImages ? onPhoto : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF28A9E2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add multiple photos',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Select several images at once',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$imageCount/$maxImages',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.add, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}

class NewsDetailScreen extends ConsumerWidget {
  final int postId;
  final bool canManage;
  const NewsDetailScreen({
    super.key,
    required this.postId,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(newsFeedProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Board News'),
        centerTitle: true,
        backgroundColor: const Color(0xFF12275B),
        foregroundColor: Colors.white,
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(ApiErrorMessage.from(error))),
        data: (items) {
          final index = items.indexWhere((post) => post.id == postId);
          if (index < 0) {
            return const Center(child: Text('This news post is unavailable.'));
          }
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Post(
                  post: items[index],
                  canManage: canManage,
                  index: index,
                  total: items.length,
                  openDetails: false,
                  showCommentsInitially: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Post extends ConsumerStatefulWidget {
  final NewsPost post;
  final bool canManage;
  final int index;
  final int total;
  final bool openDetails;
  final bool showCommentsInitially;
  const _Post({
    required this.post,
    required this.canManage,
    required this.index,
    required this.total,
    this.openDetails = true,
    this.showCommentsInitially = false,
  });
  @override
  ConsumerState<_Post> createState() => _PostState();
}

class _PostState extends ConsumerState<_Post> {
  final comment = TextEditingController();
  late bool expanded;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.showCommentsInitially;
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final body = p.content.trim();
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? null
            : Colors.white,
        gradient: Theme.of(context).brightness == Brightness.dark
            ? AppGlassDecoration.surface(
                tint: Theme.of(context).colorScheme.surface,
                darkMode: true,
              ).gradient
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .14)
              : const Color(0xFFE5EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: .38)
                : const Color(0x14001B4D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.imageUrls.isNotEmpty) _NewsImages(urls: p.imageUrls),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2457D6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        p.badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Color(0xFF9AA4B5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _time(p.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8994A8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  p.title,
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    maxLines: widget.openDetails ? 3 : null,
                    overflow: widget.openDetails
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    style: TextStyle(
                      height: 1.55,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFFFE8B8),
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 18,
                        color: Color(0xFF12275B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.author,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (widget.canManage)
                      PopupMenuButton<String>(
                        onSelected: _manage,
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit news'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'up',
                            enabled: widget.index > 0,
                            child: const ListTile(
                              leading: Icon(Icons.arrow_upward),
                              title: Text('Move up'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'down',
                            enabled: widget.index < widget.total - 1,
                            child: const ListTile(
                              leading: Icon(Icons.arrow_downward),
                              title: Text('Move down'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text('Delete news'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!widget.openDetails) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => expanded = !expanded),
                      child: Text('${p.comments.length} comments'),
                    ),
                  ),
                ],
                const Divider(height: 1),
                Row(
                  children: [
                    ...[
                      ('LIKE', Icons.thumb_up_alt_outlined, 'Like'),
                      ('LOVE', Icons.favorite_border, 'Love'),
                      ('CELEBRATE', Icons.celebration_outlined, 'Celebrate'),
                    ].map(
                      (r) => Expanded(
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(newsFeedProvider.notifier)
                              .react(p.id, r.$1),
                          icon: Icon(r.$2, size: 18),
                          label: Text('${r.$3} ${p.reactions[r.$1] ?? 0}'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 10,
                            ),
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 11),
                            foregroundColor: p.currentReaction == r.$1
                                ? const Color(0xFF2457D6)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!widget.openDetails && expanded) ...[
                  const Divider(),
                  ...p.comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(c.message),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: comment,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment…',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (!widget.openDetails) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NewsDetailScreen(postId: p.id, canManage: widget.canManage),
          ),
        ),
        child: card,
      ),
    );
  }

  Future<void> _send() async {
    final value = comment.text.trim();
    if (value.isEmpty) return;
    setState(() => sending = true);
    try {
      await ref.read(newsFeedProvider.notifier).comment(widget.post.id, value);
      comment.clear();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _manage(String action) async {
    final notifier = ref.read(newsFeedProvider.notifier);
    if (action == 'up') return notifier.move(widget.post.id, -1);
    if (action == 'down') return notifier.move(widget.post.id, 1);
    if (action == 'delete') {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete this news post?'),
              content: const Text(
                'Comments and reactions will also be removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;
      if (confirmed) await notifier.delete(widget.post.id);
      return;
    }
    if (action == 'edit') {
      final draft = await Navigator.push<_NewsDraft>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _CreatePostScreen(
            initialTitle: widget.post.title,
            initialContent: widget.post.content,
            initialBadgeLabel: widget.post.badgeLabel,
            initialImageUrls: widget.post.imageUrls,
          ),
        ),
      );
      if (draft == null) return;
      try {
        final repository = ref.read(newsRepositoryProvider);
        final uploaded = await Future.wait(
          draft.photos.map(
            (photo) => repository.uploadPhoto(photo.bytes, photo.name),
          ),
        );
        await notifier.update(
          widget.post.id,
          draft.title,
          draft.content,
          draft.badgeLabel,
          [...draft.existingUrls, ...uploaded],
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiErrorMessage.from(error))));
      }
    }
  }

  String _time(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _NewsImages extends StatelessWidget {
  final List<String> urls;
  const _NewsImages({required this.urls});

  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final visibleUrls = urls.take(4).toList(growable: false);
    final collage = switch (visibleUrls.length) {
      1 => _photo(visibleUrls[0]),
      2 => Row(
        children: [
          Expanded(child: _photo(visibleUrls[0])),
          const SizedBox(width: _gap),
          Expanded(child: _photo(visibleUrls[1])),
        ],
      ),
      3 => Row(
        children: [
          Expanded(flex: 6, child: _photo(visibleUrls[0])),
          const SizedBox(width: _gap),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(child: _photo(visibleUrls[1])),
                const SizedBox(height: _gap),
                Expanded(child: _photo(visibleUrls[2])),
              ],
            ),
          ),
        ],
      ),
      _ => Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _photo(visibleUrls[0])),
                const SizedBox(width: _gap),
                Expanded(child: _photo(visibleUrls[1])),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _photo(visibleUrls[2])),
                const SizedBox(width: _gap),
                Expanded(
                  child: _photo(
                    visibleUrls[3],
                    remaining: urls.length > 4 ? urls.length - 4 : 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    };

    return SizedBox(
      width: double.infinity,
      height: urls.length == 1 ? 240 : 280,
      child: collage,
    );
  }

  Widget _photo(String url, {int remaining = 0}) => Stack(
    fit: StackFit.expand,
    children: [
      Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFF0F3F8),
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF8994AA),
              size: 34,
            ),
          ),
        ),
      ),
      if (remaining > 0) ...[
        const ColoredBox(color: Color(0x8F071C4D)),
        Center(
          child: Text(
            '+$remaining',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
        ),
      ],
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(
          Icons.newspaper_outlined,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        const Text('No board news has been posted yet.'),
      ],
    ),
  );
}

class _NewsLoadError extends StatelessWidget {
  final String message;

  const _NewsLoadError({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ],
    ),
  );
}
