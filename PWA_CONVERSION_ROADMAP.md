# PWA Conversion Roadmap - Everyday Christian App

## Table of Contents
1. [Overview](#overview)
2. [Dependency Analysis](#dependency-analysis)
3. [Platform-Specific Code](#platform-specific-code)
4. [Database Migration Strategy](#database-migration-strategy)
5. [Subscription System Redesign](#subscription-system-redesign)
6. [Notification System](#notification-system)
7. [Security Considerations](#security-considerations)
8. [Performance Optimization](#performance-optimization)
9. [Implementation Timeline](#implementation-timeline)

---

## Overview

### Current State
- **Platform**: Flutter mobile app (iOS + Android)
- **Database**: sqflite (SQLite) with offline Bible data
- **Payments**: in_app_purchase (App Store + Google Play)
- **Auth**: Biometric (Face ID/Touch ID) via local_auth
- **Notifications**: flutter_local_notifications
- **AI**: Google Gemini API (web-compatible)

### Target State
- **Platform**: Progressive Web App (installable on all platforms)
- **Database**: sql.js (WASM SQLite) with IndexedDB persistence
- **Payments**: Stripe (credit card + Apple Pay + Google Pay)
- **Auth**: WebAuthn (FIDO2) + password fallback
- **Notifications**: Service Workers + Web Push API
- **AI**: Google Gemini API (no changes needed)

---

## Dependency Analysis

### Category 1: Fully Web-Compatible (36 packages)

#### State Management
```yaml
flutter_riverpod: ^2.6.1              ✅ Web support
state_notifier: ^1.0.0                ✅ Web support
```

#### AI & Language Models
```yaml
google_generative_ai: ^0.4.6          ✅ Web support (HTTP-based)
langchain: ^0.7.3                     ✅ Web support
langchain_google: ^0.5.1+1            ✅ Web support
```

#### Networking
```yaml
http: ^1.2.2                          ✅ Web support
dio: ^5.7.0                           ✅ Web support
```

#### UI & Animations
```yaml
flutter_animate: ^4.5.0               ✅ Web support
shimmer: ^3.0.0                       ✅ Web support
smooth_page_indicator: ^1.2.0+3       ✅ Web support
glassmorphism: ^3.0.0                 ✅ Web support
loading_animation_widget: ^1.3.0      ✅ Web support
dotted_border: ^2.1.0                 ✅ Web support
```

#### Typography & Fonts
```yaml
google_fonts: ^6.2.1                  ✅ Web support
```

#### Localization
```yaml
intl: ^0.19.0                         ✅ Web support
flutter_localizations:                ✅ Web support
```

#### Utilities
```yaml
uuid: ^4.5.1                          ✅ Web support
url_launcher: ^6.3.1                  ✅ Web support (window.open)
share_plus: ^10.1.2                   ✅ Web support (Web Share API)
package_info_plus: ^8.1.0             ✅ Web support
connectivity_plus: ^6.1.1             ✅ Web support (Network Information API)
shared_preferences: ^2.3.3            ✅ Web support (localStorage)
```

#### Date & Time
```yaml
timezone: ^0.9.4                      ✅ Web support
```

#### Development
```yaml
flutter_dotenv: ^5.2.1                ✅ Web support
```

**Action Required**: None - these work as-is on web

---

### Category 2: Requires Alternatives (6 packages)

#### 1. Database - sqflite
```yaml
sqflite: ^2.4.1                       ❌ Mobile-only
```

**Problem**: sqflite uses native SQLite libraries (iOS/Android only)

**Solution**: sql.js (WASM-based SQLite for web)
```yaml
# Add to pubspec.yaml
sql_js: ^0.1.0  # Or use drift with web support
```

**Migration Strategy**:
- Keep existing SQL queries (no schema changes)
- Wrap sql.js with DatabaseHelper-compatible interface
- Pre-load Bible database as WASM asset (~5-8MB)
- Use IndexedDB for persistence

**Code Changes**:
- `lib/core/database/database_helper.dart` - Replace sqflite calls
- Add conditional import for web vs mobile

**Effort**: 2-3 days

---

#### 2. Payments - in_app_purchase
```yaml
in_app_purchase: ^3.2.0               ❌ App Store/Play Store only
```

**Problem**: in_app_purchase uses platform-specific APIs (StoreKit/Google Play Billing)

**Solution**: Stripe
```yaml
# Add to pubspec.yaml
stripe_checkout: ^1.0.0
# Or use Stripe REST API directly
```

**Migration Strategy**:
- Create backend API for subscription management
- Use Stripe Checkout for payment UI
- Implement webhooks for subscription events
- Store subscription status in database

**Code Changes**:
- `lib/core/services/subscription_service.dart` - Complete rewrite (900 lines)
- `lib/screens/paywall_screen.dart` - New Stripe UI
- `lib/core/providers/app_providers.dart` - Update subscription provider
- Create backend API (Node.js/Python)

**Effort**: 5-8 days + backend setup

---

#### 3. Notifications - flutter_local_notifications
```yaml
flutter_local_notifications: ^17.2.3  ⚠️ Limited web support
```

**Problem**: Background notification scheduling doesn't work in browsers

**Solution**: Service Workers + Web Push API
```yaml
# Add to pubspec.yaml
web_notification: ^0.1.0
# Or use vanilla Web Notifications API
```

**Migration Strategy**:
- Create Service Worker (`web/sw.js`)
- Use Web Push API for notifications
- Request notification permission on first launch
- Email fallback for unsupported browsers

**Code Changes**:
- `lib/core/services/notification_service.dart` - Add web implementation (338 lines)
- Create `web/sw.js` Service Worker
- Add notification permission UI

**Effort**: 2-3 days

---

#### 4. Secure Storage - flutter_secure_storage
```yaml
flutter_secure_storage: ^9.2.2        ❌ No web support
```

**Problem**: Uses platform-specific secure enclaves (Keychain/KeyStore)

**Solution**: sessionStorage or web_crypto
```yaml
# Built-in Web Crypto API
# No package needed - use dart:html
```

**Migration Strategy**:
- Use sessionStorage for session tokens
- Use Web Crypto API for encryption if needed
- Clear on browser close (security best practice)

**Code Changes**:
- `lib/core/services/app_lockout_service.dart` - Add web implementation
- Store auth tokens in sessionStorage

**Effort**: 1 day

---

#### 5. Background Tasks - workmanager
```yaml
workmanager: ^0.5.2                   ❌ No web support
```

**Problem**: Background tasks don't work in browsers (battery/privacy)

**Solution**: Service Workers
```yaml
# Use Service Worker API
# No package needed - pure JavaScript
```

**Migration Strategy**:
- Move background tasks to Service Worker
- Use periodic sync API (where supported)
- Email notifications as fallback

**Code Changes**:
- Create `web/sw.js` with periodic sync
- Remove mobile background tasks on web

**Effort**: 1-2 days

---

#### 6. File System - path_provider
```yaml
path_provider: ^2.1.4                 ⚠️ Limited web support
```

**Problem**: Web doesn't have traditional file system

**Solution**: Use web-specific paths
```yaml
# path_provider works on web but returns different paths
# No changes needed, just conditional logic
```

**Code Changes**:
- Add platform checks where file paths are used
- Use IndexedDB or localStorage instead

**Effort**: 0.5 days

---

### Category 3: Must Remove (4 packages)

#### 1. iOS Widgets - home_widget
```yaml
home_widget: ^0.7.0                   ❌ iOS-only
```

**Impact**: LOW - Dashboard screen serves same purpose

**Action**: Remove package and related code
- Delete `lib/services/widget_service.dart` (152 lines)
- Remove from `pubspec.yaml`

---

#### 2. Live Activities
```yaml
live_activities: ^2.3.2               ❌ iOS 16.1+ only
```

**Impact**: MINIMAL - Not a core feature

**Action**: Remove package and related code

---

#### 3. Intelligence Framework
```yaml
intelligence: ^0.0.1                  ❌ iOS-only
```

**Impact**: MINIMAL - Experimental feature

**Action**: Remove package

---

#### 4. Deep Linking - app_links
```yaml
app_links: ^6.3.2                     ⚠️ Needs refactor
```

**Impact**: MEDIUM - Deep linking works differently on web

**Action**: Refactor to use URL routing (Flutter's built-in)
- Keep package for mobile
- Use conditional imports

---

### Category 4: Requires Configuration (26 packages)

These packages support web but need platform checks or conditional imports:

```yaml
local_auth: ^2.3.0                    # Biometric → WebAuthn
flutter_tts: ^4.2.0                   # Platform voices → Web Speech API
image_picker: ^1.1.2                  # Camera → File upload
file_picker: ^8.1.4                   # Native → HTML input
```

**Action**: Add conditional imports and platform checks throughout codebase

---

## Platform-Specific Code

### Critical Files Requiring Modification

#### 1. Database Helper
**File**: `lib/core/database/database_helper.dart`
**Lines**: 150+
**Complexity**: HIGH

**Current Implementation**:
```dart
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'everyday_christian.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }
}
```

**Web Implementation**:
```dart
// lib/core/database/database_helper.dart
import 'package:sqflite_common/sqflite.dart' if (dart.library.html) 'package:sql_js/sql_js.dart';

class DatabaseHelper {
  static dynamic _database;

  Future<dynamic> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<dynamic> _initDatabase() async {
    if (kIsWeb) {
      // Load WASM SQLite
      await SqlJsLoader.load();
      final db = await SqlJsDatabase.open('everyday_christian.db');
      await _onCreate(db, 1);
      return db;
    } else {
      // Mobile SQLite
      String path = join(await getDatabasesPath(), 'everyday_christian.db');
      return await openDatabase(path, version: 1, onCreate: _onCreate);
    }
  }
}
```

**Migration Steps**:
1. Create `lib/core/database/sql_js_helper.dart` wrapper
2. Add conditional imports
3. Update all query methods to handle both platforms
4. Pre-load Bible data in WASM format
5. Test extensively

**Effort**: 2-3 days

---

#### 2. Subscription Service
**File**: `lib/core/services/subscription_service.dart`
**Lines**: 900+
**Complexity**: VERY HIGH

**Current Implementation**:
```dart
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;

  Future<void> purchaseSubscription(String productId) async {
    final ProductDetails product = await _getProduct(productId);
    final PurchaseParam param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }
}
```

**Web Implementation**:
```dart
// lib/core/services/subscription_service.dart
import 'package:http/http.dart' as http;

class SubscriptionService {
  static const String stripeApiUrl = 'https://api.stripe.com/v1';

  Future<void> purchaseSubscription(String priceId) async {
    if (kIsWeb) {
      // Stripe Checkout Session
      final response = await http.post(
        Uri.parse('$apiUrl/checkout/sessions'),
        headers: {'Authorization': 'Bearer $stripeSecretKey'},
        body: {
          'price': priceId,
          'success_url': '$webUrl/success',
          'cancel_url': '$webUrl/cancel',
        },
      );

      final sessionUrl = json.decode(response.body)['url'];
      await launchUrl(Uri.parse(sessionUrl));
    } else {
      // Mobile in-app purchase
      final ProductDetails product = await _getProduct(priceId);
      final PurchaseParam param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }
}
```

**Backend API Required**:
```javascript
// backend/api/stripe.js
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/create-checkout-session', async (req, res) => {
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    price: req.body.priceId,
    success_url: `${process.env.WEB_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.WEB_URL}/cancel`,
  });

  res.json({ url: session.url });
});

app.post('/webhook', async (req, res) => {
  const event = stripe.webhooks.constructEvent(
    req.body,
    req.headers['stripe-signature'],
    process.env.STRIPE_WEBHOOK_SECRET
  );

  if (event.type === 'checkout.session.completed') {
    // Update user subscription in database
  }

  res.json({ received: true });
});
```

**Migration Steps**:
1. Set up Stripe account and get API keys
2. Create backend API (Node.js + Express recommended)
3. Implement Stripe Checkout flow
4. Add webhook handlers for subscription events
5. Update UI to show Stripe payment form
6. Store subscription status in database
7. Test payment flow end-to-end

**Effort**: 5-8 days + 1-2 days backend setup

---

#### 3. Notification Service
**File**: `lib/core/services/notification_service.dart`
**Lines**: 338
**Complexity**: HIGH

**Current Implementation**:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> scheduleDailyVerse(TimeOfDay time) async {
    await _notifications.zonedSchedule(
      0,
      'Daily Verse',
      'Read your verse for today',
      _nextInstance(time),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
```

**Web Implementation**:
```dart
// lib/core/services/notification_service.dart
import 'dart:html' as html;

class NotificationService {
  Future<void> scheduleDailyVerse(TimeOfDay time) async {
    if (kIsWeb) {
      // Request permission
      final permission = await html.Notification.requestPermission();
      if (permission != 'granted') return;

      // Register Service Worker
      await html.window.navigator.serviceWorker!.register('/sw.js');

      // Schedule via Service Worker
      final registration = await html.window.navigator.serviceWorker!.ready;
      // Service Worker will handle scheduling
    } else {
      // Mobile notifications
      await _notifications.zonedSchedule(...);
    }
  }
}
```

**Service Worker** (`web/sw.js`):
```javascript
// web/sw.js
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Periodic background sync (for daily verse)
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'daily-verse') {
    event.waitUntil(showDailyVerseNotification());
  }
});

async function showDailyVerseNotification() {
  const verse = await fetchDailyVerse();

  return self.registration.showNotification('Daily Verse', {
    body: verse.text,
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-72.png',
    tag: 'daily-verse',
  });
}
```

**Migration Steps**:
1. Create Service Worker (`web/sw.js`)
2. Add notification permission UI
3. Implement Web Push API integration
4. Test notifications in supported browsers
5. Add email fallback for unsupported browsers

**Effort**: 2-3 days

---

#### 4. Biometric Authentication
**File**: `lib/core/services/app_lockout_service.dart`
**Lines**: 100+
**Complexity**: MEDIUM

**Current Implementation**:
```dart
import 'package:local_auth/local_auth.dart';

class AppLockoutService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    return await _localAuth.authenticate(
      localizedReason: 'Please authenticate to continue',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }
}
```

**Web Implementation**:
```dart
// lib/core/services/app_lockout_service.dart
import 'dart:html' as html;

class AppLockoutService {
  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) {
      // WebAuthn (FIDO2)
      try {
        final credential = await html.window.navigator.credentials!.get({
          'publicKey': {
            'challenge': generateChallenge(),
            'rpId': 'everydaychristian.app',
            'userVerification': 'required',
          }
        });

        return credential != null;
      } catch (e) {
        // Fallback to password
        return await _authenticateWithPassword();
      }
    } else {
      // Mobile biometric
      return await _localAuth.authenticate(...);
    }
  }

  Future<bool> _authenticateWithPassword() async {
    // Show password dialog
    return false;
  }
}
```

**Migration Steps**:
1. Implement WebAuthn registration flow
2. Store credential IDs in database
3. Add password authentication fallback
4. Update UI to show web-appropriate auth options

**Effort**: 2-3 days

---

#### 5. Text-to-Speech
**File**: `lib/services/tts_service.dart`
**Lines**: 350+
**Complexity**: MEDIUM

**Current Implementation**:
```dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) async {
    await _tts.setVoice({'name': 'Karen', 'locale': 'en-AU'});
    await _tts.speak(text);
  }
}
```

**Web Implementation**:
```dart
// lib/services/tts_service.dart
import 'dart:html' as html;

class TTSService {
  html.SpeechSynthesis? _synthesis;

  Future<void> speak(String text) async {
    if (kIsWeb) {
      _synthesis = html.window.speechSynthesis;
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'en-US';
      _synthesis!.speak(utterance);
    } else {
      await _tts.setVoice({'name': 'Karen', 'locale': 'en-AU'});
      await _tts.speak(text);
    }
  }
}
```

**Migration Steps**:
1. Add Web Speech API implementation
2. Remove platform-specific voice configurations
3. Use browser default voices
4. Test across browsers

**Effort**: 1 day

---

#### 6. Main Initialization
**File**: `lib/main.dart`
**Lines**: 150
**Complexity**: LOW

**Current Code** (lines 30-35):
```dart
// Enable edge-to-edge mode for Android 15+
SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

// Initialize timezone database
tz.initializeTimeZones();
```

**Web-Compatible Code**:
```dart
if (!kIsWeb) {
  // Enable edge-to-edge mode for Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

// Initialize timezone database (works on web)
tz.initializeTimeZones();
```

**Migration Steps**:
1. Add platform checks for mobile-only initialization
2. Remove widget-related initialization
3. Test web build

**Effort**: 0.5 days

---

## Database Migration Strategy

### Current Architecture
- **Database**: SQLite via sqflite
- **Size**: ~5-8MB (KJV + RVR1909 Bibles)
- **Schema**: 3 tables (verses, favorites, reading_plans)
- **Queries**: ~50 SQL queries in DatabaseHelper

### Target Architecture
- **Database**: sql.js (WASM SQLite)
- **Size**: ~5-8MB WASM file + database
- **Schema**: Same (no changes)
- **Queries**: Same (no changes)

### Migration Path

#### Option 1: sql.js (Recommended)
**Pros**:
- ✅ Keep all existing SQL queries
- ✅ Minimal code changes
- ✅ True SQLite compatibility
- ✅ Works offline with IndexedDB

**Cons**:
- ❌ Requires WASM file loading (~5MB one-time download)
- ❌ Slightly slower than native

**Implementation**:
```dart
// lib/core/database/sql_js_helper.dart
import 'package:sql_js/sql_js.dart';

class SqlJsHelper {
  static SqlJsDatabase? _db;

  static Future<SqlJsDatabase> get database async {
    if (_db != null) return _db!;

    // Load WASM module
    await SqlJsLoader.load();

    // Open database (creates if doesn't exist)
    _db = await SqlJsDatabase.open('everyday_christian.db');

    // Pre-load Bible data
    await _loadBibleData(_db!);

    return _db!;
  }

  static Future<void> _loadBibleData(SqlJsDatabase db) async {
    final bibleData = await rootBundle.loadString('assets/bible_data.sql');
    await db.execute(bibleData);
  }
}
```

**Asset Preparation**:
```bash
# Convert SQLite database to SQL dump
sqlite3 everyday_christian.db .dump > assets/bible_data.sql

# Or use WASM database directly
cp everyday_christian.db web/assets/
```

---

#### Option 2: Drift (with web support)
**Pros**:
- ✅ Type-safe Dart API
- ✅ Built-in migration support
- ✅ Better performance on web

**Cons**:
- ❌ Requires complete schema rewrite
- ❌ All queries need rewriting
- ❌ Higher migration effort

**Not Recommended**: Too much work for minimal benefit

---

### Recommended Approach: sql.js

**Phase 1**: Set up sql.js
1. Add dependency: `sql_js: ^0.1.0`
2. Create wrapper: `lib/core/database/sql_js_helper.dart`
3. Load WASM module on web startup

**Phase 2**: Adapt DatabaseHelper
1. Add conditional imports
2. Wrap sql.js API to match sqflite interface
3. Test all queries

**Phase 3**: Pre-load Bible data
1. Export current database to SQL dump
2. Include as asset
3. Execute on first launch (web)

**Phase 4**: IndexedDB persistence
1. Save database to IndexedDB after changes
2. Load from IndexedDB on startup
3. Fallback to asset if not found

**Code Example**:
```dart
// lib/core/database/database_helper.dart
import 'package:sqflite_common/sqflite.dart'
    if (dart.library.html) '../database/sql_js_helper.dart';

class DatabaseHelper {
  static Future<Database> initDatabase() async {
    if (kIsWeb) {
      return await SqlJsHelper.database;
    } else {
      return await openDatabase(
        join(await getDatabasesPath(), 'everyday_christian.db'),
      );
    }
  }

  // All query methods stay the same!
  Future<List<Map<String, dynamic>>> getVerses(String book) async {
    final db = await database;
    return await db.query('verses', where: 'book = ?', whereArgs: [book]);
  }
}
```

**Testing Strategy**:
1. Unit test all queries on web
2. Compare results with mobile
3. Performance benchmark (should be <100ms for most queries)
4. Stress test with 10,000+ verses

**Rollback Plan**:
If sql.js doesn't work:
- Fallback to REST API for Bible data
- Cache aggressively with IndexedDB
- Lazy load books as needed

---

## Subscription System Redesign

### Current Architecture
- **Platform**: in_app_purchase (App Store + Google Play)
- **Products**: 2 (monthly $9.99, yearly $89.99)
- **Features**: Unlimited AI chat, offline Bible, devotionals
- **Implementation**: `lib/core/services/subscription_service.dart` (900 lines)

### Target Architecture
- **Platform**: Stripe (web payments)
- **Products**: Same pricing
- **Features**: Same
- **Implementation**: Stripe Checkout + backend API

### Stripe Integration

#### Frontend (Flutter Web)
```dart
// lib/core/services/subscription_service_web.dart
import 'package:http/http.dart' as http;

class SubscriptionServiceWeb {
  static const String apiUrl = 'https://api.everydaychristian.app';

  Future<void> subscribe(String priceId) async {
    // Create Checkout Session
    final response = await http.post(
      Uri.parse('$apiUrl/create-checkout-session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'priceId': priceId,
        'userId': currentUserId,
      }),
    );

    final sessionUrl = json.decode(response.body)['url'];

    // Redirect to Stripe Checkout
    await launchUrl(Uri.parse(sessionUrl));
  }

  Future<SubscriptionStatus> getStatus() async {
    final response = await http.get(
      Uri.parse('$apiUrl/subscription-status?userId=$currentUserId'),
    );

    return SubscriptionStatus.fromJson(json.decode(response.body));
  }
}
```

#### Backend API (Node.js + Express)
```javascript
// backend/server.js
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
app.use(express.json());

// Create Checkout Session
app.post('/create-checkout-session', async (req, res) => {
  const { priceId, userId } = req.body;

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{
      price: priceId, // price_xxx from Stripe Dashboard
      quantity: 1,
    }],
    metadata: { userId },
    success_url: `${process.env.WEB_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.WEB_URL}/paywall`,
  });

  res.json({ url: session.url });
});

// Webhook handler
app.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object;
      await activateSubscription(session.metadata.userId, session.subscription);
      break;

    case 'customer.subscription.deleted':
      const subscription = event.data.object;
      await deactivateSubscription(subscription.metadata.userId);
      break;

    case 'invoice.payment_failed':
      const invoice = event.data.object;
      await handlePaymentFailure(invoice.customer);
      break;
  }

  res.json({ received: true });
});

