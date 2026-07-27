import 'package:flutter/material.dart';

class AppInfoTile extends StatelessWidget {
  final String title;
  final String value;

  const AppInfoTile({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final valueText = Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: compact ? 2 : 1,
          style: const TextStyle(fontWeight: FontWeight.w600),
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                valueText,
              ],
            ),
          );
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
            child: valueText,
          ),
        );
      },
    );
  }
}
