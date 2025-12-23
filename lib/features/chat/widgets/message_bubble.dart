import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/chat_message.dart';
import '../../../models/bible_verse.dart';
import '../../../theme/app_theme.dart';
import '../../../components/base_bottom_sheet.dart';
import '../../../components/glass_card.dart';
import 'verse_card.dart';

/// Widget that displays a single chat message in a bubble
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onLongPress;
  final Function(BibleVerse)? onVersePressed;
  final VoidCallback? onRegenerateResponse;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = false,
    this.onLongPress,
    this.onVersePressed,
    this.onRegenerateResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser && showAvatar) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context),

                if (message.hasVerses) ...[
                  const SizedBox(height: 8),
                  _buildVerseCards(context),
                ],

                if (showTimestamp) ...[
                  const SizedBox(height: 4),
                  _buildTimestamp(context),
                ],
              ],
            ),
          ),

          if (message.isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        color: message.isUser
            ? AppTheme.primaryColor.withValues(alpha: 0.3)
            : Colors.deepPurple.withValues(alpha: 0.3),
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isSystem) ...[
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'System Message',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Text(
              message.content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
              maxLines: 500,
              overflow: TextOverflow.visible,
            ),

            if (message.status == MessageStatus.sending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sending...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],

            if (message.status == MessageStatus.failed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 12,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Failed to send',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerseCards(BuildContext context) {
    return Column(
      children: message.verses.map((verse) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: VerseCard(
          verse: verse,
          onTap: () => onVersePressed?.call(verse),
          compact: true,
        ),
      )).toList(),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Text(
      message.formattedTime,
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.5),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showMessageOptions(BuildContext context) {
    HapticFeedback.mediumImpact();

    showCustomBottomSheet(
      context: context,
      showHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

            _buildOptionTile(
              context,
              icon: Icons.copy,
              title: 'Copy Message',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.goldColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Message copied to clipboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            if (message.hasVerses) ...[
              _buildOptionTile(
                context,
                icon: Icons.book,
                title: 'Copy Verses',
                onTap: () {
                  final versesText = message.verses
                      .map((v) => '${v.reference}: ${v.text}')
                      .join('\n\n');
                  Clipboard.setData(ClipboardData(text: versesText));
                  Navigator.pop(context);
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
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.goldColor,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Verses copied to clipboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            _buildOptionTile(
              context,
              icon: Icons.share,
              title: 'Share Message',
              onTap: () {
                Navigator.pop(context);
                _shareMessage(context);
              },
            ),

            if (message.isAI && onRegenerateResponse != null) ...[
              _buildOptionTile(
                context,
                icon: Icons.refresh,
                title: 'Regenerate Response',
                onTap: () {
                  Navigator.pop(context);
                  onRegenerateResponse?.call();
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

  void _shareMessage(BuildContext context) {
    String shareText = message.content;

    if (message.hasVerses) {
      shareText += '\n\nBible Verses:\n';
      for (final verse in message.verses) {
        shareText += '\n${verse.reference}: ${verse.text}';
      }
    }

    shareText += '\n\nShared from Everyday Christian App';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
      ),
    );
  }
}

/// Widget for typing indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
              color: Colors.deepPurple.withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),

          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI is thinking',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final value = (_animation.value - delay).clamp(0.0, 1.0);
                        final opacity = (Curves.easeInOut.transform(value) * 0.8) + 0.2;

                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          child: Opacity(
                            opacity: opacity,
                            child: const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
