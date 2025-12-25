/// Trial Validation Integration
///
/// Integration code for the subscription service to validate trial eligibility
/// using IP + Fingerprint hybrid approach via Cloudflare Worker.
///
/// ADD THIS CODE TO subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'device_fingerprint_service.dart';

// ============================================================================
// STEP 1: Add this import at the top of subscription_service.dart
// ============================================================================
// import 'device_fingerprint_service.dart';


// ============================================================================
// STEP 2: Add this method to SubscriptionService class
// ============================================================================

/// Validate trial eligibility via Cloudflare Worker (IP + Fingerprint)
///
/// Returns: TrialEligibilityResult with allowed status and message
Future<TrialEligibilityResult> _validateTrialEligibility() async {
  try {
    // Generate device fingerprint
    final fingerprint = await DeviceFingerprintService.generateFingerprint();

    debugPrint('📊 [SubscriptionService] Validating trial eligibility...');
    debugPrint('📊 [SubscriptionService] Fingerprint: ${DeviceFingerprintService.shortFingerprint(fingerprint)}');

    // Get trial validator URL from environment
    final validatorUrl = dotenv.get(
      'TRIAL_VALIDATOR_URL',
      fallback: 'https://trial-validator.connect-2a2.workers.dev',
    );

    // Call Cloudflare Worker
    final response = await http.post(
      Uri.parse(validatorUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fingerprint': fingerprint}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result['allowed'] == true) {
        debugPrint('📊 [SubscriptionService] ✅ Trial allowed - new user');
        return TrialEligibilityResult(
          allowed: true,
          message: result['message'] ?? 'Trial activated',
        );
      } else {
        debugPrint('📊 [SubscriptionService] ❌ Trial blocked: ${result['reason']}');
        return TrialEligibilityResult(
          allowed: false,
          message: result['message'] ?? 'Trial already used',
          reason: result['reason'],
        );
      }
    } else if (response.statusCode == 403) {
      // Trial blocked
      final result = jsonDecode(response.body);
      debugPrint('📊 [SubscriptionService] ❌ Trial blocked: ${result['reason']}');

      return TrialEligibilityResult(
        allowed: false,
        message: result['message'] ?? 'Trial already used',
        reason: result['reason'],
        suggestion: result['suggestion'],
      );
    } else {
      // Server error - fail open (allow trial for better UX)
      debugPrint('📊 [SubscriptionService] ⚠️ Trial validation error: ${response.statusCode}');
      return TrialEligibilityResult(
        allowed: true,
        message: 'Trial activated (validation skipped)',
      );
    }
  } catch (error) {
    // Network error - fail open (allow trial for better UX)
    debugPrint('📊 [SubscriptionService] ⚠️ Trial validation network error: $error');
    return TrialEligibilityResult(
      allowed: true,
      message: 'Trial activated (validation skipped)',
    );
  }
}


// ============================================================================
// STEP 3: Replace the existing startTrial() method with this updated version
// ============================================================================

/// Start trial (called on first AI message)
///
/// Updated to validate trial eligibility via Cloudflare Worker
/// using IP + Fingerprint hybrid approach for abuse prevention.
Future<TrialEligibilityResult> startTrial() async {
  if (hasStartedTrial) {
    return TrialEligibilityResult(
      allowed: true,
      message: 'Trial already active',
    );
  }

  // NEW: Check trial eligibility via Cloudflare Worker
  final eligibility = await _validateTrialEligibility();

  if (!eligibility.allowed) {
    // Trial blocked by IP or fingerprint match
    debugPrint('📊 [SubscriptionService] Cannot start trial: ${eligibility.message}');

    // Mark as blocked locally to show appropriate UI
    await _prefs?.setBool('trial_blocked', true);

    return eligibility;
  }

  // Existing trial start logic (unchanged)
  await _prefs?.setString(_keyTrialStartDate, DateTime.now().toIso8601String());
  await _prefs?.setInt(_keyTrialMessagesUsed, 0);

  debugPrint('📊 [SubscriptionService] ✅ Trial started successfully');

  return TrialEligibilityResult(
    allowed: true,
    message: 'Trial activated - enjoy your 15 messages!',
  );
}


// ============================================================================
// STEP 4: Add this class to subscription_service.dart (above or below ActivationResult)
// ============================================================================

/// Result of trial eligibility validation
class TrialEligibilityResult {
  final bool allowed;
  final String message;
  final String? reason;
  final String? suggestion;

  TrialEligibilityResult({
    required this.allowed,
    required this.message,
    this.reason,
    this.suggestion,
  });

  @override
  String toString() {
    return 'TrialEligibilityResult(allowed: $allowed, message: $message, reason: $reason)';
  }
}


// ============================================================================
// STEP 5: Update UI to handle blocked trials
// ============================================================================
// In your trial UI (e.g., onboarding screen or first message screen):
//
// final subscriptionService = Provider.of<SubscriptionService>(context);
// final eligibility = await subscriptionService.startTrial();
//
// if (!eligibility.allowed) {
//   // Show dialog explaining trial is not available
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text('Trial Not Available'),
//       content: Text(
//         eligibility.message ??
//         'You have already used your free trial. '
//         'Subscribe to continue using Everyday Christian.'
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text('Close'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.pop(context);
//             Navigator.pushNamed(context, '/subscription');
//           },
//           child: Text('Subscribe Now'),
//         ),
//       ],
//     ),
//   );
//   return; // Don't proceed with message send
// }


// ============================================================================
// STEP 6: Add environment variable to .env
// ============================================================================
// Add this line to your .env file:
//
// # Trial Validation API (Cloudflare Worker)
// TRIAL_VALIDATOR_URL=https://trial-validator.connect-2a2.workers.dev
//
// And add to .env.example:
//
// # ============================================================================
// # TRIAL VALIDATION API - Cloudflare Workers
// # ============================================================================
// # Production: https://trial-validator.connect-2a2.workers.dev
// # Development: https://trial-validator.connect-2a2.workers.dev (same endpoint)
// TRIAL_VALIDATOR_URL=https://trial-validator.connect-2a2.workers.dev
