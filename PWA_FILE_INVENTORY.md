# PWA Conversion File Inventory

## Table of Contents
1. [Files to Delete](#files-to-delete)
2. [Files to Create](#files-to-create)
3. [Files to Heavily Modify](#files-to-heavily-modify)
4. [Files Requiring Minor Changes](#files-requiring-minor-changes)
5. [Files Safe to Keep](#files-safe-to-keep)
6. [Import Statement Patterns](#import-statement-patterns)
7. [Git Strategy](#git-strategy)

---

## Files to Delete

### 1. iOS Widget Service
**Path**: `lib/services/widget_service.dart`
**Lines**: 152
**Reason**: iOS home widgets not supported on web
**Dependencies**: `home_widget` package

**Impact**: LOW
- Home screen dashboard provides same functionality
- Widget preview screen can be removed

**Related Files to Update**:
- `lib/screens/home_screen.dart` - Remove widget-related UI
- `lib/debug_screen_gallery.dart` - Remove widget preview references
- `pubspec.yaml` - Remove `home_widget: ^0.7.0`

**Commit Message**:
```
Remove iOS home widget service for PWA compatibility

- Delete lib/services/widget_service.dart (152 lines)
- Remove home_widget dependency
- iOS widgets not supported in web browsers
- Dashboard screen provides equivalent functionality
```

---

### 2. pubspec.yaml Entries
**Path**: `pubspec.yaml`
**Lines to Remove**:

```yaml
# Line 22 - Remove iOS-only package
home_widget: ^0.7.0

# Lines 25-26 - Remove iOS Live Activities
live_activities: ^2.3.2
intelligence: ^0.0.1

# Lines 28-31 - These stay but need web alternatives
# sqflite: ^2.4.1  # Keep for mobile, add sql_js for web
# in_app_purchase: ^3.2.0  # Keep for mobile, add stripe for web
# flutter_local_notifications: ^17.2.3  # Keep, add web impl
# flutter_secure_storage: ^9.2.2  # Keep, add web fallback

# Lines 51-52 - Remove if only used for widgets
# Check if used elsewhere before deleting
```

**Commit Message**:
```
Update dependencies for web platform support

- Remove iOS-only packages (home_widget, live_activities)
- Add web-compatible alternatives (sql_js, web_notification)
- Keep mobile packages with conditional imports
```

---

## Files to Create

### 1. SQL.js Database Helper
**Path**: `lib/core/database/sql_js_helper.dart`
**Lines**: ~200 (estimated)
**Purpose**: Web-compatible SQLite wrapper

**Template**:
```dart
/// Web-compatible SQLite implementation using sql.js (WASM)
///
/// This file is only imported on web platform via conditional imports.
/// Mobile platforms continue using sqflite.

import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'package:flutter/foundation.dart';
import 'package:sql_js/sql_js.dart';

class SqlJsHelper {
  static SqlJsDatabase? _database;
  static bool _initialized = false;

  /// Get the singleton database instance
  static Future<SqlJsDatabase> get database async {
    if (_database != null) return _database!;

    if (!_initialized) {
      await _initialize();
    }

    _database = await _openDatabase();
    return _database!;
  }

  /// Initialize sql.js WASM module
  static Future<void> _initialize() async {
    if (_initialized) return;

    debugPrint('🔧 Loading sql.js WASM module...');
    await SqlJsLoader.load();
    _initialized = true;
    debugPrint('✅ sql.js loaded successfully');
  }

  /// Open database from IndexedDB or create new
  static Future<SqlJsDatabase> _openDatabase() async {
    try {
      // Try to load from IndexedDB
      final savedData = await _loadFromIndexedDB();

      if (savedData != null) {
        debugPrint('✅ Loaded database from IndexedDB');
        return SqlJsDatabase.fromUint8List(savedData);
      }
    } catch (e) {
      debugPrint('⚠️ Could not load from IndexedDB: $e');
    }

    // Create new database
    debugPrint('🔨 Creating new database...');
    final db = await SqlJsDatabase.open('everyday_christian.db');

    // Load initial schema and data
    await _loadBibleData(db);

    // Save to IndexedDB
    await _saveToIndexedDB(db);

    return db;
  }

  /// Load Bible data from asset
  static Future<void> _loadBibleData(SqlJsDatabase db) async {
    debugPrint('📖 Loading Bible data...');

    // Load SQL dump from assets
    final response = await html.window.fetch('assets/bible_data.sql');
    final sqlScript = await response.text();

    // Execute SQL statements
    final statements = sqlScript.split(';');
    for (final statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }

    debugPrint('✅ Bible data loaded successfully');
  }

  /// Save database to IndexedDB for persistence
  static Future<void> _saveToIndexedDB(SqlJsDatabase db) async {
    try {
      final bytes = db.export();

      final dbStore = await html.window.indexedDB!.open(
        'everyday_christian_db',
        version: 1,
        onUpgradeNeeded: (e) {
          final db = e.target.result as idb.Database;
          if (!db.objectStoreNames!.contains('database')) {
            db.createObjectStore('database');
          }
        },
      );

      final transaction = dbStore.transaction('database', 'readwrite');
      final store = transaction.objectStore('database');
      await store.put(bytes, 'data');

      debugPrint('💾 Saved database to IndexedDB');
    } catch (e) {
      debugPrint('⚠️ Could not save to IndexedDB: $e');
    }
  }

  /// Load database from IndexedDB
  static Future<Uint8List?> _loadFromIndexedDB() async {
    try {
      final db = await html.window.indexedDB!.open('everyday_christian_db');
      final transaction = db.transaction('database', 'readonly');
      final store = transaction.objectStore('database');
      final result = await store.getObject('data');

      return result as Uint8List?;
    } catch (e) {
      return null;
    }
  }

  /// Close database and clean up
  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Persist current state to IndexedDB
  static Future<void> persist() async {
    if (_database != null) {
      await _saveToIndexedDB(_database!);
    }
  }
}

/// Extension to make sql.js compatible with sqflite API
extension SqlJsDatabaseExtensions on SqlJsDatabase {
  /// Query wrapper compatible with sqflite
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final sql = StringBuffer('SELECT ');

    if (distinct == true) {
      sql.write('DISTINCT ');
    }

    sql.write(columns?.join(', ') ?? '*');
    sql.write(' FROM $table');

    if (where != null) {
      sql.write(' WHERE $where');
    }

    if (groupBy != null) {
      sql.write(' GROUP BY $groupBy');
    }

    if (having != null) {
      sql.write(' HAVING $having');
    }

    if (orderBy != null) {
      sql.write(' ORDER BY $orderBy');
    }

    if (limit != null) {
      sql.write(' LIMIT $limit');
    }

    if (offset != null) {
      sql.write(' OFFSET $offset');
    }

    final results = await select(sql.toString(), whereArgs ?? []);
    return results.map((row) => row.asMap()).toList();
  }

  /// Insert wrapper compatible with sqflite
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final columns = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';

    await execute(sql, values.values.toList());

    // Get last insert rowid
    final result = await select('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  /// Update wrapper compatible with sqflite
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final setClauses = values.keys.map((key) => '$key = ?').join(', ');
    final sql = StringBuffer('UPDATE $table SET $setClauses');

    final args = [...values.values];

    if (where != null) {
      sql.write(' WHERE $where');
      if (whereArgs != null) {
        args.addAll(whereArgs);
      }
    }

    await execute(sql.toString(), args);

    // Get affected rows
    final result = await select('SELECT changes() as count');
    return result.first['count'] as int;
  }

  /// Delete wrapper compatible with sqflite
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final sql = StringBuffer('DELETE FROM $table');

    if (where != null) {
      sql.write(' WHERE $where');
    }

    await execute(sql.toString(), whereArgs ?? []);

    // Get affected rows
    final result = await select('SELECT changes() as count');
    return result.first['count'] as int;
  }
}

enum ConflictAlgorithm {
  rollback,
  abort,
  fail,
  ignore,
  replace,
}
```

**Dependencies**:
```yaml
# pubspec.yaml
dependencies:
  sql_js: ^0.1.0  # WASM SQLite for web
```

**Assets**:
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/bible_data.sql  # SQL dump of Bible database
```

**Testing**:
```dart
// test/sql_js_helper_test.dart
void main() {
  group('SqlJsHelper', () {
    test('should initialize and load Bible data', () async {
      final db = await SqlJsHelper.database;
      expect(db, isNotNull);

      final verses = await db.query('verses', limit: 10);
      expect(verses, isNotEmpty);
    });

    test('should persist to IndexedDB', () async {
      final db = await SqlJsHelper.database;
      await SqlJsHelper.persist();
      // Verify IndexedDB contains data
    });
  });
}
```

---

### 2. Service Worker
**Path**: `web/sw.js`
**Lines**: ~150 (estimated)
**Purpose**: Offline caching, push notifications, periodic sync

**Template**:
```javascript
/// Service Worker for Everyday Christian PWA
///
/// Features:
/// - Offline caching (Cache First strategy)
/// - Push notifications
/// - Periodic background sync (daily verse)
/// - Asset pre-caching

const CACHE_VERSION = 'v1';
const CACHE_NAME = `everyday-christian-${CACHE_VERSION}`;

// Assets to pre-cache on install
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter_service_worker.js',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
  '/assets/bible_data.sql',
];

// Install event - pre-cache assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Pre-caching assets');
      return cache.addAll(PRECACHE_ASSETS);
    }).then(() => {
      console.log('[SW] Installation complete');
      return self.skipWaiting();
    })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');

  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => {
      console.log('[SW] Activation complete');
      return self.clients.claim();
    })
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip API calls (always fetch fresh)
  if (request.url.includes('/api/')) {
    return;
  }

  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      if (cachedResponse) {
        console.log('[SW] Serving from cache:', request.url);
        return cachedResponse;
      }

      console.log('[SW] Fetching from network:', request.url);

      return fetch(request).then((networkResponse) => {
        // Cache successful responses
        if (networkResponse.ok) {
          return caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, networkResponse.clone());
            return networkResponse;
          });
        }

        return networkResponse;
      }).catch((error) => {
        console.error('[SW] Fetch failed:', error);

        // Return offline page if available
        if (request.mode === 'navigate') {
          return caches.match('/offline.html');
        }

        throw error;
      });
    })
  );
});

