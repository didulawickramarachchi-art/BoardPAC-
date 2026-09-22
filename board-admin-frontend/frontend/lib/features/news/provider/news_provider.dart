import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/news_repository.dart';
import '../model/news_post.dart';

final newsRepositoryProvider = Provider(
  (ref) => NewsRepository(ref.read(dioProvider)),
);
final newsFeedProvider =
    StateNotifierProvider<NewsNotifier, AsyncValue<List<NewsPost>>>(
      (ref) => NewsNotifier(ref.read(newsRepositoryProvider))..load(),
    );

class NewsNotifier extends StateNotifier<AsyncValue<List<NewsPost>>> {
  final NewsRepository repository;
  final Map<int, int> _reactionRevisions = {};
  NewsNotifier(this.repository) : super(const AsyncLoading());
  Future<void> load() async {
    try {
      final v = await repository.getAll();
      if (mounted) state = AsyncData(v);
    } catch (e, s) {
      if (mounted) state = AsyncError(e, s);
    }
  }

  Future<void> create(
    String t,
    String c,
    String badgeLabel,
    List<String> imageUrls,
  ) async {
    final p = await repository.create(t, c, badgeLabel, imageUrls);
    if (mounted) state = AsyncData([p, ...state.valueOrNull ?? const []]);
  }

  Future<void> update(
    int id,
    String t,
    String c,
    String badgeLabel,
    List<String> imageUrls,
  ) async => _replace(await repository.update(id, t, c, badgeLabel, imageUrls));

  Future<void> delete(int id) async {
    await repository.delete(id);
    if (mounted) {
      state = AsyncData(
        (state.valueOrNull ?? const []).where((post) => post.id != id).toList(),
      );
    }
  }

  Future<void> move(int id, int offset) async {
    final items = [...state.valueOrNull ?? const <NewsPost>[]];
    final from = items.indexWhere((post) => post.id == id);
    final to = from + offset;
    if (from < 0 || to < 0 || to >= items.length) return;
    final post = items.removeAt(from);
    items.insert(to, post);
    state = AsyncData(items);
    try {
      await repository.reorder(items.map((item) => item.id).toList());
    } catch (_) {
      await load();
    }
  }

  Future<void> comment(int id, String m) async =>
      _replace(await repository.comment(id, m));
  Future<void> react(int id, String type) async {
    final items = state.valueOrNull;
    if (items == null) return;
    final index = items.indexWhere((post) => post.id == id);
    if (index < 0) return;

    final previous = items[index];
    final oldReaction = previous.currentReaction;
    final newReaction = oldReaction == type ? null : type;
    final counts = Map<String, int>.from(previous.reactions);

    if (oldReaction != null) {
      final updated = (counts[oldReaction] ?? 0) - 1;
      if (updated > 0) {
        counts[oldReaction] = updated;
      } else {
        counts.remove(oldReaction);
      }
    }
    if (newReaction != null) {
      counts[newReaction] = (counts[newReaction] ?? 0) + 1;
    }

    final revision = (_reactionRevisions[id] ?? 0) + 1;
    _reactionRevisions[id] = revision;
    _replace(
      previous.copyWithReaction(
        reactions: counts,
        currentReaction: newReaction,
      ),
    );

    try {
      final confirmed = await repository.react(id, type);
      if (mounted && _reactionRevisions[id] == revision) {
        _replace(confirmed);
      }
    } catch (_) {
      if (mounted && _reactionRevisions[id] == revision) {
        _replace(previous);
      }
    }
  }

  void _replace(NewsPost p) {
    if (mounted) {
      state = AsyncData(
        (state.valueOrNull ?? const [])
            .map((x) => x.id == p.id ? p : x)
            .toList(),
      );
    }
  }
}
