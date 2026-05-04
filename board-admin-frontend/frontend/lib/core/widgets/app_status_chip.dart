import 'package:flutter/material.dart';

class AppStatusChip extends StatelessWidget {
  final String label;

  const AppStatusChip({
    super.key,
    required this.label,
  });

  Color _background(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
      case 'APPROVE':
      case 'APPROVED':
      case 'READ':
      case 'ACCEPTED':
        return Colors.green.shade100;
      case 'PENDING':
      case 'TENTATIVE':
        return Colors.orange.shade100;
      case 'REJECT':
      case 'DECLINED':
      case 'DEACTIVATED':
      case 'LOCKED':
        return Colors.red.shade100;
      default:
        return Colors.blueGrey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: _background(label),
      side: BorderSide.none,
    );
  }
}