// Push event - show notification
self.addEventListener('push', (event) => {
  console.log('[SW] Push notification received');

  const data = event.data ? event.data.json() : {};
  const title = data.title || 'Everyday Christian';
  const options = {
    body: data.body || '',
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-72.png',
    data: {
      url: data.url || '/',
      timestamp: Date.now(),
    },
    actions: [
      { action: 'open', title: 'Open App' },
      { action: 'close', title: 'Dismiss' },
    ],
    requireInteraction: false,
    vibrate: [200, 100, 200],
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked');

  event.notification.close();

  if (event.action === 'close') {
    return;
  }

  const urlToOpen = event.notification.data.url;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if app is already open
        for (const client of clientList) {
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }

        // Open new window
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// Periodic background sync (daily verse)
// Note: Requires user opt-in and may not work in all browsers
self.addEventListener('periodicsync', (event) => {
  console.log('[SW] Periodic sync triggered:', event.tag);

  if (event.tag === 'daily-verse') {
    event.waitUntil(fetchAndShowDailyVerse());
  }
});

async function fetchAndShowDailyVerse() {
  try {
    // Fetch daily verse from API
    const response = await fetch('/api/daily-verse');
    const verse = await response.json();

    // Show notification
    await self.registration.showNotification('Daily Verse', {
      body: `${verse.text}\n\n${verse.reference}`,
      icon: '/icons/icon-192.png',
      badge: '/icons/badge-72.png',
      data: { url: '/devotional' },
    });

    console.log('[SW] Daily verse notification shown');
  } catch (error) {
    console.error('[SW] Failed to fetch daily verse:', error);
  }
}

// Message event (for communication with app)
self.addEventListener('message', (event) => {
  console.log('[SW] Message received:', event.data);

  if (event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  if (event.data.type === 'CACHE_BIBLE_DATA') {
    event.waitUntil(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.add('/assets/bible_data.sql');
      })
    );
  }
});
```

**Register Service Worker** (`web/index.html`):
```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/sw.js')
        .then((registration) => {
          console.log('✅ Service Worker registered:', registration);

          // Request notification permission
          if ('Notification' in window && Notification.permission === 'default') {
            Notification.requestPermission().then((permission) => {
              console.log('🔔 Notification permission:', permission);
            });
          }

          // Register periodic sync (if supported)
          if ('periodicSync' in registration) {
            registration.periodicSync.register('daily-verse', {
              minInterval: 24 * 60 * 60 * 1000, // 24 hours
            }).then(() => {
              console.log('✅ Periodic sync registered');
            }).catch((error) => {
              console.warn('⚠️ Periodic sync not supported:', error);
            });
          }
        })
        .catch((error) => {
          console.error('❌ Service Worker registration failed:', error);
        });
    });
  }
