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
  /// Triggers exactly 3 days before `nextDueDate` at 09:00 AM in local time.
  /// Clean, un-crowded formatting without emojis.
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

    // Calculate target date: 3 days before due date
    final DateTime targetDay = nextDueDate.subtract(const Duration(days: 3));

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If 3 days prior is in the past, but due date is still in the future
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
        final tz.TZDateTime next9AM = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.hour < reminderTime.hour ? now.day : now.day + 1,
          reminderTime.hour,
          reminderTime.minute,
        );

        if (next9AM.isBefore(dueDateAt9)) {
          scheduledDate = next9AM;
        } else {
          scheduledDate = dueDateAt9;
        }
      }
    }

    debugPrint("Current Time: $now");
    debugPrint("Target Scheduled Time: $scheduledDate (ID:$safeId)");

    final String dateStr = "${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}";

    // Clean Title & Collapsed Body without emojis
    final String title = "Reminder: $petName's $formattedRecordType Due Soon";
    final String body = "$formattedRecordType ($treatmentName) is due on $dateStr. Tap dropdown for full details.";

    // Expanded BigText content shown when user clicks dropdown button
    final String bigText = "<b>Pet Name:</b> $petName<br/>"
        "<b>Record Type:</b> $formattedRecordType<br/>"
        "<b>Treatment:</b> $treatmentName<br/>"
        "<b>Due Date:</b> $dateStr<br/><br/>"
        "Please arrange a vet appointment today to keep $petName's health booster schedule up to date.";
    final String summaryText = "$petName • Health Reminder";

    // If scheduled date is STILL in the past (due date has passed), fire immediate overdue notice
    if (scheduledDate.isBefore(now)) {
      debugPrint("Target reminder time is in the past. Showing immediate alert.");
      await showImmediateOverdueNotice(
        rawId: safeId,
        petName: petName,
        recordType: formattedRecordType,
        treatmentName: treatmentName,
      );
      return;
    }

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
      debugPrint("Health reminder scheduled with exactAllowWhileIdle for $scheduledDate (ID:$safeId)");
    } catch (e) {
      debugPrint("exactAllowWhileIdle failed ($e). Falling back to inexactAllowWhileIdle...");
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

  /// Schedule Vet Appointment Booking Reminder 3 days before event date.
  /// Clean, un-crowded formatting without emojis.
  Future<void> scheduleBookingReminder({
    required String bookingId,
    required String petName,
    required String clinicName,
    required String serviceType,
    required DateTime bookingDate,
    required String timeSlot,
  }) async {
    final int safeId = _toSafeNotificationId('booking_3d_$bookingId');

    await cancelNotification(safeId);

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
      final tz.TZDateTime apptAt9 = tz.TZDateTime(
        tz.local,
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        9,
        0,
      );

      if (apptAt9.isAfter(now)) {
        final tz.TZDateTime next9AM = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.hour < 9 ? now.day : now.day + 1,
          9,
          0,
        );
        if (next9AM.isBefore(apptAt9)) {
          scheduledDate = next9AM;
        } else {
          scheduledDate = apptAt9;
        }
      }
    }

    if (scheduledDate.isBefore(now)) {
      debugPrint("Booking date $bookingDate is in the past. Skipping 3-day booking reminder.");
      return;
    }

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
      debugPrint("Scheduled 3-day vet booking reminder for $scheduledDate (ID:$safeId)");
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
        debugPrint("Scheduled fallback 3-day vet booking reminder for $scheduledDate (ID:$safeId)");
      } catch (e2) {
        debugPrint("Error scheduling booking reminder: $e2");
      }
    }
  }

  /// Immediate alert if record is overdue or date has already passed. Clean text without emojis.
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

    final String title = "Overdue Alert: $petName's $formattedRecordType ($treatmentName)";
    final String body = "Treatment is overdue. Tap dropdown for full details.";

    final String bigText = "<b>Pet Name:</b> $petName<br/>"
        "<b>Record Type:</b> $formattedRecordType<br/>"
        "<b>Treatment:</b> $treatmentName<br/><br/>"
        "This booster schedule is overdue. Please arrange a vet appointment today to ensure $petName stays protected.";
    final String summaryText = "$petName • Overdue Notice";

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

    await _notificationsPlugin.show(
      safeId,
      title,
      body,
      platformDetails,
      payload: 'health_overdue_$safeId',
    );

    debugPrint("Showed Immediate Overdue Notice ID: $safeId for $petName's $treatmentName");
  }

  /// Instant notification banner helper (e.g. for bookings). Clean text without emojis.
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
