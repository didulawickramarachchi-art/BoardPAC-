import 'package:flutter/material.dart';

/// Shared breakpoints used throughout the application.
///
/// The values deliberately describe available layout width rather than a
/// particular device. This also makes the UI respond correctly when a desktop
/// window is resized or the app is shown in split-screen mode.
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
  static const double maxContentWidth = 1440;
}

extension ResponsiveContext on BuildContext {
  double get layoutWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => layoutWidth < AppBreakpoints.compact;
  bool get isMedium =>
      layoutWidth >= AppBreakpoints.compact &&
      layoutWidth < AppBreakpoints.medium;
  bool get isExpanded => layoutWidth >= AppBreakpoints.medium;

  double get pageGutter {
    if (layoutWidth >= AppBreakpoints.expanded) return 32;
    if (layoutWidth >= AppBreakpoints.compact) return 24;
    return 16;
  }
}

/// Gives every route a safe, centered viewport on very wide displays while
/// leaving phones, tablets, and ordinary desktop windows completely fluid.
class ResponsiveAppViewport extends StatelessWidget {
  const ResponsiveAppViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return ColoredBox(
      color: const Color(0xFFE9ECF4),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: SizedBox(
            width: double.infinity,
            height: mediaQuery.size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Centers page content and applies gutters that scale with available width.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: context.pageGutter),
          child: child,
        ),
      ),
    );
  }
}

int responsiveColumnCount(
  double width, {
  int compact = 1,
  int medium = 2,
  int expanded = 3,
  int large = 4,
}) {
  if (width >= AppBreakpoints.expanded) return large;
  if (width >= AppBreakpoints.medium) return expanded;
  if (width >= AppBreakpoints.compact) return medium;
  return compact;
}
