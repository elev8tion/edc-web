import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/services/auth_service.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass.dart';
import '../components/glass_button.dart';
import '../core/widgets/app_snackbar.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.forgotPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() => _emailSent = true);
      } else {
        AppSnackBar.showError(
          context,
          message: AppLocalizations.of(context).forgotPasswordError,
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterEmail;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.pleaseEnterValidEmail;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                      color: AppTheme.goldColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    _emailSent ? l10n.checkYourEmail : l10n.forgotPassword,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 28, minSize: 24, maxSize: 32),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    _emailSent
                        ? l10n.passwordResetEmailSent
                        : l10n.forgotPasswordSubtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  if (!_emailSent) ...[
                    // Form
                    FrostedGlass(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: l10n.email,
                                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.goldColor),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                  borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitForm(),
                            ),

                            const SizedBox(height: 24),

                            GlassButton(
                              text: l10n.sendResetLink,
                              onPressed: _submitForm,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Success state
                    FrostedGlass(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade400,
                            size: 60,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.passwordResetInstructions,
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          GlassButton(
                            text: l10n.backToSignIn,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Back to sign in link (only when form is shown)
                  if (!_emailSent) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.backToSignIn,
                        style: TextStyle(
                          color: AppTheme.goldColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
