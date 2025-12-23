import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/frosted_glass.dart';
import '../../../components/glass_button.dart';

class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({super.key});

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (_isSignUp && (value == null || value.trim().isEmpty)) {
      return 'Please enter your name';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                      'Sign In',
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
                      'Sign Up',
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

            // Name field (only for sign up)
            if (_isSignUp) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
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
                validator: _validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
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
                labelText: 'Password',
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

            const SizedBox(height: 24),

            // Submit button
            GlassButton(
              text: _isSignUp ? 'Create Account' : 'Sign In',
              onPressed: _submitForm,
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
                                    'or',
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
                              label: const Text(
                                'Use Biometric',
                                style: TextStyle(color: AppTheme.primaryColor),
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

            // Additional options for sign up
            if (_isSignUp) ...[
              const SizedBox(height: 16),
              Text(
                'By creating an account, you agree to keep your spiritual journey private and secure.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}