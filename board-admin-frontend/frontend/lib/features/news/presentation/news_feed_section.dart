import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_message.dart';
import '../model/news_post.dart';
import '../provider/news_provider.dart';

class NewsFeedSection extends ConsumerWidget {
  final bool canCreate;
  const NewsFeedSection({super.key, required this.canCreate});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(newsFeedProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Board news',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF071C4D),
              ),
            ),
            Text(
              'Updates and conversations from your board',
              style: TextStyle(color: Color(0xFF69758C)),
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
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16001B4D),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFDDE5F7),
                      child: Icon(
                        Icons.newspaper_rounded,
                        color: Color(0xFF12275B),
                      ),
                    ),
                    SizedBox(width: 13),
                    Text(
                      'Create News',
                      style: TextStyle(
                        color: Color(0xFF071C4D),
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
          error: (e, _) => Center(child: Text(ApiErrorMessage.from(e))),
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
  final List<_PendingPhoto> photos;
  final List<String> existingUrls;
  const _NewsDraft(this.title, this.content, this.photos, this.existingUrls);
}

class _PendingPhoto {
  final Uint8List bytes;
  final String name;
  const _PendingPhoto(this.bytes, this.name);
}

class _CreatePostScreen extends StatefulWidget {
  final String initialContent;
  final List<String> initialImageUrls;
  const _CreatePostScreen({
    this.initialContent = '',
    this.initialImageUrls = const [],
  });
  @override
  State<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<_CreatePostScreen> {
  late final TextEditingController _body;
  final List<_PendingPhoto> _photos = [];
  late final List<String> _existingUrls;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.initialContent);
    _existingUrls = [...widget.initialImageUrls];
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    if (result != null && mounted) {
      final available = 10 - _existingUrls.length - _photos.length;
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
    final content = _body.text.trim();
    if (content.isEmpty) return;
    final firstLine = content.split('\n').first;
    final title = firstLine.length > 80
        ? '${firstLine.substring(0, 77)}...'
        : firstLine;
    Navigator.pop(
      context,
      _NewsDraft(title, content, [..._photos], [..._existingUrls]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.viewInsetsOf(context).bottom > 0;
    final enabled = _body.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
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
                        disabledBackgroundColor: const Color(0xFFF0F0F2),
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _body,
                        autofocus: true,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'What do you want to talk about?',
                        ),
                      ),
                    ),
                    if (_existingUrls.isNotEmpty || _photos.isNotEmpty)
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
                ),
              ),
            ),
            _PostOptions(compact: compact, onPhoto: _pickPhoto),
          ],
        ),
      ),
    );
  }
}

class _PostOptions extends StatelessWidget {
  final bool compact;
  final VoidCallback onPhoto;
  const _PostOptions({required this.compact, required this.onPhoto});
  static const items = [
    ('Photo/Video', Icons.add_photo_alternate_outlined, Color(0xFF28A9E2)),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14, compact ? 4 : 14, 14, 10),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE9E9EC))),
    ),
    child: compact
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: items
                .map(
                  (item) => IconButton(
                    onPressed: item.$1 == 'Photo/Video' ? onPhoto : null,
                    tooltip: item.$1,
                    icon: Icon(item.$2, color: item.$3),
                  ),
                )
                .toList(),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to your post',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: item.$1 == 'Photo/Video' ? onPhoto : null,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(item.$2, color: item.$3),
                          const SizedBox(width: 7),
                          Expanded(child: Text(item.$1)),
                          const Icon(Icons.add, size: 17),
                        ],
                      ),
                    ),
                  );
                },
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
      backgroundColor: const Color(0xFFF3F6FC),
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
    final titleIsExcerpt = p.content.startsWith(
      p.title.endsWith('...')
          ? p.title.substring(0, p.title.length - 3)
          : p.title,
    );
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E6F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12001B4D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFE8B8),
                child: Icon(Icons.campaign_rounded, color: Color(0xFF12275B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.author,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _time(p.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF69758C),
                      ),
                    ),
                  ],
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
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete news'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!titleIsExcerpt) ...[
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF071C4D),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            p.content,
            maxLines: widget.openDetails ? 3 : null,
            overflow: widget.openDetails
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: const TextStyle(height: 1.4),
          ),
          if (p.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _NewsImages(urls: p.imageUrls),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text('${p.comments.length} comments'),
            ),
          ),
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
                    onPressed: () =>
                        ref.read(newsFeedProvider.notifier).react(p.id, r.$1),
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
                          : const Color(0xFF69758C),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const Divider(),
            ...p.comments.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4FA),
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
            initialContent: widget.post.content,
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
        await notifier.update(widget.post.id, draft.title, draft.content, [
          ...draft.existingUrls,
          ...uploaded,
        ]);
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

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          urls.first,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            urls[index],
            width: MediaQuery.sizeOf(context).width * .72,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.newspaper_outlined, size: 36, color: Color(0xFF69758C)),
        SizedBox(height: 8),
        Text('No board news has been posted yet.'),
      ],
    ),
  );
}