// Check subscription status
app.get('/subscription-status', async (req, res) => {
  const { userId } = req.query;

  // Query database for user subscription
  const sub = await db.subscriptions.findOne({ userId });

  if (!sub || sub.status !== 'active') {
    return res.json({ active: false });
  }

  res.json({
    active: true,
    plan: sub.plan,
    expiresAt: sub.expiresAt,
  });
});

app.listen(3000);
```

#### Database Schema
```sql
CREATE TABLE subscriptions (
  id INTEGER PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE,
  stripe_subscription_id TEXT,
  stripe_customer_id TEXT,
  plan TEXT, -- 'monthly' or 'yearly'
  status TEXT, -- 'active', 'canceled', 'past_due'
  current_period_end INTEGER,
  created_at INTEGER,
  updated_at INTEGER
);
```

### Migration Steps

**Phase 1: Stripe Setup (Day 1)**
1. Create Stripe account
2. Get API keys (test + live)
3. Create products and prices in Dashboard
4. Set up webhook endpoint

**Phase 2: Backend API (Days 2-3)**
1. Set up Node.js server (or serverless functions)
2. Implement Stripe Checkout endpoint
3. Implement webhook handler
4. Add subscription status endpoint
5. Deploy to Vercel/Netlify Functions

**Phase 3: Frontend Integration (Days 4-5)**
1. Create `SubscriptionServiceWeb`
2. Update `PaywallScreen` UI
3. Handle success/cancel redirects
4. Test payment flow

**Phase 4: Database Integration (Day 6)**
1. Store subscription status in database
2. Sync with Stripe on app startup
3. Handle expired subscriptions

**Phase 5: Testing (Days 7-8)**
1. Test with Stripe test cards
2. Test webhooks (use Stripe CLI)
3. Test subscription renewal
4. Test cancellation
5. Load testing

**Deployment**:
```bash
# Backend (Vercel)
cd backend
vercel deploy --prod

