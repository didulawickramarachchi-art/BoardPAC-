import 'package:flutter/material.dart';

class ReactionBar extends StatelessWidget {
  final String? currentReaction;
  final Map<String, int> counts;
  final ValueChanged<String> onReact;

  const ReactionBar({
    super.key,
    required this.currentReaction,
    required this.counts,
    required this.onReact,
  });

  static const _reactions = <String, (String, IconData, Color)>{
    'LIKE': ('Like', Icons.thumb_up, Color(0xFF1877F2)),
    'LOVE': ('Love', Icons.favorite, Color(0xFFE91E63)),
    'DISLIKE': ('Dislike', Icons.thumb_down, Color(0xFF6E7781)),
  };

  @override
  Widget build(BuildContext context) {
    final selected = _reactions[currentReaction];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<String>(
          onSelected: onReact,
          itemBuilder: (_) => _reactions.entries
              .map(
                (entry) => PopupMenuItem(
                  value: entry.key,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.value.$2, color: entry.value.$3),
                      const SizedBox(width: 10),
                      Text(entry.value.$1),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected?.$2 ?? Icons.add_reaction_outlined,
                size: 18,
                color: selected?.$3,
              ),
              const SizedBox(width: 5),
              Text(
                selected?.$1 ?? 'React',
                style: TextStyle(
                  color: selected?.$3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ..._reactions.entries
            .where((entry) => (counts[entry.key] ?? 0) > 0)
            .map(
              (entry) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.value.$2, size: 14, color: entry.value.$3),
                  const SizedBox(width: 2),
                  Text('${counts[entry.key]}'),
                ],
              ),
            ),
      ],
    );
  }
}
