import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../theme/app_theme.dart';
import '../components/glass_button.dart';
import '../widgets/noise_overlay.dart';

/// Custom payment bottom sheet with Stripe CardField
/// Matches app's glassmorphism design (BaseBottomSheet style)
///
/// Used for collecting card details for subscription trials and direct purchases.
/// Features:
/// - BackdropFilter for proper glass blur
/// - Dual-shadow technique for depth
/// - Static noise overlay for texture
/// - Light simulation via foreground gradient
class PaymentBottomSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final Future<void> Function(CardFieldInputDetails) onConfirm;

  const PaymentBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onConfirm,
  });

  /// Show the payment bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String buttonText,
    required Future<void> Function(CardFieldInputDetails) onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentBottomSheet(
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  CardFieldInputDetails? _cardDetails;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isCardComplete => _cardDetails?.complete ?? false;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.vertical(top: Radius.circular(AppRadius.xxl));

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Dual shadows matching BaseBottomSheet
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, -10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, -4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      // Light simulation
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5],
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: StaticNoiseOverlay(
          opacity: 0.04,
          density: 0.4,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
                      const Color(0xFF0F172A).withValues(alpha: 0.98), // Slate-900
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Subtitle
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Card Field Container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: AppRadius.mediumRadius,
                            border: Border.all(
                              color: _errorMessage != null
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: AppRadius.mediumRadius,
                            child: CardField(
                              onCardChanged: (details) {
                                setState(() {
                                  _cardDetails = details;
                                  _errorMessage = null;
                                });
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                              // CardField uses TextStyle for styling
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              cursorColor: AppTheme.goldColor,
                            ),
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Security note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Secured by Stripe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Confirm Button
                        GlassButton(
                          text: _isLoading ? 'Processing...' : widget.buttonText,
                          isLoading: _isLoading,
                          borderColor: AppTheme.goldColor,
                          onPressed: _isCardComplete && !_isLoading
                              ? () => _handleConfirm()
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Cancel Button
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    if (_cardDetails == null || !_cardDetails!.complete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm(_cardDetails!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
}
