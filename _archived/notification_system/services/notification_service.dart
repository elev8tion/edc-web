import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:everyday_christian/core/services/devotional_progress_service.dart';
import 'package:everyday_christian/services/unified_verse_service.dart';
import 'package:everyday_christian/core/services/prayer_service.dart';
import 'package:everyday_christian/core/services/reading_plan_service.dart';
import 'package:everyday_christian/core/services/database_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Data services for notification content
  late final DevotionalProgressService _devotionalService;
  late final UnifiedVerseService _verseService;
  late final PrayerService _prayerService;
  late final ReadingPlanService _readingPlanService;

  // Constructor accepts DatabaseService instance
  NotificationService(DatabaseService database) {
    _devotionalService = DevotionalProgressService(database);
    _verseService = UnifiedVerseService();
    _prayerService = PrayerService(database);
    _readingPlanService = ReadingPlanService(database);
  }

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap with payload routing
    if (response.payload != null) {
      _handleNotificationPayload(response.payload!);
    }
  }

  void _handleNotificationPayload(String payload) {
    // Parse payload and navigate accordingly
    // Format: "type:data" e.g., "verse:John 3:16" or "prayer:123"
    final parts = payload.split(':');
    if (parts.length >= 2) {
      final type = parts[0];
      final data = parts.sublist(1).join(':');

      switch (type) {
        case 'verse':
          // Navigate to daily verse screen with verse reference
          _navigateToDailyVerse(data);
          break;
        case 'prayer':
          // Navigate to prayer journal
          _navigateToPrayer(data);
          break;
        case 'reading':
          // Navigate to reading plan
          _navigateToReading(data);
          break;
      }
    }
  }

  void _navigateToDailyVerse(String reference) {
    // This will be handled by the app's navigation service
  }

  void _navigateToPrayer(String prayerId) {
    // Navigation to prayer journal
  }

  void _navigateToReading(String planId) {
    // Navigation to reading plan
  }

  Future<void> scheduleDailyDevotional({
    required int hour,
    required int minute,
  }) async {
    // Get today's devotional content
    final devotional = await _devotionalService.getTodaysDevotional();

    final title = devotional != null
        ? 'Daily Devotional: ${devotional.title}'
        : 'Daily Devotional';

    final body = devotional != null
        ? '${devotional.reflection.split('\n').first.substring(0, devotional.reflection.length > 100 ? 100 : devotional.reflection.length)}...'
        : 'Start your day with God\'s word';

    await _notifications.zonedSchedule(
      1,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'devotional_channel',
          'Daily Devotional',
          channelDescription: 'Daily devotional reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'devotional:${devotional?.id ?? "today"}',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyVerse({
    required int hour,
    required int minute,
  }) async {
    // Get today's daily verse from the verse service
    final verse = await _verseService.getDailyVerse();

    final verseReference = verse != null
        ? verse.reference
        : 'Verse of the Day';

    final verseText = verse != null
        ? verse.text
        : 'Tap to read today\'s verse';

    final versePreview = verseText.length > 100
        ? '${verseText.substring(0, 100)}...'
        : verseText;

    // Create payload for deep linking
    final payload = 'verse:$verseReference';

    await _notifications.zonedSchedule(
      3, // Unique ID for daily verse notifications
      'Verse of the Day',
      '$verseReference - $versePreview',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_verse_channel',
          'Daily Verse',
          channelDescription: 'Daily verse notifications',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            verseText,
            contentTitle: 'Verse of the Day',
            summaryText: verseReference,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showDailyVerseNotification({
    required String verseReference,
    required String verseText,
  }) async {
    try {
      // Check permission status first
      final permissionStatus = await Permission.notification.status;

      if (!permissionStatus.isGranted) {
        final newStatus = await Permission.notification.request();
        if (!newStatus.isGranted) {
          return;
        }
      }

      // Immediate notification for testing or on-demand
      final payload = 'verse:$verseReference';

      await _notifications.show(
        3,
        'Verse of the Day',
        '$verseReference - ${verseText.substring(0, verseText.length > 50 ? 50 : verseText.length)}...',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_verse_channel',
            'Daily Verse',
            channelDescription: 'Daily verse notifications',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              verseText,
              contentTitle: 'Verse of the Day',
              summaryText: verseReference,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      // Silent failure in production
      // Error details: $e
    }
  }

  Future<void> schedulePrayerReminder({
    required int hour,
    required int minute,
  }) async {
    // Get active prayer requests
    final prayers = await _prayerService.getActivePrayers();
    final prayerCount = prayers.length;

    final title = prayerCount > 0
        ? 'Prayer Reminder'
        : 'Time to Pray';

    final body = prayerCount > 0
        ? 'You have $prayerCount prayer ${prayerCount == 1 ? "request" : "requests"} to lift up today'
        : 'Take a moment to spend time with God';

    await _notifications.zonedSchedule(
      2,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Reminders',
          channelDescription: 'Prayer reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'prayer:active',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleReadingPlanReminder({
    required int hour,
    required int minute,
  }) async {
    // Get current active reading plan
    final currentPlan = await _readingPlanService.getCurrentPlan();

    final title = currentPlan != null
        ? 'Bible Reading: ${currentPlan.title}'
        : 'Bible Reading';

    final body = currentPlan != null
        ? 'Continue your reading plan today'
        : 'Start a reading plan to grow in God\'s word';

    await _notifications.zonedSchedule(
      4,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_channel',
          'Reading Plan',
          channelDescription: 'Bible reading plan reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'reading:${currentPlan?.id ?? "none"}',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}