import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../../../components/glass_card.dart';
import '../../../utils/responsive_utils.dart';

/// Widget for chat message input with suggestions and controls
class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;
  final VoidCallback? onMicPressed;
  final bool showMicButton;
  final List<String> suggestions;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
    this.onMicPressed,
    this.showMicButton = false,
    this.suggestions = const [],
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _showSuggestions = false;
  String _currentText = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Safety check: don't update state after dispose
    if (!mounted) return;

    final newText = _controller.text;
    setState(() {
      _currentText = newText;
      _showSuggestions = newText.isNotEmpty &&
                        widget.suggestions.isNotEmpty &&
                        _focusNode.hasFocus;
    });

    // Safety check before animation
    if (!mounted) return;
    if (_showSuggestions) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _onFocusChanged() {
    // Safety check: don't update state after dispose
    if (!mounted) return;

    setState(() {
      _showSuggestions = _focusNode.hasFocus &&
                        _currentText.isNotEmpty &&
                        widget.suggestions.isNotEmpty;
    });

    // Safety check before animation
    if (!mounted) return;
    if (_showSuggestions) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onSendMessage(text);
      _controller.clear();
      setState(() {
        _currentText = '';
        _showSuggestions = false;
      });
      _fadeController.reverse();
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _currentText = suggestion;
      _showSuggestions = false;
    });
    _fadeController.reverse();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showSuggestions) _buildSuggestions(),

        _buildInputArea(),
      ],
    );
  }

  Widget _buildSuggestions() {
    final filteredSuggestions = widget.suggestions
        .where((s) => s.toLowerCase().contains(_currentText.toLowerCase()))
        .take(3)
        .toList();

    if (filteredSuggestions.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        child: GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.lightbulb_outline,
                    size: ResponsiveUtils.iconSize(context, 16),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 18),
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...filteredSuggestions.map((suggestion) => _buildSuggestionTile(suggestion)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectSuggestion(suggestion),
        borderRadius: AppRadius.smallRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            suggestion,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 11, maxSize: 21),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 13, maxSize: 24),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share what\'s on your heart...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 13, maxSize: 24),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !widget.isLoading,
                    ),
                  ),

                  if (widget.showMicButton && _currentText.isEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onMicPressed,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic,
                          size: ResponsiveUtils.iconSize(context, 20),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: widget.isLoading ? null : _sendMessage,
            child: Container(
              width: ResponsiveUtils.scaleSize(context, 48, minScale: 0.8, maxScale: 1.5),
              height: ResponsiveUtils.scaleSize(context, 48, minScale: 0.8, maxScale: 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isLoading || _currentText.isEmpty
                      ? [
                          Colors.grey.withValues(alpha: 0.3),
                          Colors.grey.withValues(alpha: 0.2),
                        ]
                      : [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: widget.isLoading || _currentText.isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: ResponsiveUtils.scaleSize(context, 20, minScale: 0.8, maxScale: 1.5),
                        height: ResponsiveUtils.scaleSize(context, 20, minScale: 0.8, maxScale: 1.5),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: Colors.white,
                      size: ResponsiveUtils.iconSize(context, 20),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Predefined suggestion prompts for spiritual guidance
class SpiritualSuggestions {
  static const List<String> commonPrompts = [
    'I\'m feeling anxious about the future',
    'I need guidance for a difficult decision',
    'I\'m struggling with forgiveness',
    'I feel lonely and need encouragement',
    'I\'m going through a tough time',
    'I need strength to overcome a challenge',
    'I\'m dealing with loss and grief',
    'I want to grow closer to God',
    'I\'m facing temptation',
    'I need peace in my heart',
    'I\'m struggling with doubt',
    'I need wisdom for my relationships',
    'I\'m feeling overwhelmed with stress',
    'I want to understand God\'s purpose for my life',
    'I need help with anger and frustration',
    'I\'m dealing with financial worries',
    'I need courage to step out in faith',
    'I\'m struggling with self-worth',
    'I need comfort during illness',
    'I want to deepen my prayer life',
  ];

  static const Map<String, List<String>> categorizedPrompts = {
    'Emotions & Feelings': [
      'I\'m feeling anxious about the future',
      'I feel lonely and need encouragement',
      'I\'m struggling with anger and frustration',
      'I need peace in my heart',
      'I\'m feeling overwhelmed with stress',
    ],
    'Relationships': [
      'I need wisdom for my relationships',
      'I\'m struggling with forgiveness',
      'I need guidance for family issues',
      'I\'m having relationship conflicts',
    ],
    'Faith & Spiritual Growth': [
      'I want to grow closer to God',
      'I\'m struggling with doubt',
      'I want to understand God\'s purpose for my life',
      'I want to deepen my prayer life',
      'I need help understanding Scripture',
    ],
    'Life Challenges': [
      'I\'m going through a tough time',
      'I need strength to overcome a challenge',
      'I\'m dealing with loss and grief',
      'I need guidance for a difficult decision',
      'I\'m dealing with financial worries',
    ],
    'Personal Growth': [
      'I\'m facing temptation',
      'I need courage to step out in faith',
      'I\'m struggling with self-worth',
      'I want to break bad habits',
      'I need help with self-discipline',
    ],
  };

  /// Get suggestions based on current input
  static List<String> getSuggestions(String input) {
    if (input.isEmpty) return commonPrompts.take(5).toList();

    final lowercaseInput = input.toLowerCase();
    return commonPrompts
        .where((prompt) => prompt.toLowerCase().contains(lowercaseInput))
        .take(5)
        .toList();
  }

  /// Get suggestions by category
  static List<String> getSuggestionsByCategory(String category) {
    return categorizedPrompts[category] ?? [];
  }

  /// Get all categories
  static List<String> getCategories() {
    return categorizedPrompts.keys.toList();
  }
}