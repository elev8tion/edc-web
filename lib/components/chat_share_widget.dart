import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Widget that wraps chat messages for branded sharing
/// Includes app branding, logo, and QR code linking to landing page
class ChatShareWidget extends StatelessWidget {
  final List<Widget> messages;
  final String landingPageUrl;
  final Locale locale;
  final AppLocalizations l10n;

  const ChatShareWidget({
    super.key,
    required this.messages,
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

          // Chat messages
          Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: messages,
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                  l10n.aiPoweredBiblicalGuidance,
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
