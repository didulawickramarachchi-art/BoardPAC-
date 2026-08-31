import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/favorite_repository.dart';
import '../model/favorite_model.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepository(ref.read(dioProvider)),
);

final favoriteListProvider = FutureProvider<List<FavoriteModel>>(
  (ref) => ref.read(favoriteRepositoryProvider).getAll(),
);

final isFavoriteProvider = Provider.family<bool, ({String type, int id})>((
  ref,
  target,
) {
  final favorites = ref.watch(favoriteListProvider).valueOrNull ?? const [];
  return favorites.any(
    (item) =>
        item.favoriteType == target.type.toUpperCase() &&
        item.targetId == target.id,
  );
});

Future<void> toggleFavorite(
  WidgetRef ref, {
  required String type,
  required int id,
}) async {
  final target = (type: type.toUpperCase(), id: id);
  final selected = ref.read(isFavoriteProvider(target));
  final repository = ref.read(favoriteRepositoryProvider);
  if (selected) {
    await repository.remove(target.type, id);
  } else {
    await repository.add(target.type, id);
  }
  ref.invalidate(favoriteListProvider);
}
