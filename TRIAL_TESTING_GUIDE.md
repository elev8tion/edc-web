# Trial Expiration Testing Guide

This guide shows you how to test the subscription trial period expiration without waiting 4 days.

## Current Trial Settings
- **Duration:** 3 days
- **Messages:** 15 total messages
- **Storage:** SharedPreferences (key: `trial_start_date`)

## Method 1: Using Flutter DevTools Console (EASIEST) ⭐

1. **Start your app on the simulator:**
   ```bash
   flutter run
   ```

2. **Open Flutter DevTools** in your browser (the URL is shown in terminal)

3. **Go to Console tab**

4. **Paste and run this code to simulate expiration:**
   ```dart
   import 'package:shared_preferences/shared_preferences.dart';

   // Set trial to 4 days ago (expired)
   final prefs = await SharedPreferences.getInstance();
   final fourDaysAgo = DateTime.now().subtract(Duration(days: 4));
   await prefs.setString('trial_start_date', fourDaysAgo.toIso8601String());
   print('✅ Trial set to 4 days ago: $fourDaysAgo');
   print('⚠️  Hot restart app (press R) to see changes');
   ```

5. **Hot restart the app** (press `R` in the Flutter terminal or DevTools)

6. **Test:** Go to chat screen and try to send a message → should show paywall!

## Method 2: Using Debug Helper Class (CODE-BASED)

1. **Import the helper in your code:**
   ```dart
   import 'package:everyday_christian/utils/debug_subscription_helpers.dart';
   ```

2. **Call from anywhere in debug mode:**
   ```dart
   // Simulate 4 days ago (trial expired)
   await DebugSubscriptionHelpers.simulateTrialExpiration(daysAgo: 4);

   // Check current status
   await DebugSubscriptionHelpers.checkTrialStatus();

   // Reset back to active trial
   await DebugSubscriptionHelpers.resetTrialToActive();
   ```

3. **Example: Add a debug button to Settings screen:**
   ```dart
   if (kDebugMode) {
     ElevatedButton(
       onPressed: () async {
         await DebugSubscriptionHelpers.simulateTrialExpiration(daysAgo: 4);
         // Hot restart to see changes
       },
       child: Text('DEBUG: Expire Trial'),
     );
   }
   ```

## Method 3: Direct SharedPreferences Manipulation (COMMAND LINE)

Run this command while your app is running:

```bash
# Simulate expiration
dart run test_trial_expiration.dart

# Reset back to active
dart run test_trial_expiration.dart reset
```

Then hot restart your app with `R` in the Flutter terminal.

## Testing Checklist

After simulating expiration, test these scenarios:

### ✅ Chat Screen
- [ ] Try to send a message → should show paywall
- [ ] Paywall should say "Trial Expired"
- [ ] "Upgrade to Premium" button should be visible

### ✅ Subscription Settings Screen
- [ ] Status should show "Trial Expired"
- [ ] Days remaining should show "0"
- [ ] Messages remaining should show "0/15"
- [ ] Upgrade button should be prominent

### ✅ Home Screen
- [ ] Quick actions should still work (local features)
- [ ] Chat quick action should work (shows paywall inside)

## Reset Back to Active Trial

Use any of these methods to reset:

**DevTools Console:**
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('trial_start_date', DateTime.now().toIso8601String());
await prefs.setInt('trial_messages_used', 0);
print('✅ Trial reset to active');
```

**Debug Helper:**
```dart
await DebugSubscriptionHelpers.resetTrialToActive();
```

**Command Line:**
```bash
dart run test_trial_expiration.dart reset
```

## Simulating Other Scenarios

### Simulate 15/15 Messages Used (No Days Passed)
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('trial_messages_used', 15);
print('✅ All trial messages consumed');
```

### Simulate Day 2 of Trial (1 day left)
```dart
final prefs = await SharedPreferences.getInstance();
final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
await prefs.setString('trial_start_date', twoDaysAgo.toIso8601String());
print('✅ Trial has 1 day remaining');
```

### Check Current Status
```dart
await DebugSubscriptionHelpers.checkTrialStatus();
// or
await DebugSubscriptionHelpers.dumpAllSubscriptionData();
```

## Understanding the Code

The trial expiration check happens in two places:

1. **`subscription_service.dart`** (lines 245-257):
   ```dart
   bool get isInTrial {
     final trialStartDate = _getTrialStartDate();
     if (trialStartDate == null) return true; // Never started = can start

     final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
     return daysSinceStart < trialDurationDays; // false if >= 3 days
   }
   ```

2. **`chat_screen.dart`** (lines 234-246):
   ```dart
   if (subscriptionStatus == SubscriptionStatus.trialExpired) {
     // Show paywall - user is locked out
     await Navigator.push(context, MaterialPageRoute(
       builder: (_) => const PaywallScreen(showTrialInfo: false),
     ));
     return; // Block message send
   }
   ```

## Troubleshooting

**Q: I changed the date but nothing happened?**
- A: You must **hot restart** (capital R) not hot reload (lowercase r)

**Q: The app still shows trial as active?**
- A: Check the actual date stored:
  ```dart
  final prefs = await SharedPreferences.getInstance();
  print(prefs.getString('trial_start_date'));
  ```

**Q: I want to completely reset everything?**
- A: Use:
  ```dart
  await DebugSubscriptionHelpers.clearAllTrialData();
  ```

**Q: Can I test on a real device?**
- A: Yes, but it's easier on simulator. All methods work on real devices in debug mode.

## Notes

- All these methods only work in **debug mode** (`kDebugMode == true`)
- Changes require a **hot restart** (R) to take effect
- The Keychain trial marker (anti-abuse) persists - use `clearKeychainForTesting()` if needed
- Premium subscriptions are handled by App Store/Play Store and can't be simulated this way
