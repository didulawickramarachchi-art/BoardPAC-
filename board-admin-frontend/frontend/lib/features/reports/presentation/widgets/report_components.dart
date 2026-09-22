import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ReportHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<ReportMetric> metrics;

  const ReportHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.navyDark, AppColors.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3812275B),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.gold, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFC5CEE5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: metrics
                .map(
                  (metric) => Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          metric.label,
                          style: const TextStyle(
                            color: Color(0xFFAAB7D7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}

class ReportMetric {
  final String value;
  final String label;
  const ReportMetric(this.value, this.label);
}

class ReportCardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const ReportCardShell({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D00184A),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class ReportEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ReportEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.success, size: 38),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class ReportErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ReportErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFF7D8CB2),
          ),
          const SizedBox(height: 14),
          Text(
            'Unable to load report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class ReportLoadingSkeleton extends StatefulWidget {
  final int cardCount;
  const ReportLoadingSkeleton({super.key, this.cardCount = 4});

  @override
  State<ReportLoadingSkeleton> createState() => _ReportLoadingSkeletonState();
}

class _ReportLoadingSkeletonState extends State<ReportLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: .42,
      end: .9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (context, child) => Opacity(opacity: _opacity.value, child: child),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SkeletonBox(height: 154, radius: 24),
        const SizedBox(height: 18),
        const _SkeletonBox(height: 58, radius: 16),
        const SizedBox(height: 24),
        ...List.generate(
          widget.cardCount,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(),
          ),
        ),
      ],
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) => const ReportCardShell(
    child: Row(
      children: [
        _SkeletonBox(width: 48, height: 48, radius: 15),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(height: 15, widthFactor: .78),
              SizedBox(height: 12),
              _SkeletonBox(height: 11, widthFactor: .55),
              SizedBox(height: 8),
              _SkeletonBox(height: 11, widthFactor: .38),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final double? widthFactor;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.radius = 8,
    this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return widthFactor == null
        ? box
        : FractionallySizedBox(
            widthFactor: widthFactor,
            alignment: Alignment.centerLeft,
            child: box,
          );
  }
}
