import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../meetings/presentation/meeting_detail_screen.dart';
import '../../meetings/model/meeting_model.dart';
import '../../meetings/provider/meeting_provider.dart';
import '../../papers/presentation/paper_detail_screen.dart';
import '../../papers/provider/paper_provider.dart';
import '../provider/favorite_provider.dart';

class MemberLibraryScreen extends ConsumerWidget {
  const MemberLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('My Library'),
        bottom: const TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.white,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(icon: Icon(Icons.star_rounded), text: 'Favorites'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Last viewed'),
          ],
        ),
      ),
      body: const TabBarView(children: [_FavoritesTab(), _RecentTab()]),
    ),
  );
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteListProvider);
    final meetings = ref.watch(meetingListProvider).valueOrNull ?? const [];
    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: 'Could not load favorites: $error',
        onRetry: () => ref.invalidate(favoriteListProvider),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(favoriteListProvider),
        child: items.isEmpty
            ? const _EmptyList(
                icon: Icons.star_border_rounded,
                message: 'Favorite meetings and papers will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final MeetingModel? matchingMeeting =
                      item.favoriteType == 'MEETING'
                      ? meetings
                            .where((meeting) => meeting.id == item.targetId)
                            .firstOrNull
                      : null;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          item.favoriteType == 'MEETING'
                              ? Icons.event_note_outlined
                              : Icons.description_outlined,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(item.subtitle),
                      trailing: IconButton(
                        tooltip: 'Remove favorite',
                        onPressed: () => toggleFavorite(
                          ref,
                          type: item.favoriteType,
                          id: item.targetId,
                        ),
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB52E),
                        ),
                      ),
                      onTap: matchingMeeting == null
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MeetingDetailScreen(
                                  meeting: matchingMeeting,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _RecentTab extends ConsumerWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentPaperListProvider);
    return recent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: 'Could not load reading history: $error',
        onRetry: () => ref.invalidate(recentPaperListProvider),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(recentPaperListProvider),
        child: items.isEmpty
            ? const _EmptyList(
                icon: Icons.history_rounded,
                message: 'Documents you open will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.picture_as_pdf_outlined),
                      ),
                      title: Text(
                        item.paper.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        item.completed
                            ? 'Completed'
                            : 'Continue from page ${item.lastPage}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaperDetailScreen(paper: item.paper),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyList({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SizedBox(
        height: 360,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
