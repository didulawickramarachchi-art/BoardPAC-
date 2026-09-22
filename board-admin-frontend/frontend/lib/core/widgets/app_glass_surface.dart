import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A liquid-glass surface for isolated panels. For long lists and grids, use
/// [AppGlassDecoration.surface] directly to avoid stacking blur filters.
class AppGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final Color? tint;
  final double blurSigma;
  final bool enableBackdropBlur;

  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
    this.tint,
    this.blurSigma = 10,
    this.enableBackdropBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Container(
      padding: padding,
      decoration: AppGlassDecoration.surface(
        borderRadius: borderRadius,
        tint: tint ?? Theme.of(context).colorScheme.surface,
        darkMode: isDark,
      ),
      child: child,
    );
    final content = ClipRRect(
      borderRadius: borderRadius,
      child: enableBackdropBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: surface,
            )
          : surface,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
    );
  }
}

abstract final class AppGlassDecoration {
  static BoxDecoration surface({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(24)),
    Color tint = Colors.white,
    bool darkMode = false,
  }) {
    if (darkMode) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.46, 1],
          colors: [
            Color.alphaBlend(
              tint.withValues(alpha: 0.16),
              const Color(0xD9273552),
            ),
            const Color(0xD91A2741),
            const Color(0xE611192B),
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFFB8CCFF).withValues(alpha: 0.16),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF7395E8).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 0.48, 1],
        colors: [
          Colors.white.withValues(alpha: 0.82),
          Color.alphaBlend(
            tint.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.62),
          ),
          const Color(0xFFEAF0FA).withValues(alpha: 0.58),
        ],
      ),
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.95),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.075),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.75),
          blurRadius: 4,
          offset: const Offset(-2, -2),
        ),
      ],
    );
  }

  static BoxDecoration dark({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(26)),
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xE64B65A5), Color(0xF000184A)],
      ),
      borderRadius: borderRadius,
      border: Border.all(color: Colors.white24),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDark.withValues(alpha: 0.22),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static const BoxDecoration background = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8FAFF), Color(0xFFE9EFFA), Color(0xFFFFF7E8)],
      stops: [0, 0.62, 1],
    ),
  );

  static BoxDecoration backgroundFor(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return background;
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF080E1C), Color(0xFF101A30), Color(0xFF181525)],
        stops: [0, 0.62, 1],
      ),
    );
  }
}
