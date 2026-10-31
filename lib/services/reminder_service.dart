import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/health_model.dart';
import '../models/pet_model.dart';
import '../models/reminder_model.dart';
import 'booking_service.dart';
import 'health_service.dart';
import 'notification_service.dart';
import 'user_notification_service.dart';

/// ReminderService: Merges real-time streams from BookingService and HealthService
/// to produce unified, sorted upcoming reminders for the user's home screen.
/// Automatically schedules local 3-days-before push notifications and syncs in-app logs.
class ReminderService {
  final BookingService _bookingService = BookingService();
  final HealthService _healthService = HealthService();
  final UserNotificationService _userNotificationService = UserNotificationService();

  /// Streams unified upcoming reminders (Vet Appointments + Vaccine/Deworming Boosters)
  Stream<List<ReminderItem>> streamUpcomingReminders(String userId, List<PetProfile> pets) {
    late StreamController<List<ReminderItem>> controller;
    final List<StreamSubscription> subscriptions = [];

    List<BookingModel> currentBookings = [];
    final Map<String, List<VaccinationRecord>> currentVaxMap = {};

    void emitReminders() {
      if (controller.isClosed) return;

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final List<ReminderItem> items = [];

      // 1. Process Vet Bookings (Only show CONFIRMED appointments until 2 hours after appointment time)
      for (final booking in currentBookings) {
        if (booking.status.toUpperCase() != 'CONFIRMED') continue;

        DateTime apptDateTime = booking.bookingDate;
        try {
          if (booking.timeSlot.isNotEmpty) {
            final parts = booking.timeSlot.trim().split(' ');
            final timeParts = parts[0].split(':');
            int hour = int.parse(timeParts[0]);
            final int minute = int.parse(timeParts[1]);
            final String period = parts[1].toUpperCase();

            if (period == 'PM' && hour < 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }

            apptDateTime = DateTime(
              booking.bookingDate.year,
              booking.bookingDate.month,
              booking.bookingDate.day,
              hour,
              minute,
            );
          }
        } catch (_) {}

        // Cutoff: 2 hours after appointment time
        final cutoffTime = apptDateTime.add(const Duration(hours: 2));

        // If 2 hours after appointment time has passed, remove from Upcoming Reminders!
        if (now.isAfter(cutoffTime)) continue;

        items.add(ReminderItem(
          id: booking.id,
          title: booking.serviceType,
          subtitle: "${booking.petName} • ${booking.clinicName}",
          petName: booking.petName,
          petId: booking.petId,
          date: booking.bookingDate,
          timeSlot: booking.timeSlot,
          type: ReminderType.booking,
          statusTag: booking.status,
        ));
      }

      // 2. Process Vaccinations & Deworming
      for (final pet in pets) {
        final records = currentVaxMap[pet.id] ?? [];
        for (final rec in records) {
          // Include uncompleted records that have a due date
          if (rec.isCompleted || rec.dueDate == null) continue;

          final dueDateOnly = DateTime(
            rec.dueDate!.year,
            rec.dueDate!.month,
            rec.dueDate!.day,
          );

          // Remove passed due dates from Homepage Upcoming Reminders
          if (dueDateOnly.isBefore(startOfToday)) continue;

          final isDeworming = rec.type.toLowerCase() == 'deworming';
          final typeEnum = isDeworming ? ReminderType.deworming : ReminderType.vaccine;

          items.add(ReminderItem(
            id: rec.id,
            title: rec.doseName.isNotEmpty
                ? rec.doseName
                : (isDeworming ? "Deworming Booster" : "Vaccine Booster"),
            subtitle: "${pet.name} • ${rec.vetName.isNotEmpty ? rec.vetName : (isDeworming ? 'Deworming' : 'Vaccination')}",
            petName: pet.name,
            petId: pet.id,
            date: rec.dueDate!,
            timeSlot: rec.reminderTime,
            type: typeEnum,
            statusTag: isDeworming ? 'Deworming' : 'Vaccine',
          ));
        }
      }

      // Sort by date ascending (earliest due / booked first)
      items.sort((a, b) => a.date.compareTo(b.date));

      controller.add(items);

      // Trigger background 3-day notification sync for local push & in-app logs
      sync3DayRemindersAndNotifications(
        userId: userId,
        bookings: currentBookings,
        vaxMap: currentVaxMap,
        pets: pets,
      );
    }

    controller = StreamController<List<ReminderItem>>.broadcast(
      onListen: () {
        // Subscribe to user's vet bookings
        final bookingSub = _bookingService.streamUserBookings(userId).listen(
          (bookings) {
            currentBookings = bookings;
            emitReminders();
          },
          onError: (err) {
            debugPrint("Error streaming bookings for reminders: $err");
            emitReminders();
          },
        );
        subscriptions.add(bookingSub);

        // Subscribe to vaccinations/deworms for each pet
        for (final pet in pets) {
          final vaxSub = _healthService.streamVaccinations(userId, pet.id).listen(
            (vaxList) {
              currentVaxMap[pet.id] = vaxList;
              emitReminders();
            },
            onError: (err) {
              debugPrint("Error streaming vaccinations for pet ${pet.id}: $err");
              emitReminders();
            },
          );
          subscriptions.add(vaxSub);
        }

        // Emit initial empty state or whatever data is currently ready
        emitReminders();
      },
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// Background sync to verify local phone 3-days-before push notifications
  /// and log in-app notification center alerts when within 3 days.
  Future<void> sync3DayRemindersAndNotifications({
    required String userId,
    required List<BookingModel> bookings,
    required Map<String, List<VaccinationRecord>> vaxMap,
    required List<PetProfile> pets,
  }) async {
    if (userId.isEmpty) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 1. Process Confirmed Bookings
    for (final booking in bookings) {
      if (booking.status.toUpperCase() != 'CONFIRMED') continue;

      final bookingDateOnly = DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
      );

      final diffDays = bookingDateOnly.difference(todayStart).inDays;

      if (diffDays >= 0) {
        await NotificationService().scheduleBookingReminder(
          bookingId: booking.id,
          petName: booking.petName,
          clinicName: booking.clinicName,
          serviceType: booking.serviceType,
          bookingDate: booking.bookingDate,
          timeSlot: booking.timeSlot,
        );
      }

      if (diffDays >= 0 && diffDays <= 3) {
        final String title = "Reminder: ${booking.petName}'s Vet Appointment in 3 Days!";
        final String body = "${booking.serviceType} at ${booking.clinicName} on ${booking.bookingDate.day}/${booking.bookingDate.month} at ${booking.timeSlot}.";
        await _userNotificationService.checkAndLog3DayReminder(
          userId: userId,
          itemId: booking.id,
          title: title,
          body: body,
          type: 'booking',
        );
      }
    }

    // 2. Process Vaccination & Deworming Records
    for (final pet in pets) {
      final vaxList = vaxMap[pet.id] ?? [];
      for (final rec in vaxList) {
        if (rec.isCompleted || rec.dueDate == null) continue;

        final dueDateOnly = DateTime(
          rec.dueDate!.year,
          rec.dueDate!.month,
          rec.dueDate!.day,
        );

        final diffDays = dueDateOnly.difference(todayStart).inDays;

        if (diffDays >= 0) {
          await NotificationService().scheduleHealthReminder(
            rawId: rec.id,
            petName: pet.name,
            recordType: rec.type,
            treatmentName: rec.doseName,
            nextDueDate: rec.dueDate!,
          );
        }

        if (diffDays >= 0 && diffDays <= 3) {
          final isDeworm = rec.type.toLowerCase() == 'deworming' || rec.type.toLowerCase() == 'deworm';
          final typeName = isDeworm ? 'Deworming' : 'Vaccination';
          final title = "Reminder: ${pet.name}'s $typeName (${rec.doseName}) Due Soon!";
          final body = "Scheduled due date: ${rec.dueDate!.day}/${rec.dueDate!.month}/${rec.dueDate!.year}. Please arrange vet appointment.";
          await _userNotificationService.checkAndLog3DayReminder(
            userId: userId,
            itemId: rec.id,
            title: title,
            body: body,
            type: isDeworm ? 'deworming' : 'vaccine',
          );
        }
      }
    }
  }
}
