import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/bible_verse.dart';
import '../../../theme/app_theme.dart';
import '../../../components/glass_card.dart';
import '../../../components/category_badge.dart';
import '../../../utils/responsive_utils.dart';

/// Beautiful card widget for displaying Bible verses
class VerseCard extends StatelessWidget {
  final BibleVerse verse;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final bool showActions;

  const VerseCard({
    super.key,
    required this.verse,
    this.compact = false,
    this.onTap,
    this.onBookmark,
    this.isBookmarked = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: compact ? 16 : 20,
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),

            SizedBox(height: compact ? 8 : 12),

            _buildVerseText(context),

            if (!compact) ...[
              const SizedBox(height: 12),
              _buildThemes(context),
            ],

            if (showActions) ...[
              SizedBox(height: compact ? 8 : 12),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: AppRadius.smallRadius,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            verse.translation,
            style: TextStyle(
              fontSize: compact
                ? ResponsiveUtils.fontSize(context, 10, minSize: 8, maxSize: 15)
                : ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 16),
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            verse.reference,
            style: TextStyle(
              fontSize: compact
                ? ResponsiveUtils.fontSize(context, 14, minSize: 11, maxSize: 21)
                : ResponsiveUtils.fontSize(context, 16, minSize: 13, maxSize: 24),
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        if (verse.isPopular) ...[
          Icon(
            Icons.star,
            size: compact
              ? ResponsiveUtils.iconSize(context, 16)
              : ResponsiveUtils.iconSize(context, 18),
            color: Colors.amber,
          ),
        ],
      ],
    );
  }

  Widget _buildVerseText(BuildContext context) {
    return Text(
      verse.text,
      style: TextStyle(
        fontSize: compact
          ? ResponsiveUtils.fontSize(context, 14, minSize: 11, maxSize: 21)
          : ResponsiveUtils.fontSize(context, 16, minSize: 13, maxSize: 24),
        height: 1.5,
        color: Colors.white,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildThemes(BuildContext context) {
    if (verse.themes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: verse.themes.take(4).map((theme) => CategoryBadge(
        text: theme,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        fontSize: 11,
      )).toList(),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          context,
          icon: Icons.copy,
          label: compact ? null : 'Copy',
          onTap: () => _copyVerse(context),
        ),

        const SizedBox(width: 8),

        _buildActionButton(
          context,
          icon: Icons.share,
          label: compact ? null : 'Share',
          onTap: () => _shareVerse(context),
        ),

        if (onBookmark != null) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: compact ? null : (isBookmarked ? 'Saved' : 'Save'),
            onTap: onBookmark!,
            isSelected: isBookmarked,
          ),
        ],

        const Spacer(),

        Text(
          '${verse.length.emoji} ${compact ? '' : verse.length.description.split(' ').first}',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 10, minSize: 8, maxSize: 15),
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 8 : 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: AppRadius.smallRadius,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.iconSize(context, 14),
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.7),
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 16),
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyVerse(BuildContext context) {
    final text = '${verse.reference}: ${verse.text}';
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B), // slate-800
                Color(0xFF0F172A), // slate-900
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.goldColor,
                size: ResponsiveUtils.iconSize(context, 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verse copied to clipboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 11, maxSize: 21),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareVerse(BuildContext context) {
    final text = '''${verse.reference}

"${verse.text}"

${verse.translation}

Shared from Everyday Christian App''';

    SharePlus.instance.share(
      ShareParams(
        text: text,
      ),
    );
  }
}

/// Compact verse card for use in lists or grids
class CompactVerseCard extends StatelessWidget {
  final BibleVerse verse;
  final VoidCallback? onTap;

  const CompactVerseCard({
    super.key,
    required this.verse,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    verse.reference,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 18),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (verse.isPopular)
                  Icon(
                    Icons.star,
                    size: ResponsiveUtils.iconSize(context, 12),
                    color: Colors.amber,
                  ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              verse.text.length > 80
                  ? '${verse.text.substring(0, 77)}...'
                  : verse.text,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 16),
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            if (verse.themes.isNotEmpty)
              CategoryBadge(
                text: verse.primaryTheme,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                fontSize: 9,
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable verse collection
class VerseCollection extends StatelessWidget {
  final String title;
  final List<BibleVerse> verses;
  final Function(BibleVerse)? onVerseSelected;

  const VerseCollection({
    super.key,
    required this.title,
    required this.verses,
    this.onVerseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 18, minSize: 14, maxSize: 27),
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: CompactVerseCard(
                  verse: verse,
                  onTap: () => onVerseSelected?.call(verse),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
