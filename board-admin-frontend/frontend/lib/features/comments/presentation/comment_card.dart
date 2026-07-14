import 'package:flutter/material.dart';

import '../model/comment_model.dart';
import '../../../core/widgets/reaction_bar.dart';

class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final ValueChanged<String>? onReact;
  final VoidCallback? onShare;

  const CommentCard({
    super.key,
    required this.comment,
    this.onReact,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final initial = comment.createdByUsername.trim().isEmpty
        ? '?'
        : comment.createdByUsername.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDCE5FA),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF12275B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.createdByUsername,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12275B),
                              ),
                            ),
                          ),
                          if (comment.annotated)
                            const Icon(
                              Icons.draw_outlined,
                              size: 16,
                              color: Color(0xFF6E7DA5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(comment.commentText),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 5),
                  child: Row(
                    children: [
                      if (onReact != null)
                        Expanded(child: ReactionBar(currentReaction: comment.currentReaction, counts: comment.reactionCounts, onReact: onReact!)),
                      if (onShare != null) ...[
                        const SizedBox(width: 18),
                        InkWell(
                          onTap: onShare,
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              color: Color(0xFF5F6673),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