</script>
```

---

### 3. PWA Manifest
**Path**: `web/manifest.json`
**Lines**: ~60
**Purpose**: Make app installable as PWA

**Template**:
```json
{
  "name": "Everyday Christian",
  "short_name": "EC",
  "description": "Your daily companion for Bible study, devotionals, and prayer.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1A1A2E",
  "theme_color": "#6366F1",
  "orientation": "portrait",
  "scope": "/",
  "lang": "en-US",
  "dir": "ltr",
  "categories": ["lifestyle", "education"],
  "icons": [
    {
      "src": "/icons/icon-72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "screenshots": [
    {
      "src": "/screenshots/home.png",
      "sizes": "540x720",
      "type": "image/png",
      "platform": "wide",
      "label": "Home Screen"
    },
    {
      "src": "/screenshots/bible.png",
      "sizes": "540x720",
      "type": "image/png",
      "platform": "wide",
      "label": "Bible Browser"
    },
    {
      "src": "/screenshots/chat.png",
      "sizes": "540x720",
      "type": "image/png",
      "platform": "wide",
      "label": "AI Chat"
    }
  ],
  "shortcuts": [
    {
      "name": "Bible",
      "short_name": "Bible",
      "description": "Browse the Bible",
      "url": "/bible",
      "icons": [
        {
          "src": "/icons/shortcut-bible.png",
          "sizes": "96x96"
        }
      ]
    },
    {
      "name": "Chat",
      "short_name": "Chat",
      "description": "AI Chat Assistant",
      "url": "/chat",
      "icons": [
        {
          "src": "/icons/shortcut-chat.png",
          "sizes": "96x96"
        }
      ]
    },
    {
      "name": "Devotional",
      "short_name": "Devotional",
      "description": "Daily Devotional",
      "url": "/devotional",
      "icons": [
        {
          "src": "/icons/shortcut-devotional.png",
          "sizes": "96x96"
        }
      ]
    }
  ],
  "related_applications": [
    {
      "platform": "play",
      "url": "https://play.google.com/store/apps/details?id=com.everydaychristian.app",
      "id": "com.everydaychristian.app"
    },
    {
      "platform": "itunes",
      "url": "https://apps.apple.com/app/everyday-christian/id123456789"
    }
  ],
  "prefer_related_applications": false
}
```

**Link in** `web/index.html`:
```html
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#6366F1">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="EC">
<link rel="apple-touch-icon" href="/icons/icon-192.png">
```

---

### 4. Backend API (Subscription Management)
**Path**: `backend/api/subscription.js` (new repository)
**Lines**: ~300 (estimated)
**Purpose**: Handle Stripe subscriptions, webhooks

**Deployment**: Vercel Serverless Functions

**Template** (see PWA_CONVERSION_ROADMAP.md for full code)

---

## Files to Heavily Modify

### 1. Database Helper
**Path**: `lib/core/database/database_helper.dart`
**Current Lines**: 150+
**Changes**: Add conditional imports, wrap sql.js

**Before**:
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

**After**:
```dart
import 'package:sqflite_common/sqflite.dart'
    if (dart.library.html) '../database/sql_js_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static dynamic _database; // SqlJsDatabase on web, Database on mobile

  Future<dynamic> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<dynamic> _initDatabase() async {
    if (kIsWeb) {
      return await SqlJsHelper.database;
    } else {
      String path = join(await getDatabasesPath(), 'everyday_christian.db');
      return await openDatabase(path, version: 1, onCreate: _onCreate);
    }
  }

  // All query methods stay the same! sql.js extensions match sqflite API
  Future<List<Map<String, dynamic>>> getVerses(String book) async {
    final db = await database;
    return await db.query('verses', where: 'book = ?', whereArgs: [book]);
  }
}
```

**Effort**: 2 days (wrapper + testing)

---

### 2. Subscription Service
**Path**: `lib/core/services/subscription_service.dart`
**Current Lines**: 900+
**Changes**: Add Stripe implementation for web

**Key Changes**:
1. Add conditional imports
2. Create `SubscriptionServiceWeb` class
3. Update `SubscriptionService` to delegate based on platform
4. Keep mobile implementation intact

**Before**:
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

**After**:
```dart
import 'package:in_app_purchase/in_app_purchase.dart'
    if (dart.library.html) '../services/subscription_service_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SubscriptionService {
  late final dynamic _impl;

  SubscriptionService() {
    if (kIsWeb) {
      _impl = SubscriptionServiceWeb();
    } else {
      _impl = SubscriptionServiceMobile();
    }
  }

  Future<void> purchaseSubscription(String productId) async {
    return await _impl.purchaseSubscription(productId);
  }

  Future<SubscriptionStatus> getStatus() async {
    return await _impl.getStatus();
  }
}

