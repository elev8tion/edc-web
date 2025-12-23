import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../core/models/prayer_request.dart';
import '../l10n/app_localizations.dart';

/// Widget that wraps prayer requests for branded sharing
/// Includes app branding, logo, and QR code linking to landing page
class PrayerShareWidget extends StatelessWidget {
  final PrayerRequest prayer;
  final String landingPageUrl;
  final Locale locale;
  final AppLocalizations l10n;

  const PrayerShareWidget({
    super.key,
    required this.prayer,
    required this.locale,
    required this.l10n,
    this.landingPageUrl = 'https://everydaychristian.app',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, // Fixed width for consistent shares
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1f3a),
            Color(0xFF2d1b4e),
            Color(0xFF1a1f3a),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with branding
          _buildHeader(),

          // Prayer content
          _buildPrayerContent(),

          const SizedBox(height: 20),

          // Footer with QR code and branding
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // App logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1f3a),
                  Color(0xFF2d1b4e),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.goldColor,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                locale.languageCode == 'es'
                    ? 'assets/images/logo_spanish.png'
                    : 'assets/images/logo_cropped.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // App name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: AppTheme.textShadowStrong,
                  ),
                ),
                Text(
                  l10n.prayerJournal,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerContent() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: prayer.isAnswered
                    ? [
                        const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      ]
                    : [
                        AppTheme.goldColor.withValues(alpha: 0.3),
                        AppTheme.goldColor.withValues(alpha: 0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: prayer.isAnswered ? const Color(0xFF4CAF50) : AppTheme.goldColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  prayer.isAnswered ? Icons.check_circle : Icons.favorite,
                  size: 16,
                  color: prayer.isAnswered ? const Color(0xFF4CAF50) : AppTheme.goldColor,
                ),
                const SizedBox(width: 6),
                Text(
                  prayer.isAnswered ? l10n.answeredPrayer : l10n.prayerRequest,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: prayer.isAnswered ? const Color(0xFF4CAF50) : AppTheme.goldColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Prayer title
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  prayer.title,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (prayer.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    prayer.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Category indicator
          Text(
            _getCategoryDisplayName(prayer.categoryId),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),

          // Answered description (if applicable)
          if (prayer.isAnswered && prayer.answerDescription != null && prayer.answerDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.howGodAnswered,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prayer.answerDescription!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Call to action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.joinMeInPrayer,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.downloadApp} →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // QR Code
          _buildQRCode(),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.goldColor,
          width: 2,
        ),
      ),
      child: QrImageView(
        data: landingPageUrl,
        version: QrVersions.auto,
        size: 80,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppTheme.primaryColor,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppTheme.primaryColor,
        ),
        embeddedImage: AssetImage(
          locale.languageCode == 'es'
              ? 'assets/images/logo_spanish.png'
              : 'assets/images/logo_cropped.png',
        ),
        embeddedImageStyle: const QrEmbeddedImageStyle(
          size: Size(24, 24),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String categoryId) {
    // Map category IDs to localized display names
    final categoryNames = {
      'cat_family': l10n.family,
      'cat_health': l10n.health,
      'cat_work': l10n.work,
      'cat_ministry': l10n.ministry,
      'cat_thanksgiving': l10n.thanksgiving,
      'cat_intercession': l10n.intercession,
      'cat_finances': l10n.finances,
      'cat_relationships': l10n.relationships,
      'cat_guidance': l10n.guidance,
      'cat_protection': l10n.protection,
      'cat_general': l10n.general,
    };
    return categoryNames[categoryId] ?? categoryId;
  }
}