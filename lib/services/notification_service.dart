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

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Default Channel ID for general high priority health alerts
  static const String channelId = 'pawkoda_health_channel_v2';
  static const String channelName = 'Health Alerts & Reminders';
  static const String channelDescription = 
      'Notifications for pet vaccinations, deworming, medical issues, and bookings.';

  /// Health Reminders Channel ID (V2 for High Priority Heads-up Banners)
  static const String healthRemindersChannelId = 'pawkoda_health_reminders_v2';
  static const String healthRemindersChannelName = 'Pet Health & Vaccine Reminders';
  static const String healthRemindersChannelDescription = 
      'Notifications for upcoming vaccinations and deworming boosters.';

  /// Safely format any integer ID to fit within Android 32-bit signed integer limits (0 to 2,147,483,647)
  int _to32BitId(int rawId) {
    return rawId.abs() % 100000000; // Always returns 0 to 99,999,999
  }

  /// Initialize timezones, local notification plugin, permissions, and channels
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
      } catch (e) {
        debugPrint("NotificationService Timezone Error: $e");
      }
    }

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
        debugPrint("Notification tapped with payload: ${response.payload}");
      },
    );

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

    await requestNotificationsPermission();
    await requestExactAlarmsPermission();

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

  /// Trigger an instant local notification banner
  Future<void> showNotification({
    int? baseId,
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final int targetId = _to32BitId(baseId ?? id ?? title.hashCode);
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthRemindersChannelId,
      healthRemindersChannelName,
      channelDescription: healthRemindersChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      targetId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Schedule daily 09:00 AM health reminders starting 3 days prior up to the due date.
  /// Formats titles and bodies without emojis according to exact user spec:
  /// - 3 days, 2 days, 1 day prior:
  ///   Title: "Reminder: [Pet's Name] [Vaccination/Deworming] ([Vaccine/Deworm Name]) due in [how many] days!"
  ///   Body: "Arrange vet appointments for [Pet's Name] now"
  /// - On the Due Date:
  ///   Title: "Alert: TODAY is [Pet's Name] [Vaccination/Deworming] day!"
  ///   Body: "Please visit the vet at scheduled time."
  Future<void> scheduleDailyHealthReminders({
    int? baseId,
    int? id,
    required String petName,
    required String treatmentName,
    required String type, // 'Vaccine' or 'Deworming'
    required DateTime nextDueDate,
  }) async {
    final int targetBaseId = _to32BitId(baseId ?? id ?? treatmentName.hashCode);
    final DateTime now = DateTime.now();
    final String doseTypeLabel = (type.toLowerCase() == 'vaccine') ? 'Vaccination' : 'Deworming';

    // Cancel any previously scheduled alerts for this record ID
    await cancelReminder(targetBaseId);

    // Schedule 4 daily alerts at 09:00 AM (3 days prior, 2 days prior, 1 day prior, and on due date)
    for (int daysPrior = 3; daysPrior >= 0; daysPrior--) {
      final DateTime targetDate = nextDueDate.subtract(Duration(days: daysPrior));
      final DateTime triggerDateTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        9, // Fixed 09:00 AM
        0,
      );

      // Skip past dates/times relative to current device time
      if (triggerDateTime.isBefore(now)) {
        continue;
      }

      // Convert local triggerDateTime into TZDateTime for exact AlarmManager trigger
      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        triggerDateTime,
        tz.local,
      );

      // Construct Title and Body without emojis according to exact user spec
      String title;
      String body;

      if (daysPrior > 0) {
        final String daysText = daysPrior == 1 ? "1 day" : "$daysPrior days";
        title = "Reminder: $petName $doseTypeLabel ($treatmentName) due in $daysText!";
        body = "Arrange vet appointments for $petName now";
      } else {
        title = "Alert: TODAY is $petName $doseTypeLabel day!";
        body = "Please visit the vet at scheduled time.";
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        healthRemindersChannelId,
        healthRemindersChannelName,
        channelDescription: healthRemindersChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      final int notificationId = targetBaseId * 10 + daysPrior;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'health_reminder_${targetBaseId}_$daysPrior',
      );

      debugPrint("Scheduled Reminder #$notificationId for $petName on $triggerDateTime ($title)");
    }
  }

  /// Backward compatible alias for scheduleHealthReminder
  Future<void> scheduleHealthReminder({
    int? baseId,
    int? id,
    required String petName,
    required String treatmentName,
    String type = 'Vaccine',
    required DateTime nextDueDate,
    TimeOfDay? reminderTime,
  }) async {
    await scheduleDailyHealthReminders(
      baseId: baseId,
      id: id,
      petName: petName,
      treatmentName: treatmentName,
      type: type,
      nextDueDate: nextDueDate,
    );
  }

  /// Trigger an immediate heads-up notice for an overdue or due health treatment
  Future<void> showImmediateOverdueNotice({
    int? baseId,
    int? id,
    required String petName,
    required String treatmentName,
    required String type,
  }) async {
    final int targetBaseId = _to32BitId(baseId ?? id ?? treatmentName.hashCode);
    final String doseTypeLabel = (type.toLowerCase() == 'vaccine') ? 'Vaccination' : 'Deworming';
    final String title = "Alert: TODAY is $petName $doseTypeLabel day!";
    final String body = "Please visit the vet at scheduled time.";

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      healthRemindersChannelId,
      healthRemindersChannelName,
      channelDescription: healthRemindersChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      targetBaseId,
      title,
      body,
      platformDetails,
      payload: 'health_overdue_$targetBaseId',
    );

    debugPrint("Showed Immediate Overdue Notice #$targetBaseId for $petName's $treatmentName");
  }

  /// Cancel all scheduled health reminders for a record
  Future<void> cancelReminder(int baseId) async {
    final int safeBaseId = _to32BitId(baseId);
    for (int offset = 0; offset <= 3; offset++) {
      final int notificationId = safeBaseId * 10 + offset;
      await cancelNotification(notificationId);
    }
    // Also cancel viva demo ID
    await cancelNotification(safeBaseId * 10 + 99);
  }

  /// Cancel a scheduled notification by ID
  Future<void> cancelNotification(int id) async {
    final int safeId = _to32BitId(id);
    await _notificationsPlugin.cancel(safeId);
    debugPrint("Cancelled Notification #$safeId");
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("Cancelled all notifications.");
  }
}