// Mobile implementation (unchanged)
class SubscriptionServiceMobile {
  final InAppPurchase _iap = InAppPurchase.instance;

  Future<void> purchaseSubscription(String productId) async {
    final ProductDetails product = await _getProduct(productId);
    final PurchaseParam param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }
}
```

**Create**: `lib/core/services/subscription_service_web.dart`
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionServiceWeb {
  static const String apiUrl = 'https://api.everydaychristian.app';

  Future<void> purchaseSubscription(String priceId) async {
    // Create Stripe Checkout Session
    final response = await http.post(
      Uri.parse('$apiUrl/create-checkout-session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'priceId': priceId}),
    );

    final sessionUrl = json.decode(response.body)['url'];

    // Redirect to Stripe Checkout
    await launchUrl(Uri.parse(sessionUrl));
  }

  Future<SubscriptionStatus> getStatus() async {
    final response = await http.get(
      Uri.parse('$apiUrl/subscription-status'),
    );

    return SubscriptionStatus.fromJson(json.decode(response.body));
  }
}
```

**Effort**: 5 days (Stripe integration + backend)

---

### 3. Notification Service
**Path**: `lib/core/services/notification_service.dart`
**Current Lines**: 338
**Changes**: Add Web Notifications API implementation

**Key Changes**:
1. Add conditional web implementation
2. Request notification permission
3. Use Service Worker for scheduling
4. Fallback to email notifications

