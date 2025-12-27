import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/subscription_service.dart';
import '../services/suspension_service.dart';

/// Provides access to the singleton SubscriptionService.
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService.instance;
});

/// Ensures subscription initialisation runs during bootstrap flows.
final subscriptionInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  await service.initialize();
});

/// Snapshot of the user's subscription state.
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.status,
    required this.isPremium,
    required this.isInTrial,
    required this.hasTrialExpired,
    required this.canSendMessage,
    required this.remainingMessages,
    required this.messagesUsed,
    required this.trialDaysRemaining,
    required this.premiumMessagesRemaining,
    required this.trialMessagesRemaining,
  });

  final SubscriptionStatus status;
  final bool isPremium;
  final bool isInTrial;
  final bool hasTrialExpired;
  final bool canSendMessage;
  final int remainingMessages;
  final int messagesUsed;
  final int trialDaysRemaining;
  final int premiumMessagesRemaining;
  final int trialMessagesRemaining;
}

/// Memoises the latest subscription information for UI consumers.
final subscriptionSnapshotProvider = Provider<SubscriptionSnapshot>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  final status = service.getSubscriptionStatus();

  return SubscriptionSnapshot(
    status: status,
    isPremium: service.isPremium,
    isInTrial: service.isInTrial,
    hasTrialExpired: service.hasTrialExpired,
    canSendMessage: service.canSendMessage,
    remainingMessages: service.remainingMessages,
    messagesUsed: service.messagesUsed,
    trialDaysRemaining: service.trialDaysRemaining,
    premiumMessagesRemaining: service.premiumMessagesRemaining,
    trialMessagesRemaining: service.trialMessagesRemaining,
  );
});

/// OPTIMIZED: Uses .select() to only rebuild when specific field changes
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.status));
});

/// OPTIMIZED: Uses .select() to only rebuild when isPremium changes
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.isPremium));
});

/// OPTIMIZED: Uses .select() to only rebuild when isInTrial changes
final isInTrialProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.isInTrial));
});

/// OPTIMIZED: Uses .select() to only rebuild when hasTrialExpired changes
final hasTrialExpiredProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.hasTrialExpired));
});

/// OPTIMIZED: Uses .select() to only rebuild when remainingMessages changes
final remainingMessagesProvider = Provider<int>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.remainingMessages));
});

/// OPTIMIZED: Uses .select() to only rebuild when messagesUsed changes
final messagesUsedProvider = Provider<int>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.messagesUsed));
});

/// OPTIMIZED: Uses .select() to only rebuild when canSendMessage changes
final canSendMessageProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.canSendMessage));
});

/// OPTIMIZED: Uses .select() to only rebuild when trialDaysRemaining changes
final trialDaysRemainingProvider = Provider<int>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.trialDaysRemaining));
});

/// OPTIMIZED: Uses .select() to only rebuild when premiumMessagesRemaining changes
final premiumMessagesRemainingProvider = Provider<int>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.premiumMessagesRemaining));
});

/// OPTIMIZED: Uses .select() to only rebuild when trialMessagesRemaining changes
final trialMessagesRemainingProvider = Provider<int>((ref) {
  return ref.watch(subscriptionSnapshotProvider.select((snap) => snap.trialMessagesRemaining));
});

// ============================================================================
// Suspension Service Providers
// ============================================================================

// Create a single instance of SuspensionService that's reused across the app
final _suspensionServiceInstance = SuspensionService();

/// Provides access to the SuspensionService singleton.
final suspensionServiceProvider = Provider<SuspensionService>((ref) {
  return _suspensionServiceInstance;
});

/// Ensures suspension service initialization runs during bootstrap.
final suspensionInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(suspensionServiceProvider);
  await service.initialize();
});

/// Check if user is currently suspended
final isSuspendedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(suspensionServiceProvider);
  return await service.isSuspended();
});

/// Get remaining suspension time
final remainingSuspensionTimeProvider = FutureProvider<Duration?>((ref) async {
  final service = ref.watch(suspensionServiceProvider);
  return await service.getRemainingTime();
});

/// Get suspension message for display
final suspensionMessageProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(suspensionServiceProvider);
  return await service.getSuspensionMessage();
});

/// Get current suspension level
final suspensionLevelProvider = FutureProvider<SuspensionLevel>((ref) async {
  final service = ref.watch(suspensionServiceProvider);
  return await service.getCurrentSuspensionLevel();
});

/// Get violation count
final violationCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(suspensionServiceProvider);
  return await service.getViolationCount();
});
