# Quick Test: Trial Expiration (4 Days Forward)

## Step-by-Step Instructions

### 1. Start the App (if not running)
```bash
cd /Users/kcdacre8tor/thereal-everyday-christian
flutter run
```

### 2. Open Flutter DevTools
Look for this line in your terminal:
```
The Flutter DevTools debugger and profiler on iPhone 16 is available at: http://127.0.0.1:9100?uri=...
```
Open that URL in your browser.

### 3. Go to Console Tab
Click the "Console" tab in DevTools.

### 4. Copy and Paste This Code
```dart
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  final fourDaysAgo = DateTime.now().subtract(Duration(days: 4));
  await prefs.setString('trial_start_date', fourDaysAgo.toIso8601String());
  print('✅ Trial set to 4 days ago (EXPIRED)');
  print('   Date: $fourDaysAgo');
  print('   Status: Trial should now be expired by 1 day');
  print('');
  print('⚠️  IMPORTANT: Press "R" in your Flutter terminal to hot restart');
}

main();
```

### 5. Press Enter to Execute

### 6. Hot Restart the App
In your Flutter terminal where you ran `flutter run`, press the **capital R** key:
```
R
```

### 7. Test!
1. Go to the **Chat** screen in the app
2. Try to **send a message**
3. You should see the **Paywall** appear! 🎉

---

## What You Should See

### ✅ Expected Behavior (Trial Expired):
- Chat message input attempts → Paywall appears
- Paywall says "Trial Expired" or "Upgrade to Premium"
- Subscription settings shows 0 days remaining

### ❌ If It Doesn't Work:
1. Make sure you did a **hot restart (R)** not hot reload (r)
2. Check the console output - it should say "Trial set to 4 days ago"
3. Try this debug command in DevTools console:
   ```dart
   import 'package:shared_preferences/shared_preferences.dart';
   final p = await SharedPreferences.getInstance();
   print('Trial start: ${p.getString('trial_start_date')}');
   ```

---

## To Reset Back to Active Trial

Paste this in DevTools Console:
```dart
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('trial_start_date', DateTime.now().toIso8601String());
  await prefs.setInt('trial_messages_used', 0);
  print('✅ Trial reset to ACTIVE (3 days remaining)');
  print('⚠️  Press "R" to hot restart');
}

main();
```

Then press `R` again.

---

## Even Simpler Alternative: Direct SQLite Edit

If DevTools isn't working, you can edit the SharedPreferences directly:

```bash
# Find the prefs file
find ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Preferences -name "*.plist" 2>/dev/null | xargs grep -l "trial_start"

# Then use:
# - Xcode → Window → Devices and Simulators → Download Container
# - Edit the plist file manually
# - Reinstall container
```

But the DevTools method is much easier! 😊