**Before**:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  Future<void> scheduleDailyVerse(TimeOfDay time) async {
    await _notifications.zonedSchedule(...);
  }
}
```

**After**:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class NotificationService {
  Future<void> scheduleDailyVerse(TimeOfDay time) async {
    if (kIsWeb) {
      await _scheduleWebNotification(time);
    } else {
      await _notifications.zonedSchedule(...);
    }
  }

  Future<void> _scheduleWebNotification(TimeOfDay time) async {
    // Request permission
    final permission = await html.Notification.requestPermission();
    if (permission != 'granted') {
      debugPrint('⚠️ Notification permission denied');
      return;
    }

    // Register Service Worker (if not already)
    final registration = await html.window.navigator.serviceWorker!.ready;

    // Schedule via backend API (Service Worker limitation)
    await http.post(
      Uri.parse('https://api.everydaychristian.app/schedule-notification'),
      body: json.encode({
        'time': '${time.hour}:${time.minute}',
        'type': 'daily-verse',
      }),
    );

    debugPrint('✅ Daily verse notification scheduled');
  }
}
```

**Effort**: 2 days

---

### 4. Paywall Screen
**Path**: `lib/screens/paywall_screen.dart`
**Current Lines**: ~400
**Changes**: Add Stripe Checkout UI for web

**Key Changes**:
1. Show Stripe payment button on web
2. Keep in-app purchase buttons on mobile
3. Handle success/cancel redirects

**Before**:
```dart
ElevatedButton(
  onPressed: () => _purchaseSubscription('monthly'),
  child: Text('Subscribe Monthly - \$9.99'),
)
```

**After**:
```dart
ElevatedButton(
  onPressed: () {
    if (kIsWeb) {
      _purchaseSubscriptionWeb('price_monthly');
    } else {
      _purchaseSubscription('monthly');
    }
  },
  child: Text('Subscribe Monthly - \$9.99'),
)

Future<void> _purchaseSubscriptionWeb(String priceId) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  await subscriptionService.purchaseSubscription(priceId);

  // Stripe redirects to success/cancel URLs
  // Handle callback in success_screen.dart
}
```

