/// Subscription Service
/// Manages premium subscription state, trial period, and message limits
///
/// Trial: 3 days OR 15 messages total (whichever comes first)
/// Premium: ~$35.99/year (pricing may vary by region and currency), 150 messages/month
///
/// Uses SharedPreferences for local persistence (privacy-first design)
/// Uses in_app_purchase for App Store/Play Store subscriptions

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Represents the current subscription state of the user
enum SubscriptionStatus {
  /// Brand new user who hasn't started trial
  neverStarted,

  /// Currently in days 1-3 of trial period
  inTrial,

  /// Trial period ended, no active subscription
  trialExpired,

  /// Active paid subscriber with valid subscription
  premiumActive,

  /// Subscription cancelled but still has time remaining
  premiumCancelled,

  /// Subscription fully expired
  premiumExpired,
}

class SubscriptionService {
  // Singleton instance
  static SubscriptionService? _instance;
  static SubscriptionService get instance {
    _instance ??= SubscriptionService._();
    return _instance!;
  }

  SubscriptionService._();

  // ============================================================================
  // CONSTANTS
  // ============================================================================

  // Product IDs (must match App Store Connect / Play Console)
  // NOTE: Updated for new free app to avoid conflicts with old paid app
  static const String premiumYearlyProductId = 'everyday_christian_free_premium_yearly';
  static const String premiumMonthlyProductId = 'everyday_christian_free_premium_monthly';

  // Trial configuration
  static const int trialDurationDays = 3;
  static const int trialMessagesPerDay = 5;
  static const int trialTotalMessages = trialDurationDays * trialMessagesPerDay; // 15

  // Premium configuration
  static const int premiumMessagesPerMonth = 150;

  // SharedPreferences keys
  static const String _keyTrialStartDate = 'trial_start_date';
  static const String _keyTrialMessagesUsed = 'trial_messages_used';
  static const String _keyTrialLastResetDate = 'trial_last_reset_date';
  static const String _keyPremiumActive = 'premium_active';
  static const String _keyPremiumMessagesUsed = 'premium_messages_used';
  static const String _keyPremiumLastResetDate = 'premium_last_reset_date';
  static const String _keySubscriptionReceipt = 'subscription_receipt';
  // New keys for expiry tracking and trial abuse prevention
  static const String _keyPremiumExpiryDate = 'premium_expiry_date';
  static const String _keyPremiumOriginalPurchaseDate = 'premium_original_purchase_date';
  static const String _keyTrialEverUsed = 'trial_ever_used'; // ignore: unused_field
  static const String _keyAutoRenewStatus = 'auto_renew_status';
  static const String _keyAutoSubscribeAttempted = 'auto_subscribe_attempted';
  static const String _keyPurchasedProductId = 'purchased_product_id'; // Track yearly vs monthly

  // Keychain/KeyStore keys (survives app uninstall for trial abuse prevention)
  static const String _keychainTrialEverUsed = 'trial_ever_used_keychain';
  static const String _keychainTrialMarkedDate = 'trial_marked_date_keychain';

  // ============================================================================
  // PROPERTIES
  // ============================================================================

  SharedPreferences? _prefs;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Secure storage for trial abuse prevention (survives app uninstall)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _isInitialized = false;
  ProductDetails? _premiumProductYearly;
  ProductDetails? _premiumProductMonthly;

  // Purchase update callback
  Function(bool success, String? error)? onPurchaseUpdate;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the service (call this on app start)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Check if in-app purchase is available
      final bool available = await _iap.isAvailable();
      if (!available) {
        debugPrint('📊 [SubscriptionService] In-app purchase not available');
        _isInitialized = true;
        return;
      }

      // Load product details
      await _loadProducts();

