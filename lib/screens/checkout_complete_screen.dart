import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../core/navigation/app_routes.dart';

class CheckoutCompleteScreen extends StatefulWidget {
  const CheckoutCompleteScreen({super.key});

  @override
  State<CheckoutCompleteScreen> createState() => _CheckoutCompleteScreenState();
}

class _CheckoutCompleteScreenState extends State<CheckoutCompleteScreen> {
  @override
  void initState() {
    super.initState();
    _handleCheckoutComplete();
  }

  Future<void> _handleCheckoutComplete() async {
    // Small delay to ensure navigation context is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Navigate to home with success message
    // The subscription was already saved via onComplete callback before redirect
    // This screen just needs to gracefully return to the app
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );

    // Show success message after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated! Welcome to Premium.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.goldColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Completing checkout...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