**Create**: `lib/screens/success_screen.dart`
```dart
/// Handle Stripe Checkout success callback
class SuccessScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get session_id from URL query params
    final uri = Uri.base;
    final sessionId = uri.queryParameters['session_id'];

    if (sessionId != null) {
      // Verify payment with backend
      _verifyPayment(sessionId, ref);
    }

    return Scaffold(
      body: Center(
        child: Text('🎉 Subscription Activated!'),
      ),
    );
  }

  Future<void> _verifyPayment(String sessionId, WidgetRef ref) async {
    final response = await http.get(
      Uri.parse('https://api.everydaychristian.app/verify-payment?session_id=$sessionId'),
    );

    if (response.statusCode == 200) {
      // Update subscription status
      ref.read(subscriptionStatusProvider.notifier).refresh();

      // Navigate to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
```

**Effort**: 1 day

---

### 5. App Lockout Service (Biometric Auth)
**Path**: `lib/core/services/app_lockout_service.dart`
**Current Lines**: 100+
**Changes**: Add WebAuthn for web

**Before**:
```dart
import 'package:local_auth/local_auth.dart';

class AppLockoutService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    return await _localAuth.authenticate(
      localizedReason: 'Please authenticate',
    );
  }
}
```

**After**:
```dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class AppLockoutService {
  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) {
      return await _authenticateWebAuthn();
    } else {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate',
      );
    }
  }

  Future<bool> _authenticateWebAuthn() async {
    try {
      final credential = await html.window.navigator.credentials!.get({
        'publicKey': {
          'challenge': _generateChallenge(),
          'rpId': 'everydaychristian.app',
          'userVerification': 'required',
        }
      });

      return credential != null;
    } catch (e) {
      debugPrint('⚠️ WebAuthn failed: $e');
      // Fallback to password
      return await _showPasswordDialog();
    }
  }
}
```

**Effort**: 2 days

---

### 6. TTS Service
**Path**: `lib/services/tts_service.dart`
**Current Lines**: 350+
**Changes**: Use Web Speech API on web

**Before**:
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

**After**:
```dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class TTSService {
  html.SpeechSynthesis? _webSynthesis;

  Future<void> speak(String text) async {
    if (kIsWeb) {
      _webSynthesis ??= html.window.speechSynthesis;
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'en-US';
      utterance.rate = 0.9;
      _webSynthesis!.speak(utterance);
    } else {
      await _tts.setVoice({'name': 'Karen', 'locale': 'en-AU'});
      await _tts.speak(text);
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      _webSynthesis?.cancel();
    } else {
      await _tts.stop();
    }
  }
}
```

**Effort**: 1 day

---

### 7. Main Initialization
**Path**: `lib/main.dart`
**Current Lines**: 150
**Changes**: Add platform checks

**Lines 30-35** (before):
```dart
// Enable edge-to-edge mode for Android 15+
SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

// Initialize timezone database
tz.initializeTimeZones();
```

**Lines 30-38** (after):
```dart
if (!kIsWeb) {
  // Enable edge-to-edge mode for Android 15+ (mobile only)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

// Initialize timezone database (works on all platforms)
tz.initializeTimeZones();

// Register Service Worker (web only)
if (kIsWeb) {
  html.window.navigator.serviceWorker!.register('/sw.js');
}
```

**Effort**: 0.5 days

---

## Files Requiring Minor Changes

### Platform Checks in Screens

**Files**: 8 screens
- `lib/screens/home_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/chat_screen.dart`
- `lib/screens/bible_browser_screen.dart`
- `lib/screens/devotional_screen.dart`
- `lib/screens/prayer_journal_screen.dart`
- `lib/screens/reading_plan_screen.dart`

**Changes**: Add conditional UI for web vs mobile

**Example** (`lib/screens/settings_screen.dart`):
```dart
// Before
ListTile(
  title: Text('Biometric Lock'),
  subtitle: Text('Use Face ID or Touch ID'),
  trailing: Switch(value: biometricEnabled, onChanged: _toggleBiometric),
)

// After
if (!kIsWeb) // Only show on mobile
  ListTile(
    title: Text('Biometric Lock'),
    subtitle: Text('Use Face ID or Touch ID'),
    trailing: Switch(value: biometricEnabled, onChanged: _toggleBiometric),
  ),

if (kIsWeb) // Show WebAuthn option on web
  ListTile(
    title: Text('Passwordless Login'),
    subtitle: Text('Use security key or biometrics'),
    trailing: Switch(value: webAuthnEnabled, onChanged: _toggleWebAuthn),
  ),
```

**Effort**: 0.5 days per screen = 4 days total

