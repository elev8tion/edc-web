import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../core/navigation/app_routes.dart';
import '../theme/app_theme_extensions.dart';
import '../core/services/subscription_service.dart';

class CheckoutCompleteScreen extends StatefulWidget {
  const CheckoutCompleteScreen({super.key});

  @override
  State<CheckoutCompleteScreen> createState() => _CheckoutCompleteScreenState();
}

class _CheckoutCompleteScreenState extends State<CheckoutCompleteScreen> {
  String _statusMessage = 'Verifying checkout...';
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    _handleCheckoutComplete();
  }

  Future<void> _handleCheckoutComplete() async {
    try {
      // Get session_id from URL parameters
      final uri = Uri.base;
      final sessionId = uri.queryParameters['session_id'];

      if (sessionId == null || sessionId.isEmpty) {
        debugPrint('[CheckoutComplete] No session_id in URL');
        _navigateHome(success: false, message: 'No checkout session found');
        return;
      }

      debugPrint('[CheckoutComplete] Verifying session: $sessionId');

      if (mounted) {
        setState(() {
          _statusMessage = 'Verifying payment...';
        });
      }

      // Verify the checkout session
      const workerUrl =
          'https://edc-stripe-subscription.connect-2a2.workers.dev';
      final response = await http.post(
        Uri.parse('$workerUrl/verify-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'complete') {
          if (mounted) {
            setState(() {
              _statusMessage = 'Activating subscription...';
            });
          }

          // Activate premium
          final subscriptionService = SubscriptionService.instance;
          await subscriptionService.activateFromStripe(
            subscriptionId: data['subscriptionId'] ?? '',
            customerId: data['customerId'] ?? '',
            trialEnd: data['trialEnd'],
            currentPeriodEnd: data['currentPeriodEnd'],
            isYearly: true, // Default to yearly
          );

          debugPrint('[CheckoutComplete] Premium activated successfully');
          _navigateHome(
              success: true, message: 'Subscription activated! Welcome to Premium.');
        } else {
          debugPrint('[CheckoutComplete] Session not complete: ${data['status']}');
          _navigateHome(success: false, message: 'Checkout was not completed');
        }
      } else {
        debugPrint('[CheckoutComplete] Verify failed: ${response.statusCode}');
        _navigateHome(success: false, message: 'Could not verify checkout');
      }
    } catch (e) {
      debugPrint('[CheckoutComplete] Error: $e');
      _navigateHome(success: false, message: 'An error occurred');
    }
  }

  void _navigateHome({required bool success, required String message}) {
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _statusMessage = success ? 'Success!' : 'Error';
    });

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
            duration: const Duration(seconds: 3),
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
