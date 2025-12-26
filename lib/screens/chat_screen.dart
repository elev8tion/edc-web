import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/app_theme.dart';
import '../core/providers/app_providers.dart';
import '../models/chat_message.dart';
import '../providers/ai_provider.dart';
import '../components/gradient_background.dart';
import '../components/base_bottom_sheet.dart';
import '../components/glass_effects/glass_dialog.dart';
import '../components/glass_card.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../utils/blur_dialog_utils.dart';
import '../components/scroll_to_bottom.dart';
import '../components/is_typing_indicator.dart';
import '../components/time_and_status.dart';
import '../services/conversation_service.dart';
import '../services/gemini_ai_service.dart';
import '../core/services/crisis_detection_service.dart';
import '../core/services/content_filter_service.dart';
import '../core/widgets/crisis_dialog.dart';
import '../utils/responsive_utils.dart';
import 'paywall_screen.dart';
import '../components/message_limit_dialog.dart';
import '../components/chat_screen_lockout_overlay.dart';
import '../components/progress_ring_send_button.dart';
import '../components/floating_message_badge.dart';
import '../core/services/subscription_service.dart';
import '../components/chat_action_buttons_header.dart';
import '../components/verse_context_message.dart';
import '../core/widgets/app_snackbar.dart';
import '../services/chat_share_service.dart';
import '../l10n/app_localizations.dart';
import '../models/verse_context.dart';

class ChatScreen extends HookConsumerWidget {
  final VerseContext?
      verseContext; // Optional verse context for verse discussion

  const ChatScreen({
    super.key,
    this.verseContext,
  });

