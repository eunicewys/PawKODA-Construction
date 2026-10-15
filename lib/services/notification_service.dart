import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// NotificationService: Centralized singleton service for handling local 
/// and scheduled phone notifications for PawKODA.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Default Channel ID for general high priority health alerts
  static const String channelId = 'pawkoda_health_channel';
  static const String channelName = 'Health Alerts & Reminders';
  static const String channelDescription = 
      'Notifications for pet vaccinations, deworming, medical issues, and bookings.';

  /// Health Reminders Channel ID
  static const String healthRemindersChannelId = 'pawkoda_health_reminders';
  static const String healthRemindersChannelName = 'Pet Health & Vaccine Reminders';
  static const String healthRemindersChannelDescription = 
      'Notifications for upcoming vaccinations and deworming boosters.';

  /// Initialize timezones, local notification plugin, permissions, and channels
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezone database and set local timezone to Kuala Lumpur
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    } catch (e) {
      debugPrint("NotificationService Timezone Error: $e");
    }

    // 2. Configure Android & iOS Initialization Settings
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

    // 3. Initialize Flutter Local Notifications Plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification tapped with payload: ${response.payload}");
      },
    );

    // 4. Create High-Importance Notification Channels for Android
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel healthChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel healthRemindersChannel = AndroidNotificationChannel(
        healthRemindersChannelId,
        healthRemindersChannelName,
        description: healthRemindersChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin.createNotificationChannel(healthChannel);
      await androidPlugin.createNotificationChannel(healthRemindersChannel);
    }

    // 5. Request Runtime Permissions (Android 13+ & Exact Alarms)
    await requestNotificationsPermission();
    await requestExactAlarmsPermission();

    _isInitialized = true;
    debugPrint("NotificationService initialized successfully.");
  }

  /// Request POST_NOTIFICATIONS permission for Android 13+ (API 33+)
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

  /// Request Exact Alarms permission for precise time triggers (Android 12+)
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

  /// Trigger an instant local notification banner
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Schedule a local notification banner at a specific future date and time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Prevent scheduling dates in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint("Cannot schedule notification in the past ($scheduledDate)");
      return;
    }

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint("Scheduled Notification #$id for $scheduledDate ($tzScheduledDate)");
  }

  /// Schedule a health reminder 3 days before `nextDueDate` at user's preferred time (defaults to 09:00 AM) in Kuala Lumpur timezone.
  /// If the calculated reminder date/time is in the past, triggers an immediate overdue notice instead.
  Future<void> scheduleHealthReminder({
    required int id,
    required String petName,
    required String treatmentName,
    required DateTime nextDueDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    // 1. Calculate target date: strictly 3 days before nextDueDate
    final targetDate = nextDueDate.subtract(const Duration(days: 3));

    // 2. Combine with user's selected time in 'Asia/Kuala_Lumpur' timezone
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetDate.year,
      targetDate.month,
      targetDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // 3. Check if scheduledDate is already in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      await showImmediateOverdueNotice(
        id: id,
        petName: petName,
        treatmentName: treatmentName,
      );
      return;
    }

    // 4. Format Date for notification body
    final String formattedDueDate = DateFormat('dd MMM yyyy').format(nextDueDate);

    final String title = "Reminder: $petName's $treatmentName Due Soon! 🐾";
    final String body = "$petName is due for their $treatmentName dose in 3 days ($formattedDueDate). Book a clinic visit today!";

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthRemindersChannelId,
      healthRemindersChannelName,
      channelDescription: healthRemindersChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'health_reminder_$id',
    );

    debugPrint("Scheduled Health Reminder #$id for $petName's $treatmentName on $scheduledDate");
  }

  /// Trigger an immediate heads-up notice for an overdue or due health treatment
  Future<void> showImmediateOverdueNotice({
    required int id,
    required String petName,
    required String treatmentName,
  }) async {
    final String title = "Attention: $petName's $treatmentName is Due!";
    final String body = "$treatmentName for $petName is due or overdue. Please arrange a veterinary checkup.";

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthRemindersChannelId,
      healthRemindersChannelName,
      channelDescription: healthRemindersChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: 'health_overdue_$id',
    );

    debugPrint("Showed Immediate Overdue Notice #$id for $petName's $treatmentName");
  }

  /// Cancel a scheduled health reminder or notification by unique ID
  Future<void> cancelReminder(int id) async {
    await cancelNotification(id);
  }

  /// Cancel a scheduled notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint("Cancelled Notification #$id");
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("Cancelled all notifications.");
  }
}
