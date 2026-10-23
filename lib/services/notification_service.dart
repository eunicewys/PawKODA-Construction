import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// NotificationService: Centralized singleton service for handling local
/// and scheduled phone notifications for PawKODA.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Single Source of Truth for Notification Channel Constants
  static const String healthChannelId = 'pawkoda_health_reminders';
  static const String healthChannelName = 'Pet Health & Vaccine Reminders';
  static const String healthChannelDesc =
      'Notifications for upcoming vaccinations and deworming boosters.';

  // Aliases for backward compatibility
  static const String channelId = healthChannelId;
  static const String channelName = healthChannelName;
  static const String channelDesc = healthChannelDesc;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    } catch (_) {
      try {
        final String timeZoneName = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint("Warning: Could not set local timezone. Falling back to UTC: $e");
      }
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification clicked with payload: ${response.payload}");
      },
    );

    // 3. Create High-Importance Notification Channel
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        healthChannelId,
        healthChannelName,
        description: healthChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation?.createNotificationChannel(channel);

      // 4. Request Runtime & Exact Alarm Permissions (Android 13+)
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }

    _isInitialized = true;
    debugPrint("NotificationService initialized successfully.");
  }

  Future<bool?> requestNotificationsPermission() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint("POST_NOTIFICATIONS Granted: $granted");
      return granted;
    }
    return false;
  }

  Future<bool?> requestExactAlarmsPermission() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestExactAlarmsPermission();
      debugPrint("SCHEDULE_EXACT_ALARM Granted: $granted");
      return granted;
    }
    return false;
  }

  /// Ensures notification ID is a safe 32-bit positive integer (0 to 99,999)
  int _toSafeNotificationId(dynamic input) {
    if (input == null) return 0;
    if (input is int) {
      return (input.abs() % 100000);
    }
    return (input.hashCode.abs() % 100000);
  }

  /// Normalize recordType string to 'Vaccination' or 'Deworm'
  String _formatRecordType(String recordType) {
    final lower = recordType.trim().toLowerCase();
    if (lower == 'vaccine' || lower == 'vaccination') {
      return 'Vaccination';
    } else if (lower == 'deworm' || lower == 'deworming') {
      return 'Deworm';
    }
    return recordType;
  }

  /// Schedule Health Reminder
  ///
  /// Triggers exactly 3 days before `nextDueDate` at 09:00 AM (or user-selected time) in Malaysia time.
  /// If 3 days prior has passed but the due date is still in the future, schedules for the next available 9:00 AM.
  /// If the due date has already passed, fires an immediate overdue alert.
  /// Title: Reminder: [Pet Name]'s [Vaccination/Deworm] ([Vaccine Name/Deworm Name]) Due Soon!
  /// Body: Arrange Vet appointment today.
  Future<void> scheduleHealthReminder({
    dynamic rawId,
    dynamic baseId,
    dynamic id,
    required String petName,
    String? recordType,
    String? type,
    required String treatmentName,
    required DateTime nextDueDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    final dynamic actualRawId = rawId ?? baseId ?? id;
    final int safeId = _toSafeNotificationId(actualRawId);
    final String formattedRecordType = _formatRecordType(recordType ?? type ?? 'Vaccination');

    // Cancel any existing reminder for this safeId first
    await cancelReminder(actualRawId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Calculate target date: exactly 3 days before due date
    final DateTime targetDay = nextDueDate.subtract(const Duration(days: 3));

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If 3 days prior is in the past, but due date is still in the future, adjust target to due date at 9:00 AM
    if (scheduledDate.isBefore(now)) {
      final tz.TZDateTime dueDateAt9 = tz.TZDateTime(
        tz.local,
        nextDueDate.year,
        nextDueDate.month,
        nextDueDate.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (dueDateAt9.isAfter(now)) {
        scheduledDate = dueDateAt9;
      }
    }

    debugPrint("Current Time: $now");
    debugPrint("Target Scheduled Time: $scheduledDate (ID:$safeId)");

    // Exact title & body format
    final String title = "Reminder: $petName's $formattedRecordType ($treatmentName) Due Soon!";
    const String body = "Arrange Vet appointment today.";

    // If scheduled date is STILL in the past (i.e. due date has already passed), fire immediate overdue notice
    if (scheduledDate.isBefore(now)) {
      debugPrint("⚠️ Target reminder time is in the past. Showing immediate alert.");
      await showImmediateOverdueNotice(
        rawId: safeId,
        petName: petName,
        recordType: formattedRecordType,
        treatmentName: treatmentName,
      );
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthChannelId,
      healthChannelName,
      channelDescription: healthChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.notification,
      ticker: 'Pet Health Reminder',
      autoCancel: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    // Request permissions on Android 13+ / exact alarms
    if (Platform.isAndroid) {
      await requestExactAlarmsPermission();
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        safeId,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'health_reminder_$safeId',
      );
      debugPrint("Health reminder scheduled successfully with exactAllowWhileIdle for $scheduledDate (ID:$safeId)");
    } catch (e) {
      debugPrint("Failed to schedule with exact mode ($e). Falling back to inexactAllowWhileIdle...");
      await _notificationsPlugin.zonedSchedule(
        safeId,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'health_reminder_$safeId',
      );
      debugPrint("Health reminder fallback scheduled successfully for $scheduledDate (ID:$safeId)");
    }
  }

  /// Immediate alert if record is overdue or date has already passed
  Future<void> showImmediateOverdueNotice({
    dynamic rawId,
    dynamic baseId,
    dynamic id,
    required String petName,
    String? recordType,
    String? type,
    required String treatmentName,
  }) async {
    final dynamic actualRawId = rawId ?? baseId ?? id;
    final int safeId = _toSafeNotificationId(actualRawId);
    final String formattedRecordType = _formatRecordType(recordType ?? type ?? 'Vaccination');

    final String title = "Reminder: $petName's $formattedRecordType ($treatmentName) Due Soon!";
    const String body = "Arrange Vet appointment today.";

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthChannelId,
      healthChannelName,
      channelDescription: healthChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      safeId,
      title,
      body,
      platformDetails,
      payload: 'health_overdue_$safeId',
    );

    debugPrint("Showed Immediate Overdue Notice ID: $safeId for $petName's $treatmentName");
  }

  /// Instant notification banner helper (e.g. for bookings)
  Future<void> showNotification({
    dynamic baseId,
    dynamic id,
    dynamic rawId,
    required String title,
    required String body,
    String? payload,
  }) async {
    final int safeId = _toSafeNotificationId(rawId ?? baseId ?? id ?? title);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthChannelId,
      healthChannelName,
      channelDescription: healthChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      safeId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Cancel reminder when record is deleted or marked completed
  Future<void> cancelReminder(dynamic rawId) async {
    final int safeId = _toSafeNotificationId(rawId);
    await _notificationsPlugin.cancel(safeId);

    // Also cancel legacy multi-offset notifications if any
    if (rawId is int) {
      final int base = (rawId.abs() % 100000000);
      for (int i = 0; i <= 3; i++) {
        await _notificationsPlugin.cancel(base * 10 + i);
      }
    }
    debugPrint("Cancelled reminder ID: $safeId");
  }

  /// Cancel a scheduled notification by ID
  Future<void> cancelNotification(dynamic id) async {
    final int safeId = _toSafeNotificationId(id);
    await _notificationsPlugin.cancel(safeId);
    debugPrint("Cancelled Notification #$safeId");
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("Cancelled all notifications.");
  }
}
