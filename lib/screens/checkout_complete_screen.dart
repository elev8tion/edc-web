import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../core/navigation/app_routes.dart';
import '../theme/app_theme_extensions.dart';
import '../services/stripe_service.dart';
import '../core/providers/subscription_providers.dart';

class CheckoutCompleteScreen extends ConsumerStatefulWidget {
  const CheckoutCompleteScreen({super.key});

  @override
  ConsumerState<CheckoutCompleteScreen> createState() => _CheckoutCompleteScreenState();
}

class _CheckoutCompleteScreenState extends ConsumerState<CheckoutCompleteScreen> {
  String _statusMessage = 'Verifying checkout...';
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    _handleCheckoutComplete();
  }

  Future<void> _handleCheckoutComplete() async {
    try {
      // CRITICAL: Get session_id from URL query parameters
      // Stripe redirects to: /#/checkout-complete?session_id=cs_xxx
      final uri = Uri.base;
      final sessionId = uri.queryParameters['session_id'];

      debugPrint('[CheckoutComplete] Full URL: ${uri.toString()}');
      debugPrint('[CheckoutComplete] Query parameters: ${uri.queryParameters}');

      if (sessionId == null || sessionId.isEmpty) {
        debugPrint('[CheckoutComplete] ERROR: No session_id in URL');
        _navigateHome(success: false, message: 'No checkout session found');
        return;
      }

      debugPrint('[CheckoutComplete] Verifying session: $sessionId');

      if (mounted) {
        setState(() {
          _statusMessage = 'Verifying payment...';
        });
      }

      // Use stripe_service to verify checkout session
      // This handles ALL the verification and activation logic
      final verificationResult = await verifyCheckoutSession(sessionId);

      if (verificationResult == null) {
        debugPrint('[CheckoutComplete] ERROR: Verification returned null');
        _navigateHome(success: false, message: 'Could not verify checkout');
        return;
      }

      debugPrint('[CheckoutComplete] Verification result: $verificationResult');

      // Check if checkout was completed successfully
      if (verificationResult['status'] == 'complete') {
        // Check if it's a trial or paid subscription
        final trialEnd = verificationResult['trialEnd'];
        final isTrial = trialEnd != null && trialEnd > (DateTime.now().millisecondsSinceEpoch ~/ 1000);

        if (mounted) {
          setState(() {
            _statusMessage = isTrial ? 'Trial activated!' : 'Premium activated!';
          });
        }

        // Give user a moment to see the success message
        await Future.delayed(const Duration(milliseconds: 500));

        final message = isTrial
            ? 'Free trial started! 3 days or 15 messages.'
            : 'Subscription activated! Welcome to Premium.';

        debugPrint('[CheckoutComplete] SUCCESS: $message');
        _navigateHome(success: true, message: message);
      } else {
        debugPrint('[CheckoutComplete] Session not complete: ${verificationResult['status']}');
        _navigateHome(success: false, message: 'Checkout was not completed');
      }
    } catch (e, stackTrace) {
      debugPrint('[CheckoutComplete] ERROR: $e');
      debugPrint('[CheckoutComplete] Stack trace: $stackTrace');
      _navigateHome(success: false, message: 'An error occurred during verification');
    }
  }

  void _navigateHome({required bool success, required String message}) {
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _statusMessage = success ? 'Success!' : 'Error';
    });

    // CRITICAL: Refresh subscription providers BEFORE navigating
    // This ensures the home screen shows the correct premium state
    if (success) {
      ref.invalidate(subscriptionSnapshotProvider);
      debugPrint('[CheckoutComplete] Invalidated subscription providers');
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
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
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isVerifying)
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
