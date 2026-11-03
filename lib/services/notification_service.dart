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

    // 2. Initialization Settings for Android & iOS
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
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

  /// Ensures notification ID is a unique, stable 32-bit positive integer (0 to 2,147,483,000).
  /// Uses FNV-1a 32-bit deterministic hashing so identical string IDs hash to the EXACT same integer
  /// across app restarts and device reboots.
  int _toSafeNotificationId(dynamic input) {
    if (input == null) {
      return (DateTime.now().millisecondsSinceEpoch.abs() % 2147483000);
    }
    if (input is int) {
      return (input.abs() % 2147483000);
    }

    final String str = input.toString();
    int hash = 2166136261;
    for (int i = 0; i < str.length; i++) {
      hash ^= str.codeUnitAt(i);
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return (hash.abs() % 2147483000);
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
  /// Schedules local phone notifications ONLY for 09:00 AM sharp (starting 3 days before up to due date).
  /// If today's 09:00 AM has already passed, schedules for tomorrow at 09:00 AM sharp.
  /// Never triggers immediate banner popups while user is navigating inside the app.
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

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Calculate target date: 3 days before due date at 09:00 AM
    final DateTime targetDay = nextDueDate.subtract(const Duration(days: 3));

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If 3 days prior 09:00 AM has already passed
    if (scheduledDate.isBefore(now)) {
      final tz.TZDateTime today9AM = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (now.isBefore(today9AM)) {
        scheduledDate = today9AM;
      } else {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + 1,
          reminderTime.hour,
          reminderTime.minute,
        );
      }
    }

    final tz.TZDateTime dueDateCutoff = tz.TZDateTime(
      tz.local,
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
      23,
      59,
    );

    // If scheduled date exceeds due date or is past, do not schedule further
    if (scheduledDate.isAfter(dueDateCutoff) || scheduledDate.isBefore(now)) {
      debugPrint("Health reminder due date $nextDueDate passed or past 9:00 AM today. No instant popups in app.");
      return;
    }

    // Cancel any existing alarm with same safeId before scheduling new one
    await cancelReminder(actualRawId);

    final String dateStr = "${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}";

    final String title = "Reminder: $petName's $formattedRecordType Due Soon";
    final String body = "$formattedRecordType ($treatmentName) is due on $dateStr. Tap dropdown for full details.";

    final String bigText = "<b>Pet Name:</b> $petName<br/>"
        "<b>Record Type:</b> $formattedRecordType<br/>"
        "<b>Treatment:</b> $treatmentName<br/>"
        "<b>Due Date:</b> $dateStr<br/><br/>"
        "Please arrange a vet appointment today to keep $petName's health booster schedule up to date.";
    final String summaryText = "$petName • Health Reminder";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: summaryText,
        htmlFormatSummaryText: true,
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

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
      debugPrint("Health reminder scheduled for 9:00 AM sharp at $scheduledDate (ID:$safeId)");
    } catch (e) {
      try {
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
        debugPrint("Health reminder fallback scheduled for $scheduledDate (ID:$safeId)");
      } catch (e2) {
        debugPrint("Error scheduling health reminder: $e2");
      }
    }
  }

  /// Schedule Vet Appointment Booking Reminder 3 days before event date at 09:00 AM sharp.
  /// If today's 09:00 AM has passed, schedules for tomorrow at 09:00 AM sharp.
  /// Never triggers immediate banner popups while user is in the app.
  Future<void> scheduleBookingReminder({
    required String bookingId,
    required String petName,
    required String clinicName,
    required String serviceType,
    required DateTime bookingDate,
    required String timeSlot,
  }) async {
    final int safeId = _toSafeNotificationId('booking_3d_$bookingId');

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Target: 3 days before appointment at 09:00 AM
    final DateTime targetDay = bookingDate.subtract(const Duration(days: 3));
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      final tz.TZDateTime today9AM = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9,
        0,
      );

      if (now.isBefore(today9AM)) {
        scheduledDate = today9AM;
      } else {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + 1,
          9,
          0,
        );
      }
    }

    final tz.TZDateTime apptCutoff = tz.TZDateTime(
      tz.local,
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      23,
      59,
    );

    if (scheduledDate.isAfter(apptCutoff) || scheduledDate.isBefore(now)) {
      debugPrint("Booking date $bookingDate has passed or today 9:00 AM passed. Next reminder tomorrow 9:00 AM.");
      return;
    }

    await cancelNotification(safeId);

    final String apptDateStr = "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";

    final String title = "Reminder: $petName's Vet Appointment in 3 Days";
    final String body = "$serviceType at $clinicName on $apptDateStr ($timeSlot). Tap dropdown for details.";

    final String bigText = "<b>Pet Name:</b> $petName<br/>"
        "<b>Clinic Name:</b> $clinicName<br/>"
        "<b>Service Type:</b> $serviceType<br/>"
        "<b>Appointment Date:</b> $apptDateStr<br/>"
        "<b>Time Slot:</b> $timeSlot<br/><br/>"
        "Your appointment is in 3 days. Please arrive 10 minutes before your scheduled time slot.";
    final String summaryText = "$petName • Appointment Reminder";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: summaryText,
        htmlFormatSummaryText: true,
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        safeId,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'booking_reminder_$safeId',
      );
      debugPrint("Scheduled 9:00 AM vet booking reminder for $scheduledDate (ID:$safeId)");
    } catch (e) {
      try {
        await _notificationsPlugin.zonedSchedule(
          safeId,
          title,
          body,
          scheduledDate,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'booking_reminder_$safeId',
        );
        debugPrint("Scheduled fallback 9:00 AM vet booking reminder for $scheduledDate (ID:$safeId)");
      } catch (e2) {
        debugPrint("Error scheduling booking reminder: $e2");
      }
    }
  }

  /// Instant notification banner helper (only when explicitly called, e.g., on booking confirmation)
  Future<void> showNotification({
    dynamic baseId,
    dynamic id,
    dynamic rawId,
    required String title,
    required String body,
    String? payload,
  }) async {
    final int safeId = _toSafeNotificationId(rawId ?? baseId ?? id ?? title);

    final String bigText = body.contains('<br/>') || body.contains('\n')
        ? body
        : "$body<br/><br/><i>Tap or pull down to view full notification details.</i>";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
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
