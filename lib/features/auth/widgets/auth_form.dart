import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/frosted_glass.dart';
import '../../../components/glass_button.dart';
import '../../../components/dark_glass_container.dart';
import '../../../core/services/preferences_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme_extensions.dart';

class AuthForm extends ConsumerStatefulWidget {
  final VoidCallback? onForgotPassword;

  const AuthForm({
    super.key,
    this.onForgotPassword,
  });

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Legal agreement checkboxes (for signup only)
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _ageChecked = false;

  bool get _canSignUp => _termsChecked && _privacyChecked && _ageChecked;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // For signup, ensure all legal checkboxes are checked
    if (_isSignUp && !_canSignUp) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider.notifier);

    bool success;
    if (_isSignUp) {
      success = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        preferredThemes: ['hope', 'strength', 'comfort'],
      );

      // Save legal agreements AFTER successful signup
      if (success) {
        final prefsService = await PreferencesService.getInstance();
        await prefsService.saveLegalAgreementAcceptance(true);
        await prefsService.setOnboardingCompleted();
      }
    } else {
      success = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Success is handled by the auth state listener in AuthScreen
    }
  }

  Future<void> _openLegalDoc(String type) async {
    final url = type == 'terms'
        ? 'https://everydaychristian.app/terms'
        : 'https://everydaychristian.app/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
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

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }
    if (value.length < 6) {
      return l10n.passwordMinLength;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FrostedGlass(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle between sign in and sign up
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = false),
                    style: TextButton.styleFrom(
                      backgroundColor: !_isSignUp
                          ? AppTheme.goldColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                    ),
                    child: Text(
                      l10n.signIn,
                      style: TextStyle(
                        color: !_isSignUp ? AppTheme.goldColor : Colors.white.withValues(alpha: 0.7),
                        fontWeight: !_isSignUp ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = true),
                    style: TextButton.styleFrom(
                      backgroundColor: _isSignUp
                          ? AppTheme.goldColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                    ),
                    child: Text(
                      l10n.signUp,
                      style: TextStyle(
                        color: _isSignUp ? AppTheme.goldColor : Colors.white.withValues(alpha: 0.7),
                        fontWeight: _isSignUp ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Name field (only for sign up - OPTIONAL)
            if (_isSignUp) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.firstNameOptional,
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.goldColor),
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
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
            ],

            // Email field
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
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.password,
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.goldColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.goldColor,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.buttonRadius,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.buttonRadius,
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: !_isPasswordVisible,
              validator: _validatePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitForm(),
            ),

            // Forgot password link (only for sign in)
            if (!_isSignUp) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.forgotPassword,
                    style: TextStyle(
                      color: AppTheme.goldColor.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Legal agreements (only for sign up)
            if (_isSignUp) ...[
              const SizedBox(height: 20),

              // Terms of Service
              _buildCheckboxRow(
                value: _termsChecked,
                onChanged: (value) {
                  setState(() => _termsChecked = value ?? false);
                  HapticFeedback.selectionClick();
                },
                label: l10n.acceptTermsOfService,
                onViewTapped: () => _openLegalDoc('terms'),
                l10n: l10n,
              ),
              const SizedBox(height: 8),

              // Privacy Policy
              _buildCheckboxRow(
                value: _privacyChecked,
                onChanged: (value) {
                  setState(() => _privacyChecked = value ?? false);
                  HapticFeedback.selectionClick();
                },
                label: l10n.acceptPrivacyPolicy,
                onViewTapped: () => _openLegalDoc('privacy'),
                l10n: l10n,
              ),
              const SizedBox(height: 8),

              // Age confirmation
              _buildCheckboxRow(
                value: _ageChecked,
                onChanged: (value) {
                  setState(() => _ageChecked = value ?? false);
                  HapticFeedback.selectionClick();
                },
                label: l10n.confirmAge13Plus,
                l10n: l10n,
              ),

              const SizedBox(height: 16),

              // Crisis resources (collapsible)
              DarkGlassContainer(
                child: ExpansionTile(
                  title: Row(
                    children: [
                      const Icon(Icons.health_and_safety,
                          color: AppTheme.goldColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.crisisResources,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  iconColor: AppColors.primaryText,
                  collapsedIconColor: AppColors.secondaryText,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    Text(
                      l10n.crisisResourcesText,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            GlassButton(
              text: _isSignUp ? l10n.createAccount : l10n.signIn,
              onPressed: (_isSignUp && !_canSignUp) ? null : _submitForm,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 16),

            // Biometric sign in (only for sign in mode)
            if (!_isSignUp) ...[
              Consumer(
                builder: (context, ref, child) {
                  return FutureBuilder<bool>(
                    future: ref.read(authServiceProvider.notifier).isBiometricEnabled(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    l10n.or,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(authServiceProvider.notifier).signIn(
                                  email: '',
                                  password: '',
                                  useBiometric: true,
                                );
                              },
                              icon: const Icon(Icons.fingerprint, color: AppTheme.primaryColor),
                              label: Text(
                                l10n.useBiometric,
                                style: const TextStyle(color: AppTheme.primaryColor),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required String label,
    VoidCallback? onViewTapped,
    required AppLocalizations l10n,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.goldColor,
            checkColor: Colors.white,
            side: BorderSide(
              color: value ? AppTheme.goldColor : Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
              if (onViewTapped != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onViewTapped,
                  child: Text(
                    l10n.view,
                    style: const TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
