import 'dart:async';

import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  Timer? _navigationTimer;
  Timer? _entranceTimer;
  late final AnimationController _backgroundController;
  late final AnimationController _entranceController;
  late final AnimationController _logoWipeController;
  late final Animation<double> _panelOpacity;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _logoReveal;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoWipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _panelOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeInOutCubic,
    );
    _badgeOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 1, curve: Curves.easeInOutCubic),
    );
    _logoReveal = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 8),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
    ]).animate(_logoWipeController);

    _entranceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _entranceController.forward();
      _logoWipeController.forward(from: 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _backgroundController.forward();
      }
    });
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceTimer?.cancel();
    _backgroundController.dispose();
    _entranceController.dispose();
    _logoWipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00003D),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;
          final logoBoxSize = (shortestSide * 0.39)
              .clamp(180.0, 235.0)
              .toDouble();

          return Stack(
            fit: StackFit.expand,
            children: [
              _BackgroundDecoration(animation: _backgroundController),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _panelOpacity,
                      child: Container(
                        width: logoBoxSize,
                        height: logoBoxSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            logoBoxSize * 0.29,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF020552), Color(0xFF008CCC)],
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _logoReveal,
                          builder: (context, child) => ClipRect(
                            clipper: _HorizontalRevealClipper(
                              reveal: _logoReveal.value,
                            ),
                            child: child,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(logoBoxSize * 0.085),
                            child: Image.asset(
                              'assets/images/slpa_logo.png',
                              width: logoBoxSize,
                              height: logoBoxSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _badgeOpacity,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFB600),
                                width: 4,
                              ),
                            ),
                            child: const Text(
                              'BOARDPACK',
                              style: TextStyle(
                                color: Color(0xFFFFB600),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFB600),
                              strokeWidth: 3,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HorizontalRevealClipper extends CustomClipper<Rect> {
  const _HorizontalRevealClipper({required this.reveal});

  final double reveal;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * reveal, size.height);

  @override
  bool shouldReclip(_HorizontalRevealClipper oldClipper) =>
      oldClipper.reveal != reveal;
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final topProgress = Curves.easeInOutCubic.transform(
          const Interval(0, 0.82).transform(animation.value),
        );
        final middleProgress = Curves.easeInOutCubic.transform(
          const Interval(0.06, 0.9).transform(animation.value),
        );
        final bottomProgress = Curves.easeInOutCubic.transform(
          const Interval(0.14, 1).transform(animation.value),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _DecorativeCircle(
              alignment: Alignment(0.78, -1.06),
              diameterFactor: 0.47,
              travel: Offset(1.6 * (1 - topProgress), -1.4 * (1 - topProgress)),
            ),
            _DecorativeCircle(
              alignment: Alignment(-1.08, -0.13),
              diameterFactor: 0.32,
              travel: Offset(-2.0 * (1 - middleProgress), 0),
            ),
            _DecorativeCircle(
              alignment: Alignment(-1.02, 0.91),
              diameterFactor: 0.30,
              travel: Offset(
                -1.7 * (1 - bottomProgress),
                1.3 * (1 - bottomProgress),
              ),
            ),
            _DecorativeCircle(
              alignment: Alignment(1.08, 0.94),
              diameterFactor: 0.48,
              travel: Offset(
                1.5 * (1 - bottomProgress),
                1.2 * (1 - bottomProgress),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    required this.alignment,
    required this.diameterFactor,
    required this.travel,
  });

  final Alignment alignment;
  final double diameterFactor;
  final Offset travel;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: travel,
      child: Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: diameterFactor,
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0C0C67),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