# Frontend (Vercel)
flutter build web --release
cd build/web
vercel deploy --prod
```

**Cost Estimates**:
- Stripe fees: 2.9% + $0.30 per transaction
- Monthly: $9.99 → You receive $9.40
- Yearly: $89.99 → You receive $87.38

---

## Notification System

### Web Notifications Strategy

**Capabilities**:
- ✅ Browser notifications (with permission)
- ✅ Service Worker push notifications
- ⚠️ Limited background scheduling
- ❌ No guaranteed delivery when browser closed

**Recommended Approach**: Hybrid
1. Web Push for active users
2. Email notifications for critical events
3. In-app reminders as fallback

**Implementation**:
```javascript
// web/sw.js
self.addEventListener('push', (event) => {
  const data = event.data.json();

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/icon-192.png',
      badge: '/icons/badge-72.png',
      data: { url: data.url },
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow(event.notification.data.url));
});
```

---

## Security Considerations

### API Key Management
**Problem**: Can't hide API keys in web apps (client-side code is visible)

**Solutions**:
1. **Backend Proxy** (Recommended)
   - Move Gemini API calls to backend
   - Frontend calls your API
   - Your API calls Gemini
   - Rate limiting + authentication

2. **Domain Restrictions**
   - Restrict Gemini API key to your domain
   - Still vulnerable if someone copies your domain

3. **Firebase App Check**
   - Use App Check to verify requests from your app
   - Works for web apps

**Recommended Architecture**:
```
Flutter Web App
  ↓ (authenticated request)
