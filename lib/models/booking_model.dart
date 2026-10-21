import 'package:cloud_firestore/cloud_firestore.dart';

/// BookingModel: Represents a veterinary appointment booked by a pet owner.
class BookingModel {
  final String id;
  final String userId;
  final String petId;
  final String petName;
  final String petSpecies;
  final String clinicId;
  final String clinicName;
  final String clinicAddress;
  final String clinicPhone;
  final String city;
  final String serviceType;
  final DateTime bookingDate;
  final String timeSlot;
  final String preferredVet; // Optional preferred vet / surgeon
  final String notes;
  final String status; // CONFIRMED, PENDING, COMPLETED, CANCELLED
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.petId,
    required this.petName,
    required this.petSpecies,
    required this.clinicId,
    required this.clinicName,
    required this.clinicAddress,
    required this.clinicPhone,
    required this.city,
    required this.serviceType,
    required this.bookingDate,
    required this.timeSlot,
    this.preferredVet = 'Any Available Vet',
    required this.notes,
    this.status = 'PENDING',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petId': petId,
      'petName': petName,
      'petSpecies': petSpecies,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'clinicPhone': clinicPhone,
      'city': city,
      'serviceType': serviceType,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'timeSlot': timeSlot,
      'preferredVet': preferredVet,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return BookingModel(
      id: docId,
      userId: map['userId'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? 'Pet',
      petSpecies: map['petSpecies'] ?? 'Dog',
      clinicId: map['clinicId'] ?? '',
      clinicName: map['clinicName'] ?? 'Veterinary Clinic',
      clinicAddress: map['clinicAddress'] ?? '',
      clinicPhone: map['clinicPhone'] ?? '',
      city: map['city'] ?? 'Penang',
      serviceType: map['serviceType'] ?? 'General Checkup',
      bookingDate: parseDate(map['bookingDate']),
      timeSlot: map['timeSlot'] ?? '10:00 AM',
      preferredVet: map['preferredVet'] ?? 'Any Available Vet',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'PENDING',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
