/// Test Script: Simulate Trial Expiration
///
/// This script simulates a trial that started 4 days ago (1 day past expiration).
/// After running this, the chat screen should show the paywall when you try to send a message.
///
/// HOW TO USE:
/// 1. Make sure the app is running on the simulator
/// 2. Run this script: `dart run test_trial_expiration.dart`
/// 3. Hot restart the app (press 'R' in the flutter run terminal)
/// 4. Go to chat screen and try to send a message
/// 5. You should see the paywall appear!
///
/// TO RESET: Run `dart run test_trial_expiration.dart reset`

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

void main(List<String> args) async {
  // Initialize shared preferences
  SharedPreferences.setPrefix('flutter.');
  final prefs = await SharedPreferences.getInstance();

  // Check if user wants to reset or simulate expiration
  final isReset = args.isNotEmpty && args[0].toLowerCase() == 'reset';

  if (isReset) {
    print('\n🔄 RESETTING TRIAL TO ACTIVE STATE...\n');
    await resetTrialToActive(prefs);
  } else {
    print('\n⏰ SIMULATING TRIAL EXPIRATION (4 days ago)...\n');
    await simulateTrialExpiration(prefs, daysAgo: 4);
  }

  // Print current status
  await checkTrialStatus(prefs);

  print('\n✅ Done! Hot restart your app to see the changes.\n');
  print('💡 TIP: In your Flutter terminal, press "R" (capital R) to hot restart.\n');

  exit(0);
}

Future<void> simulateTrialExpiration(SharedPreferences prefs, {int daysAgo = 4}) async {
  final expirationDate = DateTime.now().subtract(Duration(days: daysAgo));
  await prefs.setString('trial_start_date', expirationDate.toIso8601String());

  print('✅ Trial start date set to $daysAgo days ago');
  print('   Date: $expirationDate');
  print('   Days past expiration: ${daysAgo - 3}');
  print('\n📱 What to expect:');
  print('   - Trial status: EXPIRED ❌');
  print('   - Chat will show paywall on message send');
  print('   - Subscription settings will show "Trial Expired"');
}

Future<void> resetTrialToActive(SharedPreferences prefs) async {
  final now = DateTime.now();
  await prefs.setString('trial_start_date', now.toIso8601String());
  await prefs.setInt('trial_messages_used', 0);

  print('✅ Trial reset to active state');
  print('   Start date: $now');
  print('   Days remaining: 3');
  print('   Messages: 0/15 used');
  print('\n📱 What to expect:');
  print('   - Trial status: ACTIVE ✅');
  print('   - Chat will work normally');
  print('   - 3 days and 15 messages remaining');
}

Future<void> checkTrialStatus(SharedPreferences prefs) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 CURRENT TRIAL STATUS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final trialStartStr = prefs.getString('trial_start_date');
  final messagesUsed = prefs.getInt('trial_messages_used') ?? 0;

  if (trialStartStr == null) {
    print('❌ NO TRIAL STARTED YET');
    print('   (User has not sent first AI message)');
    return;
  }

  final trialStart = DateTime.parse(trialStartStr);
  final now = DateTime.now();
  final daysSinceStart = now.difference(trialStart).inDays;
  final daysRemaining = (3 - daysSinceStart).clamp(0, 3);
  final messagesRemaining = (15 - messagesUsed).clamp(0, 15);

  final isExpiredByTime = daysSinceStart >= 3;
  final isExpiredByMessages = messagesUsed >= 15;
  final isExpired = isExpiredByTime || isExpiredByMessages;

  print('Start Date:        $trialStart');
  print('Current Date:      $now');
  print('Days Elapsed:      $daysSinceStart / 3 days');
  print('Days Remaining:    $daysRemaining days');
  print('Messages Used:     $messagesUsed / 15');
  print('Messages Left:     $messagesRemaining');
  print('');
  print('Status:            ${isExpired ? "❌ EXPIRED" : "✅ ACTIVE"}');

  if (isExpiredByTime) {
    print('Expired Reason:    Time limit (3 days)');
  }
  if (isExpiredByMessages) {
    print('Expired Reason:    Message limit (15 messages)');
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}