  ChatMessage _createWelcomeMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ChatMessage.system(
      content: '${l10n.peaceBeWithYou}\n\n${l10n.chatWelcomeMessage}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final messages = useState<List<ChatMessage>>([]);
    final isTyping = useState(false);
    final isStreaming = useState(false);
    final isStreamingComplete = useState(false);
    final streamedText = useState('');
    final sessionId = useState<String?>(null);
    final conversationService = useMemoized(() => ConversationService());
    final canSend = useState(false);
    final showScrollToBottom = useState(false);
    final hasAddedVerseContext =
        useState(false); // Track if verse context was prepended to AI
    final regeneratedMessageId = useState<String?>(
        null); // Track which message was just regenerated for animation

    // Listen to text changes to update send button state
    useEffect(() {
      void listener() {
        canSend.value = messageController.text.trim().isNotEmpty;
      }

      messageController.addListener(listener);
      return () => messageController.removeListener(listener);
    }, [messageController]);

    // Listen to scroll position to show/hide scroll to bottom button
    useEffect(() {
      void listener() {
        if (scrollController.hasClients) {
          final maxScroll = scrollController.position.maxScrollExtent;
          final currentScroll = scrollController.position.pixels;
          // Show button if scrolled up more than 200 pixels from bottom
          showScrollToBottom.value = (maxScroll - currentScroll) > 200;
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    // Watch AI service initialization state
    final aiServiceState = ref.watch(aiServiceStateProvider);

    // Watch connectivity status
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    // Initialize session and load messages from database
    useEffect(() {
      Future<void> initializeSession() async {
        try {
          debugPrint('🔄 Initializing chat session...');

          // Always start with a fresh session (old sessions accessible via history)
          debugPrint('🆕 Creating fresh session');
          final newSessionId = await conversationService.createSession(
            title: verseContext != null
                ? l10n.discussingVerse(verseContext!.reference)
                : l10n.newConversation,
          );
          sessionId.value = newSessionId;
          debugPrint('✅ Created new session: $newSessionId');

          // Only add welcome message if NOT navigated from verse
          if (verseContext == null) {
            final welcomeMessage = ChatMessage.system(
              content: '${l10n.peaceBeWithYou}\n\n${l10n.chatWelcomeMessage}',
              sessionId: newSessionId,
            );
            await conversationService.saveMessage(welcomeMessage);
            messages.value = [welcomeMessage];
            debugPrint('✅ New session initialized with welcome message');
          } else {
            // For verse discussions, start with empty messages (verse context shows separately)
            messages.value = [];
            debugPrint(
                '✅ New verse discussion session initialized: ${verseContext!.reference}');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Failed to initialize session: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          // Fallback to in-memory
          if (verseContext == null) {
            // ignore: use_build_context_synchronously
            messages.value = [_createWelcomeMessage(context)];
          } else {
            messages.value = [];
          }
          debugPrint('⚠️ Using in-memory fallback mode');
        }
      }

      initializeSession();
      return null;
    }, []);

    // Auto-scroll when messages change
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [messages.value]);

    void scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    Future<void> sendMessage(String text) async {
      if (text.trim().isEmpty) return;

      // Check connectivity before sending (chat requires internet)
      final connectivityAsync = ref.read(connectivityStatusProvider);
      final isConnected = connectivityAsync.value ?? false;

      if (!isConnected) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'You\'re offline',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chat requires internet connection. Try browsing saved verses or devotionals offline.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.withValues(alpha: 0.9),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Get current language FIRST (before any async operations)
      final language = Localizations.localeOf(context).languageCode;

      // Get subscription service and status
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final subscriptionStatus = subscriptionService.getSubscriptionStatus();

      debugPrint(
          '🔍 Subscription check: status=$subscriptionStatus, kDebugMode=$kDebugMode');

      // 1. Check if user is locked out (trial expired or premium expired)
      if (subscriptionStatus == SubscriptionStatus.trialExpired ||
          subscriptionStatus == SubscriptionStatus.premiumExpired) {
        // Show paywall directly - user is fully locked out
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PaywallScreen(showTrialInfo: false),
            ),
          );
        }
        return;
      }

      // 2. Check if user is suspended for security violations
      // Invalidate to get fresh status (suspension may have been applied in previous message)
      ref.invalidate(isSuspendedProvider);
      final isSuspended = await ref.read(isSuspendedProvider.future);

      if (isSuspended) {
        debugPrint('🚫 User is suspended - blocking message send');
        // User is suspended - the UI overlay will show the suspension message
        return;
      }

      // 3. Check if user has messages remaining
      debugPrint('🔍 About to check canSendMessage...');
      final canSend = subscriptionService.canSendMessage;
      debugPrint('🔍 canSendMessage result: $canSend');

      if (!canSend) {
        // Show message limit dialog first
        if (context.mounted) {
          final shouldShowPaywall = await MessageLimitDialog.show(
            context: context,
            isPremium: subscriptionStatus == SubscriptionStatus.premiumActive,
            remainingMessages: subscriptionService.remainingMessages,
          );

          if (shouldShowPaywall == true) {
            if (!context.mounted) {
              return;
            }
            // User clicked "Subscribe Now"
            final upgraded = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaywallScreen(
                  showTrialInfo:
                      subscriptionStatus == SubscriptionStatus.inTrial,
                  showMessageStats: true,
                ),
              ),
            );

            if (upgraded != true) {
              // User didn't upgrade, don't send message
              return;
            }
          } else {
            // User clicked "Maybe Later"
            // Days 1-2: Can still view history (just return)
            // Day 3 + cancelled: Will be handled by lockout check on next screen load
            return;
          }
        } else {
          return;
        }
      }

      // Consume message credit
      // NOTE: Debug bypass DISABLED for testing Phase 1 subscription fixes
      // Ref: openspec/changes/subscription-state-management-fixes
      debugPrint('🔍 About to call consumeMessage...');
      final consumed = await subscriptionService.consumeMessage();
      debugPrint('🔍 consumeMessage returned: $consumed');

      // CRITICAL FIX: Invalidate provider to refresh UI with new message count
      // Ref: openspec/changes/subscription-state-management-fixes/PROPOSAL.md - Task 1.1
      if (consumed && context.mounted) {
        ref.invalidate(subscriptionSnapshotProvider);
        debugPrint('🔄 Invalidated subscriptionSnapshotProvider to refresh UI');

        // Show floating badge after successful message send
        FloatingMessageBadge.show(
          context: context,
          remainingMessages: subscriptionService.remainingMessages,
          isPremium: subscriptionService.isPremium,
          isInTrial: subscriptionService.isInTrial,
        );
      }

      if (!consumed) {
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.chatFailedToSend,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Check for crisis keywords and show resources if detected
      final crisisDetectionService = CrisisDetectionService();
      final crisisResult = crisisDetectionService.detectCrisis(text.trim());

      if (crisisResult != null && context.mounted) {
        // Show dismissible warning with resources (doesn't block the message)
        crisisDetectionService.logCrisisDetection(crisisResult);

        // Capture the context that has Navigator access
        final navigatorContext = context;
        final l10n = AppLocalizations.of(context);
        final currentLanguage = l10n.localeName;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
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
                  color: Colors.orange.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade300, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.crisisResourcesAvailable,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crisisResult.getMessage(language: currentLanguage),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.crisisResourcesTapToView,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade300),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            action: SnackBarAction(
              label: l10n.crisisResourcesView,
              textColor: Colors.orange.shade300,
              onPressed: () {
                // Use navigatorContext to ensure we have Navigator access
                if (navigatorContext.mounted) {
                  CrisisDialog.show(
                    navigatorContext,
                    crisisResult: crisisResult,
                    onAcknowledge: () {
                      debugPrint('✅ User viewed crisis resources');
                    },
                  );
                }
              },
            ),
          ),
        );
        // Message continues to AI normally
      }

      final userMessage = ChatMessage.user(
        content: text.trim(),
        sessionId: sessionId.value,
      );

      // Create AI message placeholder IMMEDIATELY (before streaming)
      final aiMessage = ChatMessage.ai(
        content: '', // Start with empty content
        sessionId: sessionId.value,
      );

      // Add both messages to list at once
      messages.value = [...messages.value, userMessage, aiMessage];
      isStreaming.value = true;
      isStreamingComplete.value = false;

      // Dismiss keyboard after sending message
      FocusManager.instance.primaryFocus?.unfocus();
      messageController.clear();

      // Save user message to database
      if (sessionId.value != null) {
        try {
          await conversationService.saveMessage(userMessage);
          debugPrint('💾 Saved user message to session ${sessionId.value}');
        } catch (e) {
          debugPrint('⚠️ Failed to save user message: $e');
        }
      } else {
        debugPrint('⚠️ Cannot save message - no active session');
      }

      scrollToBottom();

      try {
        // Use actual AI service with streaming
        final aiService = ref.read(aiServiceProvider);
        debugPrint('🔍 AI Service ready: ${aiService.isReady}');

        if (!aiService.isReady) {
          debugPrint('⚠️ AI Service not ready, using fallback');
          throw Exception('AI Service not ready');
        }

        debugPrint('🚀 Starting streaming AI response for: "${text.trim()}"');

        // Prepend verse context to first message (behind the scenes, not visible to user)
        String aiInput = text.trim();
        if (verseContext != null && !hasAddedVerseContext.value) {
          // Only on first user message in verse discussion
          aiInput =
              "Regarding ${verseContext!.fullReference}: '${verseContext!.verseText}'\n\n$aiInput";
          hasAddedVerseContext.value =
              true; // Mark as added so we don't prepend again
          debugPrint(
              '📖 Prepended verse context to AI input (not visible to user)');
        }

        // Accumulate full response
        final fullResponse = StringBuffer();

        // Start streaming
        final stream = aiService.generateResponseStream(
          userInput: aiInput, // Send modified input to AI
          conversationHistory: messages.value
              .sublist(0, messages.value.length - 1), // Exclude the placeholder
          language: language,
        );

        await for (final chunk in stream) {
          fullResponse.write(chunk);

          // Update the AI message content in place
          final updatedMessages = [...messages.value];
          updatedMessages[updatedMessages.length - 1] = ChatMessage.ai(
            content: fullResponse.toString(),
            sessionId: sessionId.value,
          );
          messages.value = updatedMessages;

          // Add small delay for smoother reading experience
          await Future.delayed(const Duration(milliseconds: 30));
          scrollToBottom();
        }

        debugPrint(
            '✅ Streaming complete, full response length: ${fullResponse.length}');

        // Filter AI response for harmful content
        final contentFilterService = ContentFilterService();
        final filterResult =
            contentFilterService.filterResponse(fullResponse.toString());

        String finalContent;
        if (filterResult.isRejected) {
          // Log the filtering event
          contentFilterService.logFilteredResponse(
              filterResult, fullResponse.toString());

          // Use fallback response instead
          finalContent = contentFilterService.getFallbackResponse('default');

          debugPrint('⚠️ Content filtered: ${filterResult.rejectionReason}');
          debugPrint('📝 Using fallback response');
        } else {
          finalContent = fullResponse.toString();
        }

        // Update final message with filtered content (if filtering changed it)
        if (filterResult.isRejected) {
          final updatedMessages = [...messages.value];
          updatedMessages[updatedMessages.length - 1] = ChatMessage.ai(
            content: finalContent,
            sessionId: sessionId.value,
          );
          messages.value = updatedMessages;
        }

        // Mark streaming as complete
        isStreaming.value = false;
        isStreamingComplete.value = false;

        // Save AI message to database
        final finalAiMessage = messages.value.last;
        if (sessionId.value != null) {
          await conversationService.saveMessage(finalAiMessage);
          debugPrint('💾 Saved AI message to session ${sessionId.value}');

          // Auto-generate conversation title after first exchange
          final conversationMessages = messages.value
              .where(
                  (m) => m.type == MessageType.user || m.type == MessageType.ai)
              .toList();

          debugPrint(
              '🔍 Conversation has ${conversationMessages.length} messages (excluding system)');

          if (conversationMessages.length == 2) {
            try {
              debugPrint('🎯 Triggering title generation...');
              final userMsg = conversationMessages.first.content;
              final title =
                  await GeminiAIService.instance.generateConversationTitle(
                userMessage: userMsg,
                aiResponse: fullResponse.toString(),
              );
              await conversationService.updateSessionTitle(
                  sessionId.value!, title);
              debugPrint('✅ Auto-generated title: "$title"');
            } catch (e) {
              debugPrint('⚠️ Failed to generate title: $e');
            }
          }
        } else {
          debugPrint('⚠️ Cannot save AI message - no active session');
        }

        scrollToBottom();
      } catch (e) {
        // Fallback to contextual response if AI service fails
        debugPrint('❌ AI Service error: $e');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
        final response =
            _getContextualResponse(text.trim().toLowerCase(), l10n);
        final aiMessage = ChatMessage.ai(
          content: response,
          sessionId: sessionId.value,
        );

        isStreaming.value = false;
        isStreamingComplete.value = false;
        streamedText.value = '';
        messages.value = [...messages.value, aiMessage];

        // Save fallback AI message to database
        if (sessionId.value != null) {
          await conversationService.saveMessage(aiMessage);
          debugPrint(
              '💾 Saved fallback AI message to session ${sessionId.value}');
        } else {
          debugPrint('⚠️ Cannot save fallback message - no active session');
        }

        scrollToBottom();
      }
    }

    // Regenerate AI response for a specific message
    Future<void> regenerateResponse(int aiMessageIndex) async {
      if (aiMessageIndex < 0 || aiMessageIndex >= messages.value.length) {
        debugPrint('❌ Invalid message index: $aiMessageIndex');
        return;
      }

      final aiMessage = messages.value[aiMessageIndex];
      if (!aiMessage.isAI) {
        debugPrint('❌ Cannot regenerate non-AI message');
        return;
      }

      // Check subscription before regenerating
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final canSend = subscriptionService.canSendMessage;

      if (!canSend) {
        // Show paywall
        if (context.mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaywallScreen(
                showTrialInfo: subscriptionService.isInTrial,
                showMessageStats: true,
              ),
            ),
          );

          if (result != true) {
            // User didn't upgrade
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                margin: const EdgeInsets.all(16),
                padding: EdgeInsets.zero,
                content: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF0F172A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade300,
                        // ignore: use_build_context_synchronously
                        size: ResponsiveUtils.iconSize(context, 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.subscriptionRequiredRegenerate,
                          style: TextStyle(
                            color: Colors.white,
                            // ignore: use_build_context_synchronously
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            return;
          }
        }
      }

      // Find the previous user message
      String? userInput;
      for (int i = aiMessageIndex - 1; i >= 0; i--) {
        if (messages.value[i].isUser) {
          userInput = messages.value[i].content;
          break;
        }
      }

      if (userInput == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
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
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade300,
                      size: ResponsiveUtils.iconSize(context, 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.errorPreviousMessage,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return;
      }

      // Consume a message for regeneration
      final consumed = await subscriptionService.consumeMessage();
      if (!consumed) {
        debugPrint('❌ Failed to consume message for regeneration');
        return;
      }

      // CRITICAL FIX: Invalidate provider to refresh UI with new message count
      // This ensures the message counter badge updates after regeneration
      if (consumed && context.mounted) {
        ref.invalidate(subscriptionSnapshotProvider);
        debugPrint('🔄 Invalidated subscriptionSnapshotProvider to refresh UI');
      }

      debugPrint(
          '🔄 Regenerating response for user input: "$userInput" (message consumed)');
      isTyping.value = true;

      try {
        // Use actual AI service
        final aiService = ref.read(aiServiceProvider);

        if (!aiService.isReady) {
          throw Exception('AI Service not ready');
        }

        // Get current language
        // ignore: use_build_context_synchronously
        final language = Localizations.localeOf(context).languageCode;

        // Add context to request a different response
        final response = await aiService.generateResponse(
          userInput: userInput,
          conversationHistory: messages.value.take(aiMessageIndex).toList(),
          context: {
            'regenerate': true,
            'previous_response': aiMessage.content,
            'instruction': l10n.aiRegenerateInstruction,
          },
          language: language,
        );
        debugPrint('✅ AI service returned new response');

        // Filter regenerated response for harmful content
        final contentFilterService = ContentFilterService();
        final filterResult =
            contentFilterService.filterResponse(response.content);

        String finalContent;
        if (filterResult.isRejected) {
          contentFilterService.logFilteredResponse(
              filterResult, response.content);
          finalContent = contentFilterService.getFallbackResponse('default');
          debugPrint(
              '⚠️ Regenerated content filtered: ${filterResult.rejectionReason}');
        } else {
          finalContent = response.content;
        }

        // Use copyWith to preserve the original message ID
        // This prevents re-animation when the widget rebuilds
        final newAiMessage = aiMessage.copyWith(
          content: finalContent,
          verses: response.verses,
          metadata: response.metadata,
        );

        // Replace the message in the list
        final updatedMessages = List<ChatMessage>.from(messages.value);
        updatedMessages[aiMessageIndex] = newAiMessage;
        messages.value = updatedMessages;

        // Update in database
        if (sessionId.value != null) {
          // Delete and re-save with same ID (preserves message identity)
          await conversationService.deleteMessage(aiMessage.id);
          await conversationService.saveMessage(newAiMessage);
          debugPrint(
              '💾 Updated message in database (ID preserved: ${aiMessage.id})');
        }

        isTyping.value = false;

        // Set regenerated message ID for shimmer animation
        regeneratedMessageId.value = newAiMessage.id;
        debugPrint(
            '✨ Triggering shimmer animation for message ${newAiMessage.id}');

        // Clear animation flag after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            regeneratedMessageId.value = null;
          }
        });

        if (context.mounted) {
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
                        '✨ Response regenerated successfully',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to regenerate response: $e');
        isTyping.value = false;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
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
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade300,
                      size: ResponsiveUtils.iconSize(context, 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.failedToRegenerate(e.toString()),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    // Export conversation to text
    Future<void> exportConversation() async {
      if (sessionId.value == null) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.noConversationToExport,
            icon: Icons.info_outline,
          );
        }
        return;
      }

      try {
        debugPrint('📤 Exporting conversation: ${sessionId.value}');
        final exportText =
            await conversationService.exportConversation(sessionId.value!);

        if (exportText.isEmpty) {
          if (context.mounted) {
            AppSnackBar.show(
              context,
              message: l10n.noMessagesToExport,
              icon: Icons.info_outline,
            );
          }
          return;
        }

        if (context.mounted) {
          showGlassDialog(
            context: context,
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.download, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AutoSizeText(
                          l10n.exportConversation,
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveUtils.fontSize(context, 20,
                                minSize: 18, maxSize: 24),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: AppRadius.mediumRadius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        exportText,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontFamily: 'monospace',
                          fontSize: ResponsiveUtils.fontSize(context, 12,
                              minSize: 10, maxSize: 14),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GlassDialogButton(
                        text: l10n.close,
                        onTap: () => Navigator.pop(context),
                      ),
                      GlassDialogButton(
                        text: l10n.share,
                        isPrimary: true,
                        onTap: () async {
                          final l10n = AppLocalizations.of(context);
                          Navigator.pop(context);
                          await SharePlus.instance.share(
                            ShareParams(
                              text: exportText,
                              subject: l10n.chatExportSubject,
                            ),
                          );
                          if (context.mounted) {
                            AppSnackBar.show(
                              context,
                              message: l10n.conversationExported,
                              icon: Icons.check_circle_outline,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to export conversation: $e');
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.failedToExport(e.toString()),
          );
        }
      }
    }

    // Share conversation directly
    Future<void> shareText() async {
      if (sessionId.value == null) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.noConversationToShare,
            icon: Icons.info_outline,
          );
        }
        return;
      }

      try {
        final l10n = AppLocalizations.of(context);
        debugPrint('📤 Sharing conversation: ${sessionId.value}');
        final exportText =
            await conversationService.exportConversation(sessionId.value!);

        if (exportText.isEmpty) {
          if (context.mounted) {
            AppSnackBar.show(
              context,
              message: l10n.noMessagesToShare,
              icon: Icons.info_outline,
            );
          }
          return;
        }

        await SharePlus.instance.share(
          ShareParams(
            text: exportText,
            subject: l10n.chatShareSubject,
          ),
        );

        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.conversationShared,
            icon: Icons.check_circle_outline,
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to share conversation: $e');
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.failedToShare(e.toString()),
          );
        }
      }
    }

    // Share entire conversation as branded image
    Future<void> shareConversationAsImage() async {
      if (messages.value.isEmpty) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.noMessagesToShare,
            icon: Icons.info_outline,
          );
        }
        return;
      }

      try {
        final dbService = ref.read(databaseServiceProvider);
        final achievementService = ref.read(achievementServiceProvider);
        final chatShareService = ChatShareService(
          databaseService: dbService,
          achievementService: achievementService,
        );

        // Filter out system messages
        final shareableMessages =
            messages.value.where((m) => m.type != MessageType.system).toList();

        if (shareableMessages.isEmpty) {
          if (context.mounted) {
            AppSnackBar.show(
              context,
              message: l10n.noMessagesToShare,
              icon: Icons.info_outline,
            );
          }
          return;
        }

        // Create shareable widgets
        final messageWidgets =
            chatShareService.createShareableMessageWidgets(shareableMessages);

        // Share the entire conversation
        await chatShareService.shareChat(
          context: context,
          messages: shareableMessages,
          messageWidgets: messageWidgets,
          sessionId: sessionId.value,
        );

        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.conversationImageShared,
            icon: Icons.check_circle_outline,
          );
        }
      } catch (e) {
        debugPrint('Error sharing conversation: $e');
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.failedToShareTryAgain,
          );
        }
      }
    }

    // Share specific message exchange as branded image with QR code
    Future<void> shareMessageExchange(int aiMessageIndex) async {
      try {
        final dbService = ref.read(databaseServiceProvider);
        final achievementService = ref.read(achievementServiceProvider);
        final chatShareService = ChatShareService(
          databaseService: dbService,
          achievementService: achievementService,
        );

        // Get the AI message and find its corresponding user message
        final aiMessage = messages.value[aiMessageIndex];

        // Find the user message that comes before this AI message
        ChatMessage? userMessage;
        for (int i = aiMessageIndex - 1; i >= 0; i--) {
          if (messages.value[i].type == MessageType.user) {
            userMessage = messages.value[i];
            break;
          }
        }

        if (userMessage == null) {
          if (context.mounted) {
            AppSnackBar.showError(
              context,
              message: l10n.questionNotFound,
            );
          }
          return;
        }

        // Create the exchange (user question + AI response)
        final exchangeMessages = [userMessage, aiMessage];

        // Create shareable widgets
        final messageWidgets =
            chatShareService.createShareableMessageWidgets(exchangeMessages);

        // Share the exchange
        await chatShareService.shareChat(
          context: context,
          messages: exchangeMessages,
          messageWidgets: messageWidgets,
          sessionId: sessionId.value,
        );

        // Show success message
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.messageExchangeShared,
            icon: Icons.share,
            iconColor: AppTheme.goldColor,
          );
        }
      } catch (e) {
        debugPrint('Error sharing message exchange: $e');
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.failedToShareTryAgain,
          );
        }
      }
    }

    // Show chat options menu
    void showChatOptions() {
      showCustomBottomSheet(
        context: context,
        title: l10n.chatOptions,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.3),
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: const Icon(Icons.download, color: AppTheme.primaryColor),
              ),
              title: Text(
                l10n.exportConversation,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.exportConversationDesc,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                exportConversation();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.3),
                      AppTheme.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child:
                    const Icon(Icons.text_snippet, color: AppTheme.accentColor),
              ),
              title: Text(
                l10n.shareText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.shareTextDesc,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                shareText();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.3),
                      AppTheme.goldColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: const Icon(Icons.image, color: AppTheme.goldColor),
              ),
              title: Text(
                l10n.shareAsImage,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.shareAsImageDesc,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                shareConversationAsImage();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // ============================================================================
    // SUSPENSION CHECK (Priority 1)
    // ============================================================================

    // Check if user is suspended FIRST (takes priority over subscription lockout)
    final isSuspendedAsync = ref.watch(isSuspendedProvider);
    final isSuspended = isSuspendedAsync.when(
      data: (suspended) => suspended,
      loading: () => false,
      error: (_, __) => false,
    );

    if (isSuspended) {
      final remainingTimeAsync = ref.watch(remainingSuspensionTimeProvider);
      final suspensionMessageAsync = ref.watch(suspensionMessageProvider);

      final remainingTime = remainingTimeAsync.whenOrNull(data: (time) => time);
      final suspensionMessage =
          suspensionMessageAsync.whenOrNull(data: (msg) => msg);

      return Scaffold(
        body: Stack(
          children: [
            const GradientBackground(),
            ChatScreenLockoutOverlay(
              reason: LockoutReason.suspended,
              suspensionMessage: suspensionMessage,
              remainingSuspension: remainingTime,
              onSubscribePressed: () {
                // For suspensions, button is hidden, but callback required
                // User cannot subscribe out of suspension
              },
            ),
          ],
        ),
      );
    }

    // ============================================================================
    // SUBSCRIPTION LOCKOUT CHECK (Priority 2)
    // ============================================================================

    // Check subscription status for chat lockout
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final subscriptionStatus = subscriptionService.getSubscriptionStatus();

    // If trial expired or premium expired, show lockout overlay
    if (subscriptionStatus == SubscriptionStatus.trialExpired ||
        subscriptionStatus == SubscriptionStatus.premiumExpired) {
      final lockoutReason =
          subscriptionStatus == SubscriptionStatus.trialExpired
              ? LockoutReason.trialExpired
              : LockoutReason.premiumExpired;

      return Scaffold(
        body: Stack(
          children: [
            const GradientBackground(),
            ChatScreenLockoutOverlay(
              reason: lockoutReason,
              onSubscribePressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaywallScreen(showTrialInfo: false),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            const GradientBackground(),
            SafeArea(
              child: Column(
                children: [
                  // AI Service initialization status banner
                  _buildAIStatusBanner(aiServiceState, l10n),
                  // Connectivity status banner
                  _buildConnectivityBanner(context, connectivityStatus, l10n),
                  // CustomScrollView with pinned header and action buttons
                  Expanded(
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        // Pinned FAB + action buttons row
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: ChatActionButtonsDelegate(
                            height:
                                120.0, // Increased to accommodate full FAB menu (80px) + padding (20px top + 20px bottom)
                            child: ChatActionButtons(
                              onMorePressed: showChatOptions,
                              onHistoryPressed: () => _showConversationHistory(
                                  context,
                                  messages,
                                  sessionId,
                                  conversationService,
                                  l10n),
                              onNewPressed: () => _startNewConversation(
                                  context,
                                  messages,
                                  sessionId,
                                  conversationService,
                                  l10n),
                              onReturnToReadingPressed: verseContext != null
                                  ? () => _returnToReading(context)
                                  : null,
                            ),
                          ),
                        ),
                        // Verse context message (only shows if navigated from verse)
                        if (verseContext != null)
                          SliverToBoxAdapter(
                            child: VerseContextMessage(
                                verseContext: verseContext!),
                          ),
                        // Messages list
                        _buildMessagesSliver(
                          context,
                          messages.value,
                          isTyping.value,
                          isStreaming.value,
                          isStreamingComplete.value,
                          streamedText.value,
                          regenerateResponse,
                          shareMessageExchange,
                          regeneratedMessageId.value,
                          l10n,
                        ),
                        // Add spacing at bottom to prevent last message from being hidden by floating input
                        const SliverToBoxAdapter(
                          child: SizedBox(
                              height: 80), // Space for floating input field
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Floating message input - positioned outside SafeArea
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMessageInput(
                  context, messageController, canSend.value, sendMessage),
            ),
            // Scroll to bottom button
            ScrollToBottom(
              isVisible: showScrollToBottom.value,
              onPressed: scrollToBottom,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIStatusBanner(AIServiceState state, AppLocalizations l10n) {
    return state.when(
      initializing: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.3),
              Colors.orange.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.9)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AutoSizeText(
                l10n.initializingAI,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                minFontSize: 10,
                maxFontSize: 15,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      ready: () => const SizedBox.shrink(),
      fallback: (reason) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.3),
              Colors.amber.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber,
                color: Colors.white.withValues(alpha: 0.9), size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: AutoSizeText(
                l10n.usingFallback(reason),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                minFontSize: 10,
                maxFontSize: 15,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      error: (message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Colors.white.withValues(alpha: 0.9), size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: AutoSizeText(
                l10n.aiServiceError(message),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                minFontSize: 10,
                maxFontSize: 15,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sliver version for CustomScrollView
  Widget _buildMessagesSliver(
    BuildContext context,
    List<ChatMessage> messages,
    bool isTyping,
    bool isStreaming,
    bool isStreamingComplete,
    String streamedText,
    Future<void> Function(int) onRegenerateResponse,
    Future<void> Function(int) onShareExchange,
    String? regeneratedMessageId,
    AppLocalizations l10n,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (listContext, index) {
            // Show typing indicator as fallback
            if (index == messages.length && isTyping) {
              return _buildTypingIndicator();
            }

            return _buildMessageBubble(
                context,
                messages[index],
                index,
                onRegenerateResponse,
                onShareExchange,
                regeneratedMessageId,
                l10n,
                messages);
          },
          childCount: messages.length + (isTyping ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    int index,
    Future<void> Function(int) onRegenerateResponse,
    Future<void> Function(int) onShareExchange,
    String? regeneratedMessageId,
    AppLocalizations l10n,
    List<ChatMessage> allMessages,
  ) {
    final bool isRegeneratedMessage =
        regeneratedMessageId != null && message.id == regeneratedMessageId;

    final messageWidget = GestureDetector(
      onLongPress: message.isAI
          ? () {
              // Show options for regenerate
              showCustomBottomSheet(
                context: context,
                title: l10n.messageOptions,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: AppRadius.mediumRadius,
                        ),
                        child: const Icon(Icons.copy,
                            color: AppTheme.primaryColor),
                      ),
                      title: Text(
                        l10n.copyMessage,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        l10n.copyMessageDesc,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 12,
                              minSize: 10, maxSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await Clipboard.setData(
                            ClipboardData(text: message.content));
                        if (context.mounted) {
                          AppSnackBar.show(
                            context,
                            message: l10n.messageCopied,
                            icon: Icons.content_copy,
                            iconColor: AppTheme.primaryColor,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: AppRadius.mediumRadius,
                        ),
                        child: const Icon(Icons.refresh,
                            color: AppTheme.primaryColor),
                      ),
                      title: Text(
                        l10n.regenerateResponse,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        l10n.regenerateResponseDesc,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 12,
                              minSize: 10, maxSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onRegenerateResponse(index);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.3),
                              AppTheme.goldColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: AppRadius.mediumRadius,
                        ),
                        child:
                            const Icon(Icons.share, color: AppTheme.goldColor),
                      ),
                      title: Text(
                        l10n.shareExchange,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        l10n.shareExchangeDesc,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 12,
                              minSize: 10, maxSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onShareExchange(index);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.scaleSize(
                    context, AppSpacing.sm,
                    minScale: 0.9, maxScale: 1.1)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFC05E91).withValues(alpha: 0.3),
                      const Color(0xFFC05E91).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.secondaryText,
                  size: ResponsiveUtils.iconSize(context, 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Flexible(
              child: message.isUser
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                            AppTheme.primaryColor.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(AppRadius.lg),
                          bottomRight: Radius.circular(AppRadius.lg),
                        ),
                        border: Border.all(
                          color: AppTheme.goldColor,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            message.content,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 15,
                                  minSize: 13, maxSize: 17),
                              color: AppColors.primaryText,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              shadows: AppTheme.textShadowSubtle,
                            ),
                            minFontSize: 12,
                            maxFontSize: 17,
                            maxLines: 500,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TimeAndStatus(
                            timestamp: message.timestamp,
                            status: message.status,
                            showTime: true,
                            showStatus: true,
                          ),
                        ],
                      ),
                    )
                  : GlassContainer(
                      borderRadius: 20,
                      blurStrength: 15.0,
                      gradientColors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                      padding: AppSpacing.cardPadding,
                      enableNoise: true,
                      enableLightSimulation: true,
                      border: Border.all(
                        color: isRegeneratedMessage
                            ? AppTheme.goldColor.withValues(alpha: 0.8)
                            : AppTheme.goldColor,
                        width: isRegeneratedMessage ? 2.0 : 1.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            message.content,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 15,
                                  minSize: 13, maxSize: 17),
                              color: AppColors.primaryText,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              shadows: AppTheme.textShadowSubtle,
                            ),
                            minFontSize: 12,
                            maxFontSize: 17,
                            maxLines: 500,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TimeAndStatus(
                            timestamp: message.timestamp,
                            status: message.status,
                            showTime: true,
                            showStatus: false, // AI messages don't show status
                          ),
                        ],
                      ),
                    ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                width: ResponsiveUtils.scaleSize(context, 40,
                    minScale: 0.9, maxScale: 1.1),
                height: ResponsiveUtils.scaleSize(context, 40,
                    minScale: 0.9, maxScale: 1.1),
                padding: EdgeInsets.all(ResponsiveUtils.scaleSize(context, 6,
                    minScale: 0.9, maxScale: 1.1)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.3),
                      AppTheme.goldColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Semantics(
                    label: l10n.aiAssistantLogo,
                    image: true,
                    child: Image.asset(
                      l10n.localeName == 'es'
                          ? 'assets/images/logo_spanish.png'
                          : 'assets/images/logo_cropped.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ); // End of GestureDetector

    // Conditionally wrap with shimmer animation for regenerated messages
    // This keeps the same widget structure, avoiding widget rebuilds
    if (isRegeneratedMessage) {
      return messageWidget
          .animate()
          .shimmer(
            duration: const Duration(milliseconds: 800),
            color: AppTheme.goldColor.withValues(alpha: 0.4),
          )
          .then()
          .shimmer(
            duration: const Duration(milliseconds: 800),
            color: AppTheme.goldColor.withValues(alpha: 0.4),
          )
          .then()
          .shimmer(
            duration: const Duration(milliseconds: 800),
            color: AppTheme.goldColor.withValues(alpha: 0.4),
          );
    }

    // For all messages, return without animations (like streaming messages)
    return messageWidget;
  }

  Widget _buildTypingIndicator() {
    return const GlassTypingIndicator();
  }

  Widget _buildMessageInput(
      BuildContext context,
      TextEditingController messageController,
      bool canSend,
      void Function(String) sendMessage) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Consumer(
      builder: (context, ref, child) {
        final remainingMessages = ref.watch(remainingMessagesProvider);
        final isPremium = ref.watch(isPremiumProvider);

        return Container(
          color: Colors.transparent, // Fully transparent background
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: bottomPadding > 0
                ? bottomPadding + AppSpacing.sm
                : AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl + 1),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl + 1),
                        border: Border.all(
                          color: AppTheme.goldColor,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: messageController,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: ResponsiveUtils.fontSize(context, 15,
                              minSize: 13, maxSize: 17),
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.scriptureChatHint,
                          hintStyle: TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: ResponsiveUtils.fontSize(context, 15,
                                minSize: 13, maxSize: 17),
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: canSend ? sendMessage : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ProgressRingSendButton(
                canSend: canSend,
                onPressed: () => sendMessage(messageController.text),
                remainingMessages: remainingMessages,
                totalMessages: isPremium ? 150 : 5,
                isPremium: isPremium,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: AppAnimations.slow, delay: AppAnimations.fast)
              .slideY(begin: 0.3),
        );
      },
    );
  }

  String _getContextualResponse(String message, AppLocalizations l10n) {
    if (message.contains('prayer') || message.contains('pray')) {
      return l10n.fallbackPrayerResponse;
    } else if (message.contains('fear') ||
        message.contains('afraid') ||
        message.contains('worry')) {
      return l10n.fallbackFearResponse;
    } else if (message.contains('love') || message.contains('relationship')) {
      return l10n.fallbackLoveResponse;
    } else if (message.contains('forgive') || message.contains('forgiveness')) {
      return l10n.fallbackForgivenessResponse;
    } else if (message.contains('purpose') || message.contains('calling')) {
      return l10n.fallbackPurposeResponse;
    } else {
      return l10n.fallbackDefaultResponse;
    }
  }

  void _showConversationHistory(
    BuildContext context,
    ValueNotifier<List<ChatMessage>> messages,
    ValueNotifier<String?> sessionId,
    ConversationService conversationService,
    AppLocalizations l10n,
  ) async {
    debugPrint('📜 Opening conversation history...');
    final allSessions = await conversationService.getSessions();
    // Filter out conversations with only system welcome messages
    final sessions = allSessions.where((session) {
      final messageCount = session['message_count'] as int? ?? 0;
      final preview = session['last_message_preview'] as String? ?? '';

      // Filter out empty conversations or those with only the welcome message
      if (messageCount == 0) return false;
      if (messageCount == 1 && preview.startsWith('Peace be with you')) {
        return false;
      }

      return true;
    }).toList();
    debugPrint(
        '📜 Found ${sessions.length} non-empty sessions in history (${allSessions.length} total)');

    if (!context.mounted) return;

    showCustomBottomSheet(
      context: context,
      title: l10n.conversationHistory,
      height: MediaQuery.of(context).size.height * 0.75,
      child: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: ResponsiveUtils.iconSize(context, 64),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AutoSizeText(
                    l10n.noConversationHistory,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16,
                          minSize: 14, maxSize: 18),
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    minFontSize: 12,
                    maxFontSize: 18,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final updatedAtRaw = session['updated_at'] as int;
                // Handle both seconds and milliseconds timestamps
                // Timestamps > 10000000000 are in milliseconds (after Sep 2001)
                final updatedAt = updatedAtRaw > 10000000000
                    ? DateTime.fromMillisecondsSinceEpoch(updatedAtRaw)
                    : DateTime.fromMillisecondsSinceEpoch(updatedAtRaw * 1000);
                final messageCount = session['message_count'] as int? ?? 0;
                final sessionIdStr = session['id'] as String;
                final lastMessagePreview =
                    session['last_message_preview'] as String?;

                return Dismissible(
                  key: Key(sessionIdStr),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Show confirmation dialog
                    return await showGlassDialog<bool>(
                          context: context,
                          child: GlassContainer(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade400,
                                  size: ResponsiveUtils.iconSize(context, 48),
                                ),
                                const SizedBox(height: 16),
                                AutoSizeText(
                                  'Delete Conversation?',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveUtils.fontSize(
                                        context, 20,
                                        minSize: 18, maxSize: 24),
                                  ),
                                  maxLines: 1,
                                  minFontSize: 16,
                                  maxFontSize: 24,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                AutoSizeText(
                                  l10n.deleteConversationMessage,
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: ResponsiveUtils.fontSize(
                                        context, 14,
                                        minSize: 12, maxSize: 16),
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  minFontSize: 11,
                                  maxFontSize: 16,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GlassDialogButton(
                                      text: l10n.cancel,
                                      onTap: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    GlassDialogButton(
                                      text: l10n.delete,
                                      isPrimary: true,
                                      onTap: () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (direction) async {
                    // Delete the session
                    await conversationService.deleteSession(sessionIdStr);
                    debugPrint('🗑️ Deleted session: $sessionIdStr');

                    if (context.mounted) {
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
                                color:
                                    AppTheme.goldColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.goldColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.conversationDeleted,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          ResponsiveUtils.fontSize(context, 14),
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
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.8),
                          Colors.red.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: ResponsiveUtils.iconSize(context, 32),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.3),
                              AppTheme.goldColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: AppRadius.mediumRadius,
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primaryText,
                          size: ResponsiveUtils.iconSize(context, 20),
                        ),
                      ),
                      title: AutoSizeText(
                        session['title'] as String? ??
                            l10n.conversationDefaultTitle,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 16,
                              minSize: 14, maxSize: 18),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        minFontSize: 12,
                        maxFontSize: 18,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lastMessagePreview != null &&
                              lastMessagePreview.isNotEmpty) ...[
                            AutoSizeText(
                              lastMessagePreview,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 13,
                                    minSize: 11, maxSize: 14),
                                color: AppColors.tertiaryText,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              minFontSize: 10,
                              maxFontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                          AutoSizeText(
                            '${_formatDate(updatedAt, l10n)} • $messageCount messages',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 12,
                                  minSize: 10, maxSize: 13),
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            minFontSize: 9,
                            maxFontSize: 13,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: ResponsiveUtils.iconSize(context, 16),
                        color: AppColors.secondaryText,
                      ),
                      onTap: () {
                        debugPrint('👆 User selected session: $sessionIdStr');
                        Navigator.pop(context);
                        _loadConversation(
                          sessionIdStr,
                          messages,
                          sessionId,
                          conversationService,
                        );
                      },
                    ),
                  )
                      .animate()
                      .fadeIn(duration: AppAnimations.fast)
                      .slideX(begin: 0.2),
                );
              },
            ),
    );
  }

  void _startNewConversation(
    BuildContext context,
    ValueNotifier<List<ChatMessage>> messages,
    ValueNotifier<String?> sessionId,
    ConversationService conversationService,
    AppLocalizations l10n,
  ) async {
    debugPrint('🆕 New conversation button clicked');

    // Get current message count (excluding system welcome message)
    final conversationMessages = messages.value
        .where((m) => m.type == MessageType.user || m.type == MessageType.ai)
        .toList();

    debugPrint(
        '🔍 Current conversation has ${conversationMessages.length} messages (excluding system)');

    // Only show confirmation if there's actual conversation content
    if (conversationMessages.isEmpty) {
      // No real messages yet - just create new session directly
      debugPrint('✨ No messages yet, creating new session directly');
      final newSessionId = await conversationService.createSession(
        title: l10n.newConversation,
      );
      sessionId.value = newSessionId;

      final welcomeMessage = ChatMessage.system(
        content:
            'Peace be with you! 🙏\n\nI\'m here to provide intelligent scripture support directly from the word itself, for everyday Christian questions. Feel free to ask me about:\n\n• Scripture interpretation\n• Prayer requests\n• Life challenges\n• Faith questions\n• Daily encouragement\n\nHow can I help you today?',
        sessionId: newSessionId,
      );
      await conversationService.saveMessage(welcomeMessage);
      messages.value = [welcomeMessage];

      debugPrint('✅ New session created: $newSessionId');

      // Show success feedback
      if (context.mounted) {
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
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✨ New conversation started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(context, 14),
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
      return;
    }

    // Show confirmation dialog if there's content
    showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                l10n.startNewConversationTitle,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtils.fontSize(context, 20,
                      minSize: 18, maxSize: 24),
                ),
                maxLines: 1,
                minFontSize: 16,
                maxFontSize: 24,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              AutoSizeText(
                l10n.startNewConversationMessage,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                minFontSize: 11,
                maxFontSize: 16,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: l10n.cancel,
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GlassButton(
                      text: l10n.newChat,
                      height: 48,
                      onPressed: () async {
                        debugPrint('✅ User confirmed new conversation');
                        Navigator.pop(context);

                        // Ensure current session is finalized
                        if (sessionId.value != null) {
                          debugPrint(
                              '💾 Finalizing current session: ${sessionId.value}');
                          // Session is already auto-updated via _updateSessionLastMessage
                        }

                        // Create new session
                        debugPrint('🆕 Creating new session...');
                        final newSessionId =
                            await conversationService.createSession(
                          title: l10n.newConversation,
                        );
                        sessionId.value = newSessionId;

                        // Reset messages with welcome message (with sessionId)
                        final welcomeMessage = ChatMessage.system(
                          content:
                              'Peace be with you! 🙏\n\nI\'m here to provide intelligent scripture support directly from the word itself, for everyday Christian questions. Feel free to ask me about:\n\n• Scripture interpretation\n• Prayer requests\n• Life challenges\n• Faith questions\n• Daily encouragement\n\nHow can I help you today?',
                          sessionId: newSessionId,
                        );
                        await conversationService.saveMessage(welcomeMessage);
                        messages.value = [welcomeMessage];

                        // Show success feedback
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
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
                                    color: AppTheme.goldColor
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.goldColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '✨ New conversation started! Previous chat saved to history.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: ResponsiveUtils.fontSize(
                                              context, 14),
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

                        debugPrint('✅ Started new conversation: $newSessionId');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadConversation(
    String conversationSessionId,
    ValueNotifier<List<ChatMessage>> messages,
    ValueNotifier<String?> sessionId,
    ConversationService conversationService,
  ) async {
    try {
      debugPrint('📂 Loading conversation: $conversationSessionId');

      // Load messages from database
      final loadedMessages =
          await conversationService.getMessages(conversationSessionId);
      debugPrint(
          '📨 Retrieved ${loadedMessages.length} messages from database');

      // Update session ID
      sessionId.value = conversationSessionId;

      // Update messages list
      messages.value = loadedMessages;

      debugPrint(
          '✅ Loaded conversation: $conversationSessionId with ${loadedMessages.length} messages');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load conversation: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Navigate back to ChapterReadingScreen with the verse context
  void _returnToReading(BuildContext context) {
    if (verseContext == null) return;

    debugPrint('📖 Returning to reading: ${verseContext!.reference}');
    Navigator.pop(context, verseContext);
  }

  String _formatDate(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();

    // Compare dates only (ignore time) to handle midnight boundary correctly
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDifference = today.difference(messageDate).inDays;

    if (daysDifference == 0) {
      return l10n.today;
    } else if (daysDifference == 1) {
      return l10n.yesterday;
    } else if (daysDifference < 7) {
      return '$daysDifference days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Widget _buildConnectivityBanner(BuildContext context,
      AsyncValue<bool> connectivityStatus, AppLocalizations l10n) {
    return connectivityStatus.when(
      data: (isConnected) {
        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.3),
                Colors.red.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noInternetConnection,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiRequiresInternet,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
