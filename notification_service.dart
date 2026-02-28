import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// NotificationService - handles local push notifications
/// Used by n8n background tasks for morning alerts and complaint triggers
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ─────────────────────────────────────────────────────────────
  // INITIALIZE
  // ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW COMPLAINT ALERT NOTIFICATION
  // ─────────────────────────────────────────────────────────────
  static Future<void> showComplaintAlert({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _ensureInitialized();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'complaints_channel',
      'Garbage Complaints',
      channelDescription: 'Alerts for garbage complaints and collection',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00C875),
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW MORNING REMINDER (scheduled)
  // ─────────────────────────────────────────────────────────────
  static Future<void> scheduleMorningReminder({
    required String message,
    int hour = 6,
    int minute = 0,
  }) async {
    await _ensureInitialized();

    await _plugin.cancelAll();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'morning_channel',
      'Morning Alerts',
      channelDescription: 'Daily morning reminders for garbage collectors',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00C875),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1,
      '🌅 Morning Route Ready!',
      message,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW POINTS EARNED NOTIFICATION
  // ─────────────────────────────────────────────────────────────
  static Future<void> showPointsEarned({
    required int points,
    required String activity,
  }) async {
    await _ensureInitialized();

    await _plugin.show(
      2,
      '⭐ +$points Points Earned!',
      activity,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'points_channel',
          'Points & Rewards',
          channelDescription: 'Notifications for earned points and badges',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4FF00),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW N8N TRIGGER CONFIRMATION
  // ─────────────────────────────────────────────────────────────
  static Future<void> showN8nTriggerConfirmation({
    required String complaintId,
    required String ward,
  }) async {
    await _ensureInitialized();
    await showComplaintAlert(
      title: '✅ Collector Notified',
      body:
          'Ward $ward garbage collector has been alerted via WhatsApp & SMS. Complaint #${complaintId.substring(0, 6).toUpperCase()}',
      payload: complaintId,
      id: 3,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CANCEL ALL
  // ─────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation logic can be added here via navigator key
  }
}
