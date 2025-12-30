/// Offline Preparation Overlay
///
/// Shows a non-blocking notification during offline asset download.
/// Appears as a small banner at the bottom of the screen.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/services/offline_preparation_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// Overlay that shows offline preparation progress
///
/// Wrap your main app content with this widget to show
/// download progress for offline assets.
class OfflinePreparationOverlay extends StatefulWidget {
  final Widget child;

  const OfflinePreparationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<OfflinePreparationOverlay> createState() => _OfflinePreparationOverlayState();
}

class _OfflinePreparationOverlayState extends State<OfflinePreparationOverlay>
    with SingleTickerProviderStateMixin {
  final OfflinePreparationService _service = OfflinePreparationService();
  StreamSubscription<OfflineProgress>? _subscription;

  OfflineProgress? _currentProgress;
  bool _isVisible = false;
  bool _isDismissed = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (kIsWeb) {
      _startPreparation();
    }
  }

  void _startPreparation() async {
    // Small delay to let the app settle
    await Future.delayed(const Duration(seconds: 2));

    _subscription = _service.progressStream.listen((progress) {
      if (!mounted || _isDismissed) return;

      setState(() {
        _currentProgress = progress;
      });

      // Show banner when downloading starts
      if (progress.status == OfflineStatus.downloading && !_isVisible) {
        setState(() => _isVisible = true);
        _animationController.forward();
      }

      // Hide after completion or error (with delay)
      if (progress.status == OfflineStatus.complete ||
          progress.status == OfflineStatus.error) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isDismissed) {
            _dismiss();
          }
        });
      }
    });

    _service.startPreparation();
  }

  void _dismiss() {
    setState(() => _isDismissed = true);
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible && _currentProgress != null)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBanner(context),
            ),
          ),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    final progress = _currentProgress!;
    final isComplete = progress.status == OfflineStatus.complete;
    final isError = progress.status == OfflineStatus.error;

    return Container(
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.maxContentWidth(context),
      ),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.shade900.withValues(alpha: 0.95)
            : isComplete
                ? Colors.green.shade900.withValues(alpha: 0.95)
                : const Color(0xFF1E1E2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.5)
              : isComplete
                  ? Colors.green.withValues(alpha: 0.5)
                  : AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red.withValues(alpha: 0.2)
                          : isComplete
                              ? Colors.green.withValues(alpha: 0.2)
                              : AppTheme.goldColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError
                          ? Icons.error_outline
                          : isComplete
                              ? Icons.cloud_done
                              : Icons.cloud_download_outlined,
                      size: 20,
                      color: isError
                          ? Colors.red.shade300
                          : isComplete
                              ? Colors.green.shade300
                              : AppTheme.goldColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isComplete
                              ? 'Offline Ready'
                              : isError
                                  ? 'Offline Setup Failed'
                                  : 'Preparing Offline Mode',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progress.message,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dismiss button
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar (only when downloading)
            if (!isComplete && !isError)
              LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.goldColor,
                ),
                minHeight: 3,
              ),
          ],
        ),
      ),
    );
  }
}
