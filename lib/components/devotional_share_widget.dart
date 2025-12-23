import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../core/models/devotional.dart';
import '../l10n/app_localizations.dart';

/// Widget that wraps devotionals for branded sharing
/// Includes app branding, logo, and QR code linking to landing page
class DevotionalShareWidget extends StatelessWidget {
  final Devotional devotional;
  final String landingPageUrl;
  final bool showFullReflection;
  final Locale locale;
  final AppLocalizations l10n;

  const DevotionalShareWidget({
    super.key,
    required this.devotional,
    required this.locale,
    required this.l10n,
    this.landingPageUrl = 'https://everydaychristian.app',
    this.showFullReflection = false,
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

          // Devotional content
          _buildDevotionalContent(),

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
                  l10n.dailyDevotional,
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

  Widget _buildDevotionalContent() {
    final DateTime date = DateTime.parse(devotional.date);
    final String formattedDate = DateFormat('EEEE, MMMM d, y').format(date);

    // Truncate reflection if not showing full
    String reflectionText = devotional.reflection;
    if (!showFullReflection && reflectionText.length > 200) {
      reflectionText = '${reflectionText.substring(0, 200)}...';
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.3),
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.goldColor,
                  width: 1,
                ),
              ),
              child: Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              devotional.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Key verse
            Container(
              padding: const EdgeInsets.all(16),
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
                  // Verse reference
                  Text(
                    devotional.keyVerseReference,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.goldColor.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Verse text
                  Text(
                    '"${devotional.keyVerseText}"',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reflection preview
            Text(
              reflectionText,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
              maxLines: showFullReflection ? null : 6,
              overflow: showFullReflection ? null : TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Reading time indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  devotional.readingTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  l10n.getApp,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.scanToDownload} →',
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
}
