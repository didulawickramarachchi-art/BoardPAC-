import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class Verify2FAScreen extends ConsumerStatefulWidget {
  const Verify2FAScreen({super.key});

  @override
  ConsumerState<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends ConsumerState<Verify2FAScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the six-digit code.')),
      );
      return;
    }
    final success = await ref
        .read(authProvider.notifier)
        .verifyCode(_codeController.text.trim());

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Stack(
        children: [
          const Positioned(
            top: -130,
            right: -100,
            child: _AmbientOrb(size: 330, color: Color(0xFF2458C4)),
          ),
          const Positioned(
            bottom: -150,
            left: -100,
            child: _AmbientOrb(size: 340, color: Color(0xFFFFB52E)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Back to sign in',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/images/slpa_logo.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppColors.navy,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Check your email',
                          style: TextStyle(
                            color: AppColors.navyDark,
                            fontSize: 27,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Enter the six-digit security code we sent to your registered email address.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        AppTextField(
                          controller: _codeController,
                          hintText: '000000',
                          labelText: 'Security code',
                          prefixIcon: const Icon(Icons.password_rounded),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofocus: true,
                          onSubmitted: (_) =>
                              state.isLoading ? null : _verify(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Verify and continue',
                          icon: Icons.verified_user_outlined,
                          onPressed: _verify,
                          isLoading: state.isLoading,
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 19,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 15,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Secure identity verification',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: .34), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
