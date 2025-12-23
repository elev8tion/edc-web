# App Security & Authentication Services

## AppLockoutService

### Overview
The `AppLockoutService` provides a privacy-first security mechanism for the Everyday Christian app using device-native authentication (PIN, fingerprint, Face ID) instead of traditional user accounts.

### Privacy-First Architecture

#### What We Store (Local Only)
- `app_lockout_attempts`: Integer counter (0-3)
- `app_lockout_time`: Unix timestamp (when lockout ends)

#### What We DON'T Store
- ❌ User credentials
- ❌ Account information
- ❌ Device PINs or passwords
- ❌ Biometric data
- ❌ Authentication history
- ❌ User identifiers

### How It Works

#### Security Flow
1. User enters incorrect pastoral guidance PIN
2. Service increments failed attempt counter
3. After 3 failed attempts → 30-minute lockout triggered
4. User can bypass lockout with device authentication
5. Successful authentication clears all lockout data

#### Implementation
```dart
// Initialize service
final lockoutService = AppLockoutService();
await lockoutService.init();

// Record failed attempt
await lockoutService.recordFailedAttempt();

// Check lockout status
if (await lockoutService.isLockedOut()) {
  final minutes = lockoutService.getRemainingLockoutMinutes();
  print('Locked out for $minutes minutes');

  // Offer device authentication bypass
  final unlocked = await lockoutService.authenticateWithDevice(
    localizedReason: 'Unlock Everyday Christian',
  );

  if (unlocked) {
    // Continue to app
  }
}
```

### Features

#### Lockout Management
- **3-strike system**: 3 failed attempts triggers lockout
- **30-minute duration**: Temporary lockout period
- **Auto-clear**: Lockout expires automatically after timeout
- **Manual bypass**: Device authentication immediately clears lockout

#### Device Authentication
- **Multi-modal**: Supports PIN, fingerprint, Face ID, pattern
- **Fallback options**: PIN available if biometric fails
- **OS-handled**: Authentication managed by iOS/Android
- **Zero visibility**: App never sees authentication credentials

### Platform Requirements

#### iOS
```xml
<!-- Info.plist -->
<key>NSFaceIDUsageDescription</key>
<string>Unlock the app using Face ID after security lockout</string>
```

#### Android
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### Testing

#### Test Coverage
- ✅ 18 comprehensive tests
- ✅ Mock LocalAuthentication for unit tests
- ✅ SharedPreferences persistence testing
- ✅ Edge case handling

#### Running Tests
```bash
flutter test test/services/app_lockout_service_test.dart
```

### Security Benefits

#### Privacy Advantages
1. **No account system** = No user data to breach
2. **Local-only storage** = No server vulnerabilities
3. **OS authentication** = Platform-level security
4. **Minimal data footprint** = Two integers only

#### Compliance Benefits
- ✅ GDPR: No personal data processing
- ✅ CCPA: No consumer information collected
- ✅ COPPA: No child data concerns
- ✅ App Store: Follows platform guidelines

### Migration Guide

#### From Account-Based Lockout
```dart
// OLD: Account-based
await userService.lockAccount(userId, duration: 30.days);

// NEW: Device-based
await lockoutService.recordFailedAttempt();
if (await lockoutService.isLockedOut()) {
  await lockoutService.authenticateWithDevice(
    localizedReason: 'Unlock app',
  );
}
```

### Error Handling

#### Common Scenarios
```dart
try {
  final authenticated = await lockoutService.authenticateWithDevice(
    localizedReason: 'Unlock app',
  );

  if (!authenticated) {
    // User cancelled or failed authentication
    showMessage('Authentication failed');
  }
} catch (e) {
  // Handle errors (device not supported, etc.)
  showMessage('Device authentication not available');
}
```

### Best Practices

#### DO
- ✅ Always initialize service before use
- ✅ Provide clear localized reasons for authentication
- ✅ Handle authentication cancellation gracefully
- ✅ Clear lockout on successful authentication

#### DON'T
- ❌ Store authentication results
- ❌ Log authentication attempts
- ❌ Bypass OS authentication APIs
- ❌ Create custom PIN/biometric handlers

### Troubleshooting

#### Device Not Supported
```dart
// Check device capabilities
final localAuth = LocalAuthentication();
final canCheck = await localAuth.canCheckBiometrics;
final isSupported = await localAuth.isDeviceSupported();

if (!canCheck || !isSupported) {
  // Fallback to password-only or disable feature
}
```

#### Authentication Always Fails
1. Check device has PIN/biometric configured
2. Verify app permissions granted
3. Test on real device (simulators may not support)
4. Check LocalAuthentication package version compatibility

### API Reference

#### Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `init()` | Initialize service with SharedPreferences | `Future<void>` |
| `isLockedOut()` | Check if currently locked out | `Future<bool>` |
| `recordFailedAttempt()` | Record a failed attempt | `Future<void>` |
| `getRemainingLockoutMinutes()` | Get minutes until unlock | `int` |
| `authenticateWithDevice()` | Trigger OS authentication | `Future<bool>` |
| `clearLockout()` | Clear all lockout data | `Future<void>` |
| `getCurrentAttempts()` | Get current attempt count | `int` |
| `getRemainingAttempts()` | Get attempts before lockout | `int` |

### Version History

#### v1.0.0 (October 2025)
- Initial implementation
- OS PIN/biometric authentication
- 3-strike lockout system
- Comprehensive test suite
- Privacy-first design

### Support

For issues or questions:
- File issue: [GitHub Issues](https://github.com/everyday-christian/issues)
- Documentation: See `/docs/OS_PIN_AUTHENTICATION_PRIVACY.md`
- Tests: See `/test/services/app_lockout_service_test.dart`