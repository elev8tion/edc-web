/// Chat Screen Lockout Overlay
/// Displays when:
/// 1. Trial has expired or premium subscription has ended
/// 2. User is suspended for Terms of Service violations
/// Prevents viewing chat history and sending messages

import 'package:flutter/material.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

enum LockoutReason {
  trialExpired,    // Trial period ended
  premiumExpired,  // Subscription expired
  suspended,       // Account suspended for violations
}

class ChatScreenLockoutOverlay extends StatelessWidget {
  final VoidCallback onSubscribePressed;
  final LockoutReason reason;
  final String? suspensionMessage; // For suspension: custom message with end date
  final Duration? remainingSuspension; // For suspension: remaining time

  const ChatScreenLockoutOverlay({
    Key? key,
    required this.onSubscribePressed,
    this.reason = LockoutReason.trialExpired,
    this.suspensionMessage,
    this.remainingSuspension,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Full screen overlay with blur effect
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.maxContentWidth(context) * 0.9,
              ),
              child: FrostedGlassCard(
                intensity: GlassIntensity.strong,
                borderColor: AppTheme.goldColor.withValues(alpha: 0.6),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon (Lock for subscription, Warning for suspension)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: reason == LockoutReason.suspended
                                ? [
                                    Colors.orange.withValues(alpha: 0.3),
                                    Colors.orange.withValues(alpha: 0.1),
                                  ]
                                : [
                                    AppTheme.goldColor.withValues(alpha: 0.3),
                                    AppTheme.goldColor.withValues(alpha: 0.1),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: reason == LockoutReason.suspended
                                ? Colors.orange.withValues(alpha: 0.5)
                                : AppTheme.goldColor.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          reason == LockoutReason.suspended
                              ? Icons.warning_amber_rounded
                              : Icons.lock_outline,
                          size: ResponsiveUtils.iconSize(context, 50),
                          color: reason == LockoutReason.suspended
                              ? Colors.orange
                              : AppTheme.goldColor,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.xl)),

                      // Title
                      Text(
                        _getTitle(),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 28, minSize: 24, maxSize: 32),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.lg)),

                      // Message
                      Text(
                        _getMessage(),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                          color: AppColors.secondaryText,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.xxl)),

                      // Conditional content based on lockout reason
                      if (reason == LockoutReason.suspended) ...[
                        // Suspension countdown badge
                        if (remainingSuspension != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Time Remaining: ${_formatDuration(remainingSuspension!)}',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                                color: Colors.orange.shade200,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.lg)),

                        // Contact support text
                        Text(
                          'If you believe this suspension was issued in error, please contact:',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
                            color: AppColors.tertiaryText,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.xs)),
                        Text(
                          'connect@everydaychristian.app',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        // Benefits list (for subscription lockout)
                        _buildBenefitItem(
                          context,
                          icon: Icons.chat_bubble_outline,
                          text: '150 AI messages per month',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.md)),
                        _buildBenefitItem(
                          context,
                          icon: Icons.history,
                          text: 'Access to all your chat history',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.md)),
                        _buildBenefitItem(
                          context,
                          icon: Icons.auto_awesome,
                          text: 'Personalized Biblical guidance',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.xxl)),

                        // Subscribe button
                        GlassButton(
                          text: 'Subscribe Now',
                          onPressed: onSubscribePressed,
                        ),
                      ],
                      SizedBox(height: ResponsiveUtils.spacing(context, AppSpacing.lg)),

                      // Info text
                      Text(
                        'Prayer journal, Bible reading, and verses remain free and unlimited',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                          color: AppColors.tertiaryText,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (reason) {
      case LockoutReason.suspended:
        return 'Account Suspended';
      case LockoutReason.trialExpired:
      case LockoutReason.premiumExpired:
        return 'Premium\nScripture Chat';
    }
  }

  String _getMessage() {
    switch (reason) {
      case LockoutReason.suspended:
        return suspensionMessage ??
            'Your AI chat access has been temporarily suspended due to Terms of Service violations. '
            'Your subscription remains active and all other features are available.';
      case LockoutReason.trialExpired:
        return 'Your free trial has ended. Subscribe to view your chat history and continue conversations '
            'with AI-powered Biblical guidance.';
      case LockoutReason.premiumExpired:
        return 'Subscribe to view your chat history and continue conversations with AI-powered Biblical guidance.';
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildBenefitItem(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: ResponsiveUtils.iconSize(context, 20),
            color: AppTheme.goldColor,
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, AppSpacing.md)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