---

## Files Safe to Keep

### All UI Components (48+ files)
- ✅ All widget files in `lib/components/`
- ✅ All provider files in `lib/core/providers/`
- ✅ All utility files in `lib/utils/`
- ✅ Theming and localization

**Examples**:
- `lib/components/frosted_glass_card.dart` - Pure Flutter widgets
- `lib/components/glass_card.dart` - Pure Flutter widgets
- `lib/components/offline_indicator.dart` - Works on web (connectivity_plus has web support)
- `lib/core/providers/app_providers.dart` - Riverpod works on web
- `lib/l10n/` - Localization works on web
- `lib/utils/` - Pure Dart utilities

**No Changes Required**: These files work as-is on web

---

## Import Statement Patterns

### Conditional Imports

**Pattern 1**: Platform-specific implementation
```dart
// lib/core/database/database_helper.dart
import 'package:sqflite_common/sqflite.dart'
    if (dart.library.html) '../database/sql_js_helper.dart';
```

**Pattern 2**: Platform detection
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web implementation
} else {
  // Mobile implementation
}
```

**Pattern 3**: HTML-specific imports
```dart
import 'dart:html' as html show window, Notification;
```

### Common Platform Checks

```dart
// Simple check
if (kIsWeb) { /* web code */ }

// Detailed platform check
if (kIsWeb) {
  // Web
} else if (Platform.isIOS) {
  // iOS
} else if (Platform.isAndroid) {
  // Android
}

// Feature detection
if (html.window.indexedDB != null) {
  // IndexedDB available
}

if ('Notification' in html.window) {
  // Notifications available
}
```

---

## Git Strategy

### Branch Structure
```
main (production)
├── web-pwa (development)
    ├── feature/database-migration
    ├── feature/stripe-integration
    ├── feature/web-notifications
    └── feature/pwa-manifest
```

### Commit Checklist

**Phase 1: Setup**
- [ ] `feat: add Flutter web support and PWA configuration`
- [ ] `feat: create PWA manifest and Service Worker`
- [ ] `chore: update dependencies for web platform`

**Phase 2: Database**
- [ ] `feat: add sql.js wrapper for web SQLite`
- [ ] `feat: migrate DatabaseHelper to support web platform`
- [ ] `test: add integration tests for web database`

**Phase 3: Subscriptions**
- [ ] `feat: add Stripe Checkout integration for web`
- [ ] `feat: create backend API for subscription management`
- [ ] `refactor: update SubscriptionService for multi-platform`

**Phase 4: Notifications**
- [ ] `feat: add Web Notifications API implementation`
- [ ] `feat: implement Service Worker push notifications`
- [ ] `refactor: update NotificationService for web`

**Phase 5: Auth**
- [ ] `feat: add WebAuthn biometric authentication`
- [ ] `refactor: update AppLockoutService for web`

**Phase 6: Cleanup**
- [ ] `remove: delete iOS-only widget service`
- [ ] `refactor: add platform checks across screens`
- [ ] `docs: update README with PWA deployment instructions`

### Merge Strategy
```bash
# Merge feature branches into web-pwa
git checkout web-pwa
git merge feature/database-migration
git merge feature/stripe-integration

# Test thoroughly on web-pwa branch

# Merge web-pwa into main when ready
git checkout main
git merge web-pwa --no-ff
git tag v2.0.0-web
git push origin main --tags
```

---

## Quick Reference

### Files to Delete (2)
1. `lib/services/widget_service.dart`
2. iOS-only package entries in `pubspec.yaml`

### Files to Create (4+)
1. `lib/core/database/sql_js_helper.dart`
2. `web/sw.js`
3. `web/manifest.json`
4. Backend API (separate repo)

### Files to Heavily Modify (7)
1. `lib/core/database/database_helper.dart`
2. `lib/core/services/subscription_service.dart`
3. `lib/core/services/notification_service.dart`
4. `lib/screens/paywall_screen.dart`
5. `lib/core/services/app_lockout_service.dart`
6. `lib/services/tts_service.dart`
7. `lib/main.dart`

### Files Requiring Minor Changes (8)
All main screens - add platform checks for UI elements

### Files Safe to Keep (48+)
All UI components, providers, utilities, theming

---

**Total Effort Estimate**: 800-1200 developer hours (4-8 weeks)

**Next Step**: Begin with Phase 1 (Database Migration)
