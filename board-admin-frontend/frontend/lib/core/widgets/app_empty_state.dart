import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  final String message;

  const AppEmptyState({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}