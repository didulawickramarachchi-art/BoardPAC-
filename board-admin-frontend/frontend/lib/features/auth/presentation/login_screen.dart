import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(.1, 1, curve: Curves.easeOutCubic),
    );
    _slide = Tween(begin: const Offset(0, .045), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (state.requiresTwoFactor) {
      Navigator.pushNamed(context, '/verify-2fa');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF020B25),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LuxuryBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 960;
                          final landscape =
                              MediaQuery.sizeOf(context).height < 650 &&
                              constraints.maxWidth >= 600;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                              child: Container(
                                decoration: _glassDecoration,
                                child: wide
                                    ? SizedBox(
                                        height: 610,
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: _BrandPanel(),
                                            ),
                                            SizedBox(
                                              width: 450,
                                              child: _LoginPanel(
                                                formKey: _formKey,
                                                usernameController:
                                                    _usernameController,
                                                passwordController:
                                                    _passwordController,
                                                obscurePassword:
                                                    _obscurePassword,
                                                loading: state.isLoading,
                                                error: state.error,
                                                onTogglePassword: () =>
                                                    setState(
                                                      () => _obscurePassword =
                                                          !_obscurePassword,
                                                    ),
                                                onLogin: _login,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : landscape
                                    ? SizedBox(
                                        height: 470,
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 190,
                                              child: _CompactBrand(),
                                            ),
                                            Expanded(
                                              child: _LoginPanel(
                                                formKey: _formKey,
                                                usernameController:
                                                    _usernameController,
                                                passwordController:
                                                    _passwordController,
                                                obscurePassword:
                                                    _obscurePassword,
                                                loading: state.isLoading,
                                                error: state.error,
                                                compact: true,
                                                onTogglePassword: () =>
                                                    setState(
                                                      () => _obscurePassword =
                                                          !_obscurePassword,
                                                    ),
                                                onLogin: _login,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const _CompactBrand(),
                                          _LoginPanel(
                                            formKey: _formKey,
                                            usernameController:
                                                _usernameController,
                                            passwordController:
                                                _passwordController,
                                            obscurePassword: _obscurePassword,
                                            loading: state.isLoading,
                                            error: state.error,
                                            onTogglePassword: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                            onLogin: _login,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _glassDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: .18),
        Colors.white.withValues(alpha: .075),
        const Color(0xFF4C67A8).withValues(alpha: .10),
      ],
    ),
    borderRadius: BorderRadius.circular(34),
    border: Border.all(color: Colors.white.withValues(alpha: .25), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .38),
        blurRadius: 70,
        offset: const Offset(0, 28),
      ),
      BoxShadow(
        color: const Color(0xFF2D65D4).withValues(alpha: .14),
        blurRadius: 55,
        spreadRadius: -8,
      ),
    ],
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 610),
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(color: Colors.white.withValues(alpha: .12)),
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/BG.jpeg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF071C4D).withValues(alpha: .32),
                const Color(0xFF071C4D).withValues(alpha: .48),
                const Color(0xFF00143F).withValues(alpha: .72),
              ],
              stops: const [0, .48, 1],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoMark(size: 92),
              Spacer(),
              Text(
                'Govern with clarity.\nLead with confidence.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.15,
                  letterSpacing: -.8,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: 390,
                child: Text(
                  'A secure digital workspace for meetings, decisions, and board collaboration.',
                  style: TextStyle(
                    color: Color(0xFFD7E1F5),
                    fontSize: 15,
                    height: 1.55,
                    shadows: [Shadow(color: Color(0x99000000), blurRadius: 10)],
                  ),
                ),
              ),
              SizedBox(height: 46),
              _SecurityBadge(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(24, 30, 24, 0),
    child: Column(
      children: [
        _LogoMark(size: 76),
        SizedBox(height: 14),
        Text(
          'BOARDPAC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .08),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .94),
      border: Border.all(color: Colors.white.withValues(alpha: .8), width: 2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFFB52E).withValues(alpha: .22),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Image.asset('assets/images/slpa_logo.png', fit: BoxFit.contain),
  );
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_outlined, color: Color(0xFFFFC85A), size: 17),
        SizedBox(width: 8),
        Text(
          'Secure board access',
          style: TextStyle(
            color: Color(0xFFD9E2F7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _LoginPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final String? error;
  final bool compact;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.error,
    this.compact = false,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: compact
        ? const EdgeInsets.fromLTRB(28, 22, 28, 18)
        : const EdgeInsets.fromLTRB(38, 48, 38, 40),
    child: Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB52E).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFB52E).withValues(alpha: .28),
                  ),
                ),
                child: const Text(
                  'BOARD MANAGEMENT SYSTEM',
                  style: TextStyle(
                    color: Color(0xFFFFC85A),
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 10 : 25),
            Text(
              'Welcome Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 24 : 29,
                letterSpacing: -.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 3 : 8),
            const Text(
              'Sign in to your account',
              style: TextStyle(
                color: Color(0xFFAFBEDD),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: compact ? 13 : 31),
            const _FieldLabel('Username'),
            SizedBox(height: compact ? 5 : 9),
            _GlassTextField(
              controller: usernameController,
              hintText: 'Enter your username',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Username is required' : null,
            ),
            SizedBox(height: compact ? 9 : 20),
            const _FieldLabel('Password'),
            SizedBox(height: compact ? 5 : 9),
            _GlassTextField(
              controller: passwordController,
              hintText: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => loading ? null : onLogin(),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Password is required' : null,
            ),
            if (error != null) ...[
              SizedBox(height: compact ? 7 : 17),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6464).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF8A8A).withValues(alpha: .26),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFFFA0A0),
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFFFC2C2),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: compact ? 12 : 28),
            SizedBox(
              width: double.infinity,
              height: compact ? 48 : 54,
              child: FilledButton(
                onPressed: loading ? null : onLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB52E),
                  foregroundColor: const Color(0xFF07163B),
                  disabledBackgroundColor: const Color(
                    0xFFFFB52E,
                  ).withValues(alpha: .45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox.square(
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF07163B),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sign In >',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
              ),
            ),
            SizedBox(height: compact ? 10 : 27),
            Center(
              child: Text(
                '© ${DateTime.now().year} Sri Lanka Ports Authority',
                style: const TextStyle(
                  color: Color(0xFF8293B8),
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFFDCE5F8),
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.suffixIcon,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    onFieldSubmitted: onSubmitted,
    validator: validator,
    cursorColor: const Color(0xFFFFC85A),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF7F90B3), fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFFAFC0E1), size: 20),
      suffixIcon: suffixIcon,
      suffixIconColor: const Color(0xFFAFC0E1),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .075),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: _border(Colors.white.withValues(alpha: .13)),
      enabledBorder: _border(Colors.white.withValues(alpha: .13)),
      focusedBorder: _border(
        const Color(0xFFFFC85A).withValues(alpha: .75),
        1.4,
      ),
      errorBorder: _border(const Color(0xFFFF8A8A).withValues(alpha: .7)),
      focusedErrorBorder: _border(const Color(0xFFFF8A8A), 1.4),
      errorStyle: const TextStyle(color: Color(0xFFFFB5B5)),
    ),
  );

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _LuxuryBackground extends StatelessWidget {
  const _LuxuryBackground();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020719), Color(0xFF071A45), Color(0xFF020B25)],
          ),
        ),
      ),
      const Positioned(
        top: -210,
        right: -120,
        child: _GlowOrb(size: 520, color: Color(0xFF2563EB)),
      ),
      const Positioned(
        bottom: -230,
        left: -160,
        child: _GlowOrb(size: 520, color: Color(0xFF7357D8)),
      ),
      Positioned(
        top: 80,
        left: MediaQuery.sizeOf(context).width * .2,
        child: const _GlowOrb(
          size: 250,
          color: Color(0xFFD49428),
          opacity: .12,
        ),
      ),
      CustomPaint(painter: _GridPainter()),
    ],
  );
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({required this.size, required this.color, this.opacity = .26});
  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .025)
      ..strokeWidth = .7;
    const spacing = 54.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