      // Auto-restore purchases on app launch (prevents data loss after "Delete All Data")
      // Use timeout to prevent hanging on simulator or when StoreKit is unavailable
      try {
        await restorePurchases().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('📊 [SubscriptionService] Restore purchases timed out (expected on simulator)');
          },
        );
      } catch (e) {
        debugPrint('📊 [SubscriptionService] Restore purchases failed: $e');
      }

      // ============================================================
      // TRIAL ABUSE PREVENTION: Check Keychain for previous trial
      // ============================================================
      // This check survives app uninstall/reinstall and prevents
      // users from getting unlimited trials by reinstalling the app.
      // Privacy-first: All data stays on device in secure Keychain/KeyStore
      //
      // ENHANCED: Now includes trial date validation to prevent blocking:
      // - Active ongoing trials (user within 3-day window)
      // - Premium subscribers (even during restore glitches)
      final hasUsedBefore = await hasUsedTrialBefore();

      if (hasUsedBefore && !isPremium) {
        // Keychain says trial was used before AND user is not premium
        // Additional safety: Check if user has an active trial in progress
        final trialStartDate = _getTrialStartDate();

        if (trialStartDate != null) {
          // User has a trial start date - verify if it's actually expired
          final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;

          if (daysSinceStart >= trialDurationDays) {
            // Trial period expired (3+ days), safe to block
            await _prefs?.setBool('trial_blocked', true);
            debugPrint('📊 [SubscriptionService] Trial blocked - expired ($daysSinceStart days since start)');
          } else {
            // Trial still within valid 3-day window, don't block
            await _prefs?.setBool('trial_blocked', false);
            debugPrint('📊 [SubscriptionService] Trial active - $daysSinceStart/$trialDurationDays days used');
          }
        } else {
          // No trial start date but Keychain says used before
          // This means trial was fully exhausted in the past, safe to block
          await _prefs?.setBool('trial_blocked', true);
          debugPrint('📊 [SubscriptionService] Trial blocked - previously exhausted on this device');
        }
      } else {
        // Either first-time user OR paid subscriber - allow access
        await _prefs?.setBool('trial_blocked', false);
        if (isPremium) {
          debugPrint('📊 [SubscriptionService] Premium subscriber - trial check bypassed');
        }
      }

      // Check if user should be automatically subscribed (day 3 without cancellation)
      await attemptAutoSubscribe();

      // Listen to purchase updates
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) => debugPrint('📊 [SubscriptionService] Purchase stream error: $error'),
      );

      // Initialize counters for first-time users (no trial start date = brand new)
      final trialStartDate = _prefs?.getString(_keyTrialStartDate);
      if (trialStartDate == null) {
        // Brand new user - initialize with 0 messages used
        await _prefs?.setInt(_keyTrialMessagesUsed, 0);
        await _prefs?.setString(_keyTrialLastResetDate, DateTime.now().toIso8601String().substring(0, 10));
        debugPrint('📊 [SubscriptionService] First-time user detected - initialized trial counters');
      }

      // Reset message counters if needed
      await _checkAndResetCounters();

      // Check if trial expired while app was closed
      await _checkAndMarkTrialExpiry();

      _isInitialized = true;
      debugPrint('📊 [SubscriptionService] SubscriptionService initialized');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to initialize SubscriptionService: $e');
      _isInitialized = true; // Still mark as initialized to prevent blocking
    }
  }

  /// Load product details from App Store / Play Store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        {premiumYearlyProductId, premiumMonthlyProductId},
      );

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('📊 [SubscriptionService] Products not found: ${response.notFoundIDs}');
      }

      // Load yearly product
      _premiumProductYearly = response.productDetails.firstWhere(
        (product) => product.id == premiumYearlyProductId,
        orElse: () => response.productDetails.first,
      );

      // Load monthly product
      _premiumProductMonthly = response.productDetails.firstWhere(
        (product) => product.id == premiumMonthlyProductId,
        orElse: () => response.productDetails.first,
      );

      if (_premiumProductYearly != null) {
        debugPrint('📊 [SubscriptionService] Loaded yearly product: ${_premiumProductYearly!.id} - ${_premiumProductYearly!.price}');
      }

      if (_premiumProductMonthly != null) {
        debugPrint('📊 [SubscriptionService] Loaded monthly product: ${_premiumProductMonthly!.id} - ${_premiumProductMonthly!.price}');
      }
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to load products: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  // ============================================================================
  // TRIAL STATUS
  // ============================================================================

  /// Check if user is in trial period (first 3 days)
  bool get isInTrial {
    if (isPremium) return false; // Premium users are not in trial

    // Check if trial is blocked from previous use (survives app uninstall)
    if (isTrialBlocked) return false;

    final trialStartDate = _getTrialStartDate();
    if (trialStartDate == null) return true; // Never started trial = can start

    final now = DateTime.now();
    final daysSinceStart = now.difference(trialStartDate).inDays;
    return daysSinceStart < trialDurationDays;
  }

  /// Check if trial has been used (started)
  bool get hasStartedTrial {
    return _getTrialStartDate() != null;
  }

  /// Check if trial has expired
  bool get hasTrialExpired {
    if (!hasStartedTrial) return false;
    return !isInTrial && !isPremium;
  }

  /// Get days remaining in trial (0 if not in trial)
  int get trialDaysRemaining {
    if (!isInTrial) return 0;

    final trialStartDate = _getTrialStartDate();
    if (trialStartDate == null) return trialDurationDays; // Not started

    final now = DateTime.now();
    final daysSinceStart = now.difference(trialStartDate).inDays;
    return (trialDurationDays - daysSinceStart).clamp(0, trialDurationDays);
  }

  /// Get total trial messages used (no daily reset)
  int get trialMessagesUsed {
    if (!isInTrial) return 0;
    return _prefs?.getInt(_keyTrialMessagesUsed) ?? 0;
  }

  /// Get remaining trial messages (out of 15 total)
  int get trialMessagesRemaining {
    if (!isInTrial) return 0;
    return (trialTotalMessages - trialMessagesUsed).clamp(0, trialTotalMessages);
  }

  /// Start trial (called on first AI message)
  Future<void> startTrial() async {
    if (hasStartedTrial) return;

    // Check if trial is blocked (already used before)
    if (isTrialBlocked) {
      debugPrint('📊 [SubscriptionService] Cannot start trial - already used on this device');
      return;
    }

    await _prefs?.setString(_keyTrialStartDate, DateTime.now().toIso8601String());
    await _prefs?.setInt(_keyTrialMessagesUsed, 0);
    // Note: No longer setting _keyTrialLastResetDate (no daily resets)

    // Note: Keychain marking moved to trial expiry (when 3 days or 15 messages exhausted)
    // This prevents blocking active trials on app restart

    debugPrint('📊 [SubscriptionService] Trial started');
  }

  // ============================================================================
  // PREMIUM STATUS
  // ============================================================================

  /// Check if user has active premium subscription
  bool get isPremium {
    // Check if premium flag is set
    final premiumActive = _prefs?.getBool(_keyPremiumActive) ?? false;
    if (!premiumActive) return false;

    // Check if subscription has expired
    final expiryDate = _getExpiryDate();
    if (expiryDate != null) {
      if (DateTime.now().isAfter(expiryDate)) {
        // Subscription expired - should trigger restorePurchases() on next app launch
        debugPrint('📊 [SubscriptionService] Premium subscription expired on $expiryDate');
        return false;
      }
    }

    // Premium is active and not expired
    return true;
  }

  /// Get detailed subscription status for granular state management
  SubscriptionStatus getSubscriptionStatus() {
    // Check if premium first
    if (isPremium) {
      final expiryDate = _getExpiryDate();
      final autoRenew = _prefs?.getBool(_keyAutoRenewStatus) ?? true;

      // Check if subscription has expired
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        return SubscriptionStatus.premiumExpired;
      }

      // Check if subscription is cancelled but still active
      if (!autoRenew) {
        return SubscriptionStatus.premiumCancelled;
      }

      // Active premium with auto-renew
      return SubscriptionStatus.premiumActive;
    }

    // Check if trial is blocked (used before, survives app uninstall)
    if (isTrialBlocked) {
      return SubscriptionStatus.trialExpired;
    }

    // Check trial status
    final trialStartDate = _getTrialStartDate();

    // User has never started trial
    if (trialStartDate == null) {
      return SubscriptionStatus.neverStarted;
    }

    // Check if still in trial period
    if (isInTrial) {
      return SubscriptionStatus.inTrial;
    }

    // Trial has expired
    return SubscriptionStatus.trialExpired;
  }

  /// Check if user should be automatically subscribed on day 3
  ///
  /// Returns true if:
  /// - Trial has expired (3+ days since start)
  /// - User hasn't cancelled trial
  /// - Auto-subscribe hasn't been attempted yet
  Future<bool> shouldAutoSubscribe() async {
    try {
      // Only applies if premium is not active
      if (isPremium) return false;

      // Get trial start date
      final trialStartDate = _getTrialStartDate();
      if (trialStartDate == null) return false; // Never started trial

      // Check if trial has expired (3+ days since start)
      final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
      if (daysSinceStart < trialDurationDays) return false; // Still in trial

      // Check if we've already attempted auto-subscribe
      final autoSubscribeAttempted = _prefs?.getBool(_keyAutoSubscribeAttempted) ?? false;
      if (autoSubscribeAttempted) return false;

      // Check if user cancelled trial via App Store/Play Store
      final userCancelled = await _checkTrialCancellation();

      return !userCancelled;
    } catch (e) {
      developer.log(
        'Error checking auto-subscribe eligibility: $e',
        name: 'SubscriptionService',
        error: e,
      );
      // On error, don't auto-subscribe (fail safe)
      return false;
    }
  }

  /// Check if user cancelled trial via platform APIs
  ///
  /// Returns true if user has cancelled, false otherwise.
  ///
  /// Implementation: Uses client-side approach with in_app_purchase plugin
  /// - Queries past purchases from App Store/Play Store
  /// - If premium subscription not found, assumes cancelled
  /// - Privacy-first: No backend, all local
  /// - Trade-off: Detection is eventual (on app launch), not real-time
  ///
  /// See: openspec/changes/subscription-refactor/RESEARCH_CANCELLATION_DETECTION.md
  Future<bool> _checkTrialCancellation() async {
    try {
      developer.log(
        'Checking for subscription cancellation via restorePurchases',
        name: 'SubscriptionService',
      );

      // Since restorePurchases() has already been called in initialize(),
      // the isPremium flag reflects the current subscription status from the platform
      //
      // Implementation: Client-side detection using isPremium flag
      // - restorePurchases() updates local state from App Store/Play Store
      // - If premium subscription exists, isPremium will be true
      // - If subscription was cancelled/expired, isPremium will be false
      // - Privacy-first: No backend, all local validation
      // - Trade-off: Detection is eventual (on app launch), not real-time
      //
      // See: openspec/changes/subscription-refactor/RESEARCH_CANCELLATION_DETECTION.md

      final hasActivePremium = isPremium;

      if (hasActivePremium) {
        developer.log(
          'Active premium subscription found - user has NOT cancelled',
          name: 'SubscriptionService',
        );
        return false; // Has active subscription, did not cancel
      } else {
        developer.log(
          'No active premium subscription found - assuming user cancelled or never subscribed',
          name: 'SubscriptionService',
        );
        return true; // No active subscription found, assume cancelled
      }
    } catch (e) {
      developer.log(
        'Exception during cancellation check: $e',
        name: 'SubscriptionService',
        error: e,
      );
      // On error, assume not cancelled (fail-safe)
      // This prevents blocking auto-subscribe due to temporary errors
      return false;
    }
  }

  /// Attempt automatic subscription if user is on day 3 and hasn't cancelled
  ///
  /// Should be called on app initialization to handle automatic subscription
  /// when trial expires without user cancellation.
  Future<void> attemptAutoSubscribe() async {
    try {
      final shouldSubscribe = await shouldAutoSubscribe();

      if (!shouldSubscribe) {
        debugPrint('📊 [SubscriptionService] Auto-subscribe check: not applicable');
        return;
      }

      // Mark attempt as started to prevent repeated attempts
      await _prefs?.setBool(_keyAutoSubscribeAttempted, true);

      developer.log(
        'Auto-subscribe triggered: Trial expired without cancellation',
        name: 'SubscriptionService',
      );

      // Initiate purchase flow
      await purchasePremium();
    } catch (e) {
      developer.log(
        'Auto-subscribe failed: $e',
        name: 'SubscriptionService',
        error: e,
      );
      // Don't throw - this is a background operation that shouldn't crash the app
      // User will see the paywall when they try to send a message
    }
  }

  /// Get premium messages used this month
  int get premiumMessagesUsed {
    if (!isPremium) return 0;

    final lastResetDate = _prefs?.getString(_keyPremiumLastResetDate);
    final thisMonth = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM

    // If last reset was not this month, return 0
    if (lastResetDate != thisMonth) return 0;

    return _prefs?.getInt(_keyPremiumMessagesUsed) ?? 0;
  }

  /// Get remaining premium messages this month
  int get premiumMessagesRemaining {
    if (!isPremium) return 0;
    return (premiumMessagesPerMonth - premiumMessagesUsed).clamp(0, premiumMessagesPerMonth);
  }

  /// Get subscription receipt (for verification)
  String? get subscriptionReceipt {
    return _prefs?.getString(_keySubscriptionReceipt);
  }

  // ============================================================================
  // MESSAGE LIMITS
  // ============================================================================

  /// Check if user can send a message (has remaining messages)
  bool get canSendMessage {
    // NOTE: Debug bypass DISABLED for testing Phase 1 subscription fixes
    // Ref: openspec/changes/subscription-state-management-fixes
    debugPrint('📊 [SubscriptionService] canSendMessage check: kDebugMode=$kDebugMode, isPremium=$isPremium, isInTrial=$isInTrial, trialMessagesRemaining=$trialMessagesRemaining');

    // DISABLED: Debug bypass prevents testing race conditions and state updates
    // if (kDebugMode) {
    //   debugPrint('📊 [SubscriptionService] Bypassing subscription check - debug mode');
    //   return true;
    // }

    if (isPremium) {
      return premiumMessagesRemaining > 0;
    } else if (isInTrial) {
      return trialMessagesRemaining > 0;
    }
    return false;
  }

  /// Get remaining messages (trial or premium)
  int get remainingMessages {
    if (isPremium) {
      return premiumMessagesRemaining;
    } else if (isInTrial) {
      return trialMessagesRemaining;
    }
    return 0;
  }

  /// Get total messages used (trial or premium)
  int get messagesUsed {
    if (isPremium) {
      return premiumMessagesUsed;
    } else if (isInTrial) {
      return trialMessagesUsed;
    }
    return 0;
  }

  /// Consume one message (call this when sending AI message)
  Future<bool> consumeMessage() async {
    if (!canSendMessage) return false;

    try {
      if (isPremium) {
        // Consume premium message
        final used = premiumMessagesUsed + 1;
        await _prefs?.setInt(_keyPremiumMessagesUsed, used);
        await _updatePremiumResetDate();
        debugPrint('📊 [SubscriptionService] Premium message consumed ($used/$premiumMessagesPerMonth)');
        return true;
      } else if (isInTrial) {
        // Start trial if not started
        if (!hasStartedTrial) {
          await startTrial();
        }

        // Consume trial message (no daily reset)
        final used = trialMessagesUsed + 1;
        await _prefs?.setInt(_keyTrialMessagesUsed, used);
        // No longer calling _updateTrialResetDate() - no daily resets
        debugPrint('📊 [SubscriptionService] Trial message consumed ($used/$trialTotalMessages total)');

        // Check if trial just expired (message limit or time limit)
        await _checkAndMarkTrialExpiry();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to consume message: $e');
      return false;
    }
  }

  // ============================================================================
  // PURCHASE FLOW
  // ============================================================================

  /// Get premium product details (defaults to yearly for backwards compatibility)
  ProductDetails? get premiumProduct => _premiumProductYearly;

  /// Get yearly product details
  ProductDetails? get premiumProductYearly => _premiumProductYearly;

  /// Get monthly product details
  ProductDetails? get premiumProductMonthly => _premiumProductMonthly;

  /// Get the purchased product ID (yearly vs monthly)
  /// Returns null if no subscription purchased
  String? get purchasedProductId => _prefs?.getString(_keyPurchasedProductId);

  /// Check if user has yearly subscription
  bool get hasYearlySubscription {
    final productId = purchasedProductId;
    return productId == premiumYearlyProductId;
  }

  /// Check if user has monthly subscription
  bool get hasMonthlySubscription {
    final productId = purchasedProductId;
    return productId == premiumMonthlyProductId;
  }

  /// Purchase premium subscription
  /// [productId] - Product ID to purchase (defaults to yearly if not specified)
  Future<void> purchasePremium({String? productId}) async {
    // Default to yearly product if not specified (for trial auto-subscribe)
    final selectedProductId = productId ?? premiumYearlyProductId;

    ProductDetails? productToPurchase;
    if (selectedProductId == premiumYearlyProductId) {
      productToPurchase = _premiumProductYearly;
    } else if (selectedProductId == premiumMonthlyProductId) {
      productToPurchase = _premiumProductMonthly;
    }

    if (productToPurchase == null) {
      onPurchaseUpdate?.call(false, 'Product not available');
      return;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productToPurchase,
      );

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('📊 [SubscriptionService] Purchase initiated for: ${productToPurchase.id}');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Purchase failed: $e');
      onPurchaseUpdate?.call(false, e.toString());
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      debugPrint('📊 [SubscriptionService] Restore purchases initiated');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Restore failed: $e');
      onPurchaseUpdate?.call(false, e.toString());
    }
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyAndActivatePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('📊 [SubscriptionService] Purchase error: ${purchase.error}');
        onPurchaseUpdate?.call(false, purchase.error?.message);
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Verify and activate purchase
  Future<void> _verifyAndActivatePurchase(PurchaseDetails purchase) async {
    try {
      // Save subscription receipt
      final receiptData = purchase.verificationData.serverVerificationData;
      await _prefs?.setString(_keySubscriptionReceipt, receiptData);

      // Store product ID to track yearly vs monthly subscription
      final productId = purchase.productID;
      await _prefs?.setString(_keyPurchasedProductId, productId);
      debugPrint('📊 [SubscriptionService] Purchased product: $productId');

      // Try to decode receipt and extract expiry information
      // Note: Receipt format differs by platform (iOS: base64 JSON, Android: JWT)
      try {
        // For iOS: Receipt is base64-encoded JSON
        // For Android: Receipt is a JWT token
        // This is a simplified implementation - production should use platform-specific decoding

        // For now, we'll extract basic info if available

        // Placeholder for receipt parsing
        // In production, use:
        // - iOS: Decode base64, parse JSON, extract fields from receipt.in_app array
        // - Android: Decode JWT, parse claims

        debugPrint('📊 [SubscriptionService] Receipt data saved (expiry extraction requires platform-specific implementation)');

        // Calculate expiry based on subscription type (yearly vs monthly)
        final isYearly = productId == premiumYearlyProductId;
        final expiryDuration = isYearly ? const Duration(days: 365) : const Duration(days: 30);
        final expiryDate = DateTime.now().add(expiryDuration);

        await _prefs?.setString(_keyPremiumExpiryDate, expiryDate.toIso8601String());
        await _prefs?.setString(_keyPremiumOriginalPurchaseDate, DateTime.now().toIso8601String());
        await _prefs?.setBool(_keyAutoRenewStatus, true); // Assume auto-renew unless receipt says otherwise

        debugPrint('📊 [SubscriptionService] Expiry set to ${isYearly ? "365 days (yearly)" : "30 days (monthly)"}');

        // Check if this was a trial purchase
        // This will be extracted from receipt once parsing is implemented
        // await _prefs?.setBool(_keyTrialEverUsed, wasTrialPurchase);

      } catch (receiptError) {
        debugPrint('📊 [SubscriptionService] Receipt parsing skipped (will implement platform-specific logic): $receiptError');
      }

      // Activate premium
      await _prefs?.setBool(_keyPremiumActive, true);
      await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
      await _prefs?.setString(_keyPremiumLastResetDate, DateTime.now().toIso8601String().substring(0, 7));

      debugPrint('📊 [SubscriptionService] Premium subscription activated');
      onPurchaseUpdate?.call(true, null);
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to activate purchase: $e');
      onPurchaseUpdate?.call(false, e.toString());
    }
  }

  // ============================================================================
  // INTERNAL HELPERS
  // ============================================================================

  /// Get trial start date
  DateTime? _getTrialStartDate() {
    final dateString = _prefs?.getString(_keyTrialStartDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Get premium subscription expiry date
  DateTime? _getExpiryDate() {
    final dateString = _prefs?.getString(_keyPremiumExpiryDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Update premium reset date (for monthly message counter)
  Future<void> _updatePremiumResetDate() async {
    final thisMonth = DateTime.now().toIso8601String().substring(0, 7);
    await _prefs?.setString(_keyPremiumLastResetDate, thisMonth);
  }

  /// Check and reset message counters (monthly for premium only, trial has no reset)
  Future<void> _checkAndResetCounters() async {
    try {
      // Trial no longer has daily resets - messages counted against 15 total

      // Reset premium counter if needed (monthly)
      if (isPremium) {
        final lastResetDate = _prefs?.getString(_keyPremiumLastResetDate);
        final thisMonth = DateTime.now().toIso8601String().substring(0, 7);

        if (lastResetDate != thisMonth) {
          await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
          await _prefs?.setString(_keyPremiumLastResetDate, thisMonth);
          debugPrint('📊 [SubscriptionService] Premium messages reset for new month');
        }
      }
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to reset counters: $e');
    }
  }

  /// Check if trial has expired and mark in Keychain if so
  /// Marks trial as used when EITHER condition is met:
  /// 1. User has consumed all 15 messages
  /// 2. 3 days have passed since trial started
  Future<void> _checkAndMarkTrialExpiry() async {
    try {
      // Only check if user is in trial (not premium)
      if (isPremium || !hasStartedTrial) return;

      bool shouldMark = false;
      String reason = '';

      // Check message limit (15 total messages)
      final used = trialMessagesUsed;
      if (used >= trialTotalMessages) {
        shouldMark = true;
        reason = '$used/$trialTotalMessages messages exhausted';
      }

      // Check time limit (3 days)
      final trialStartDate = _getTrialStartDate();
      if (trialStartDate != null) {
        final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
        if (daysSinceStart >= trialDurationDays) {
          shouldMark = true;
          reason = '$daysSinceStart days elapsed';
        }
      }

      // Mark trial as expired in Keychain if limit reached
      if (shouldMark) {
        await markTrialAsUsed();
        debugPrint('📊 [SubscriptionService] Trial expired and marked in Keychain ($reason)');
      }
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to check trial expiry: $e');
      // Non-critical - don't block message sending
    }
  }

  // ============================================================================
  // KEYCHAIN TRIAL TRACKING (SURVIVES APP UNINSTALL)
  // ============================================================================

  /// Check if trial has been used before on this device
  /// Uses iOS Keychain / Android KeyStore which persists across app uninstalls
  ///
  /// Privacy-first: All data stays on device, nothing transmitted to servers
  Future<bool> hasUsedTrialBefore() async {
    try {
      final trialUsed = await _secureStorage.read(key: _keychainTrialEverUsed);
      final hasUsed = trialUsed == 'true';

      if (hasUsed) {
        final markedDate = await _secureStorage.read(key: _keychainTrialMarkedDate);
        debugPrint('📊 [SubscriptionService] Trial already used on this device (marked: $markedDate)');
      }

      return hasUsed;
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Error reading Keychain trial status: $e');
      // Fail open - don't block users if Keychain read fails
      return false;
    }
  }

  /// Mark trial as used in Keychain (persists across app uninstalls)
  /// Called when user starts their first trial
  ///
  /// Privacy-first: Stored locally on device in secure Keychain/KeyStore
  Future<void> markTrialAsUsed() async {
    try {
      await _secureStorage.write(key: _keychainTrialEverUsed, value: 'true');
      await _secureStorage.write(
        key: _keychainTrialMarkedDate,
        value: DateTime.now().toIso8601String(),
      );
      debugPrint('📊 [SubscriptionService] Trial marked as used in Keychain');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Error writing to Keychain: $e');
      // Non-critical failure - continue execution
    }
  }

  /// Check if trial is blocked (used before and not premium)
  /// Returns true if user should be blocked from starting a new trial
  bool get isTrialBlocked {
    return _prefs?.getBool('trial_blocked') ?? false;
  }

  // ============================================================================
  // DEBUG / TESTING
  // ============================================================================

  /// Clear all subscription data (for testing only)
  @visibleForTesting
  Future<void> clearAllData() async {
    await _prefs?.remove(_keyTrialStartDate);
    await _prefs?.remove(_keyTrialMessagesUsed);
    await _prefs?.remove(_keyTrialLastResetDate);
    await _prefs?.remove(_keyPremiumActive);
    await _prefs?.remove(_keyPremiumMessagesUsed);
    await _prefs?.remove(_keyPremiumLastResetDate);
    await _prefs?.remove(_keySubscriptionReceipt);
    await _prefs?.remove('trial_blocked');
    debugPrint('📊 [SubscriptionService] All subscription data cleared (SharedPreferences only)');
    debugPrint('📊 [SubscriptionService] Note: Keychain trial marker persists - use clearKeychainForTesting() to reset');
  }

  /// Clear Keychain trial marker (for testing only)
  /// WARNING: This defeats the trial abuse prevention system
  /// Only use during development/testing
  @visibleForTesting
  Future<void> clearKeychainForTesting() async {
    try {
      await _secureStorage.delete(key: _keychainTrialEverUsed);
      await _secureStorage.delete(key: _keychainTrialMarkedDate);
      await _prefs?.setBool('trial_blocked', false);
      debugPrint('📊 [SubscriptionService] Keychain trial marker cleared - trial can be used again');
      debugPrint('⚠️  [SubscriptionService] WARNING: Only use this method for testing!');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Error clearing Keychain: $e');
    }
  }

  /// Manually activate premium (for testing only)
  @visibleForTesting
  Future<void> activatePremiumForTesting() async {
    await _prefs?.setBool(_keyPremiumActive, true);
    await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
    await _prefs?.setString(_keyPremiumLastResetDate, DateTime.now().toIso8601String().substring(0, 7));
    debugPrint('📊 [SubscriptionService] Premium activated for testing');
  }

  /// Get debug info
  Map<String, dynamic> get debugInfo {
    return {
      'isInitialized': _isInitialized,
      'isPremium': isPremium,
      'isInTrial': isInTrial,
      'isTrialBlocked': isTrialBlocked,
      'hasStartedTrial': hasStartedTrial,
      'hasTrialExpired': hasTrialExpired,
      'trialDaysRemaining': trialDaysRemaining,
      'trialMessagesUsed': trialMessagesUsed,
      'trialMessagesRemaining': trialMessagesRemaining,
      'premiumMessagesUsed': premiumMessagesUsed,
      'premiumMessagesRemaining': premiumMessagesRemaining,
      'canSendMessage': canSendMessage,
      'hasYearlyProduct': _premiumProductYearly != null,
      'hasMonthlyProduct': _premiumProductMonthly != null,
      'yearlyProductId': _premiumProductYearly?.id,
      'yearlyProductPrice': _premiumProductYearly?.price,
      'monthlyProductId': _premiumProductMonthly?.id,
      'monthlyProductPrice': _premiumProductMonthly?.price,
      'purchasedProductId': purchasedProductId,
      'hasYearlySubscription': hasYearlySubscription,
      'hasMonthlySubscription': hasMonthlySubscription,
    };
  }
}
