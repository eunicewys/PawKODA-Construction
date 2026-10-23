import 'package:intl/intl.dart';

enum ReminderType {
  booking,
  vaccine,
  deworming,
}

/// Unified ReminderItem model for combining Vet Bookings and Vax & Deworm reminders
class ReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final String petName;
  final String petId;
  final DateTime date;
  final String? timeSlot;
  final ReminderType type;
  final String statusTag;

  const ReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.petName,
    required this.petId,
    required this.date,
    this.timeSlot,
    required this.type,
    required this.statusTag,
  });

  /// Helper to calculate human readable date status: "Today 02:00 PM", "Tomorrow 10:30 AM", "In 3 days", etc.
  String get dateStatusText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diffDays = targetDate.difference(today).inDays;

    final String slotText = (timeSlot != null && timeSlot!.trim().isNotEmpty)
        ? timeSlot!.trim().replaceAll("at ", "")
        : "";

    if (diffDays < 0) {
      final abs = diffDays.abs();
      return "Overdue by $abs day${abs == 1 ? '' : 's'}";
    } else if (diffDays == 0) {
      return "Due";
    } else if (diffDays == 1) {
      return slotText.isNotEmpty ? "Tomorrow $slotText" : "Tomorrow";
    } else if (diffDays <= 7) {
      return "In $diffDays days";
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  /// Helper to check if reminder is due today or overdue
  bool get isUrgent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.compareTo(today) <= 0;
  }
}
