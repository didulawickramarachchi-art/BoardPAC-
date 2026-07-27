import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
        return AppColors.successSurface;
      case 'PENDING':
      case 'TENTATIVE':
        return AppColors.warningSurface;
      case 'REJECT':
      case 'DECLINED':
      case 'DEACTIVATED':
      case 'INACTIVE':
      case 'LOCKED':
        return AppColors.dangerSurface;
      default:
        return AppColors.surfaceMuted;
    }
  }

  Color _foreground(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
      case 'APPROVE':
      case 'APPROVED':
      case 'READ':
      case 'ACCEPTED':
        return AppColors.success;
      case 'PENDING':
      case 'TENTATIVE':
        return AppColors.warning;
      case 'REJECT':
      case 'DECLINED':
      case 'DEACTIVATED':
      case 'INACTIVE':
      case 'LOCKED':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: _foreground(label))),
      backgroundColor: _background(label),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
