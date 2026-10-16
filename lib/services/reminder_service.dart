import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/health_model.dart';
import '../models/pet_model.dart';
import '../models/reminder_model.dart';
import 'booking_service.dart';
import 'health_service.dart';

/// ReminderService: Merges real-time streams from BookingService and HealthService
/// to produce unified, sorted upcoming reminders for the user's home screen.
class ReminderService {
  final BookingService _bookingService = BookingService();
  final HealthService _healthService = HealthService();

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

      // 1. Process Vet Bookings
      for (final booking in currentBookings) {
        if (booking.status == 'CANCELLED') continue;

        final bDate = DateTime(
          booking.bookingDate.year,
          booking.bookingDate.month,
          booking.bookingDate.day,
        );

        // Include today's and future bookings
        if (bDate.isBefore(startOfToday)) continue;

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
}
