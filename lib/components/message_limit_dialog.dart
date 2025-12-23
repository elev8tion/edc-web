/// Message Limit Dialog
/// Shows when user hits their daily (trial) or monthly (premium) message limit
/// Provides options to subscribe or continue later

import 'package:flutter/material.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/blur_dialog_utils.dart';

class MessageLimitDialog extends StatelessWidget {
  final bool isPremium;
  final int remainingMessages;
  final VoidCallback onSubscribePressed;
  final VoidCallback onMaybeLaterPressed;

  const MessageLimitDialog({
    Key? key,
    required this.isPremium,
    required this.remainingMessages,
    required this.onSubscribePressed,
    required this.onMaybeLaterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.maxContentWidth(context) * 0.9,
        ),
        child: FrostedGlassCard(
          intensity: GlassIntensity.strong,
          borderColor: AppTheme.goldColor.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldColor.withValues(alpha: 0.3),
                        AppTheme.goldColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: ResponsiveUtils.iconSize(context, 36),
                    color: AppTheme.goldColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  isPremium ? 'Monthly Limit Reached' : 'Trial Limit Reached',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 24, minSize: 20, maxSize: 28),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // Message
                Text(
                  isPremium
                      ? 'You\'ve used all 150 messages this month.\nUpgrade your plan or wait for the monthly reset.'
                      : 'You\'ve used all 15 trial messages.\nSubscribe now for 150 messages per month!',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Subscribe button
                GlassButton(
                  text: isPremium ? 'Upgrade Plan' : 'Subscribe Now',
                  onPressed: onSubscribePressed,
                ),
                const SizedBox(height: AppSpacing.md),

                // Maybe Later button
                GestureDetector(
                  onTap: onMaybeLaterPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show message limit dialog
  static Future<bool?> show({
    required BuildContext context,
    required bool isPremium,
    required int remainingMessages,
  }) {
    return showBlurredDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MessageLimitDialog(
        isPremium: isPremium,
        remainingMessages: remainingMessages,
        onSubscribePressed: () {
          Navigator.of(context).pop(true); // Return true = user wants to subscribe
        },
        onMaybeLaterPressed: () {
          Navigator.of(context).pop(false); // Return false = user declined
        },
      ),
    );
  }
}
