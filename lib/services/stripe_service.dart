/// Stripe Service Facade
///
/// This file provides a unified API for Stripe payments across platforms.
/// Uses conditional exports to load the appropriate implementation:
/// - Mobile (iOS/Android): Uses flutter_stripe package with CardField
/// - Web (PWA): Uses Stripe Embedded Checkout with JS interop
///
/// Usage:
/// ```dart
/// import 'package:everyday_christian/services/stripe_service.dart';
///
/// // Initialize on app start
/// await initializeStripe();
///
/// // Start subscription flow
/// await startSubscription(context: context, userId: userId);
/// ```

export 'stripe_service_stub.dart'
    if (dart.library.io) 'stripe_service_mobile.dart'
    if (dart.library.js_interop) 'stripe_service_web.dart';
