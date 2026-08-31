import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/favorite_provider.dart';

class FavoriteButton extends ConsumerWidget {
  final String type;
  final int targetId;
  final Color? color;
  const FavoriteButton({
    super.key,
    required this.type,
    required this.targetId,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = (type: type.toUpperCase(), id: targetId);
    final selected = ref.watch(isFavoriteProvider(target));
    return IconButton(
      tooltip: selected ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(selected ? Icons.star_rounded : Icons.star_border_rounded),
      color: selected ? const Color(0xFFFFB52E) : color,
      onPressed: () async {
        try {
          await toggleFavorite(ref, type: type, id: targetId);
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not update favorite: $error')),
            );
          }
        }
      },
    );
  }
}