Your Backend API (Vercel Functions)
  ↓ (with secret API key)
Google Gemini API
```

**Implementation**:
```dart
// lib/services/gemini_service_web.dart
class GeminiServiceWeb {
  Future<String> chat(String message) async {
    // Call your backend instead of Gemini directly
    final response = await http.post(
      Uri.parse('https://api.everydaychristian.app/chat'),
      headers: {
        'Authorization': 'Bearer ${await getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'message': message}),
    );

    return json.decode(response.body)['response'];
  }
}
```

```javascript
// backend/api/chat.js
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

export default async function handler(req, res) {
  // Verify auth token
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!isValidToken(token)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Rate limiting
  if (await isRateLimited(token)) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }

  // Call Gemini
  const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
  const result = await model.generateContent(req.body.message);

  res.json({ response: result.response.text() });
}
```

### Secure Storage
- ❌ Don't use localStorage for sensitive data (XSS vulnerable)
- ✅ Use sessionStorage (clears on close)
- ✅ Use Web Crypto API for encryption
- ✅ Use HttpOnly cookies for auth tokens

### Content Security Policy
```html
<!-- web/index.html -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' https://api.everydaychristian.app https://api.stripe.com;
  font-src 'self' https://fonts.gstatic.com;
">
```

---

## Performance Optimization

### Initial Load Time
**Target**: <3 seconds on 3G

**Strategies**:
1. **Code Splitting**
   ```dart
   // Lazy load screens
   static const String chat = '/chat';
   static Widget buildChatScreen() => const ChatScreen();
   ```

2. **Asset Optimization**
   - Compress images (WebP format)
   - Minify JavaScript/CSS
   - Use CDN for fonts

3. **WASM Loading**
   - Pre-load sql.js in Service Worker
   - Cache WASM file aggressively
   - Show loading indicator

4. **Font Loading**
   ```dart
   // Use font display: swap
   GoogleFonts.config.allowRuntimeFetching = false;
   ```

### Runtime Performance
**Target**: 60 FPS, <100ms response time

**Strategies**:
1. **Debounce/Throttle**
   - Debounce search inputs
   - Throttle scroll listeners

2. **Virtual Scrolling**
   - Use ListView.builder (already used)
   - Paginate Bible chapters

3. **Image Caching**
   ```dart
   CachedNetworkImage(
     imageUrl: url,
     memCacheWidth: 400,
     maxWidthDiskCache: 800,
   )
   ```

4. **Background Tasks**
   - Move heavy work to Web Workers
   - Use compute() for Dart isolates

### Bundle Size
**Target**: <5MB initial bundle

**Current Flutter Web Bundle**: ~2.5MB (CanvasKit)

**Optimizations**:
1. Use HTML renderer for smaller builds
   ```bash
   flutter build web --web-renderer html
   ```

2. Tree shaking (automatic)

3. Remove unused assets

4. Compress with Brotli

---

## Implementation Timeline

### Week 1: Foundation
- [ ] Day 1: Set up Flutter web project, PWA manifest
- [ ] Day 2: Database migration (sql.js)
- [ ] Day 3: Test Bible data loading
- [ ] Day 4: Remove iOS-only features
- [ ] Day 5: Update dependencies, conditional imports

**Deliverable**: Basic web build with Bible browsing

---

### Week 2: Core Features
- [ ] Day 6: AI chat (backend proxy)
- [ ] Day 7: Bible search
- [ ] Day 8: Devotionals
- [ ] Day 9: Prayer journal
- [ ] Day 10: Reading plans

**Deliverable**: Full-featured app (no payments)

---

### Week 3: Systems
- [ ] Day 11-12: Stripe integration (backend)
- [ ] Day 13-14: Stripe integration (frontend)
- [ ] Day 15: Service Worker notifications

**Deliverable**: Complete PWA with payments

---

### Week 4: Polish
- [ ] Day 16-17: Performance optimization
- [ ] Day 18: Security audit
- [ ] Day 19: Cross-browser testing
- [ ] Day 20: Deploy to production

**Deliverable**: Live PWA ✨

---

**Total Effort**: 4 weeks (with buffer)

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| sql.js performance issues | Medium | High | Benchmark early, fallback to API |
| Stripe integration complexity | Low | High | Use Stripe Checkout (hosted) |
| Browser compatibility | Medium | Medium | Progressive enhancement, polyfills |
| API key exposure | High | Critical | Backend proxy (required) |
| Notification unreliability | High | Low | Email fallback |

---

## Success Criteria

- [ ] Lighthouse score >90 (all categories)
- [ ] Works offline (Bible + cached data)
- [ ] Installable as PWA on all platforms
- [ ] Payment flow tested and working
- [ ] Cross-browser compatibility (Chrome, Firefox, Safari, Edge)
- [ ] No critical security vulnerabilities
- [ ] Performance: <3s load time on 3G
- [ ] Feature parity: 95%+ vs mobile

---

**Document Status**: Complete and ready for implementation
**Last Updated**: 2025-12-15
**Next Review**: After Phase 1 completion
