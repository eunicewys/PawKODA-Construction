import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. HEALTH ISSUE / DISEASE MODEL ---
class HealthIssue {
  final String id;
  final String petId;
  final String title;
  final DateTime diagnosisDate;
  final String severity; // Mild, Moderate, Severe
  final String status; // Active, Recovered, Ongoing
  final String notes;
  final DateTime? createdAt;

  HealthIssue({
    required this.id,
    required this.petId,
    required this.title,
    required this.diagnosisDate,
    required this.severity,
    required this.status,
    required this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'title': title,
      'diagnosisDate': Timestamp.fromDate(diagnosisDate),
      'severity': severity,
      'status': status,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory HealthIssue.fromMap(Map<String, dynamic> map, String docId) {
    return HealthIssue(
      id: docId,
      petId: map['petId'] ?? '',
      title: map['title'] ?? '',
      diagnosisDate: (map['diagnosisDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      severity: map['severity'] ?? 'Mild',
      status: map['status'] ?? 'Active',
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// --- 2. VACCINATION & DEWORMS MODEL ---
class VaccinationRecord {
  final String id;
  final String petId;
  final String type; // vaccine, deworming
  final String doseName;
  final DateTime dateGiven;
  final String vetName;
  final String dosage;
  final DateTime? dueDate; // next due date
  final bool isCompleted;
  final String notes;
  final String? reminderTime;

  VaccinationRecord({
    required this.id,
    required this.petId,
    required this.type,
    required this.doseName,
    required this.dateGiven,
    required this.vetName,
    required this.dosage,
    this.dueDate,
    required this.isCompleted,
    required this.notes,
    this.reminderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'type': type,
      'doseName': doseName,
      'dateGiven': Timestamp.fromDate(dateGiven),
      'vetName': vetName,
      'dosage': dosage,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'notes': notes,
      'reminderTime': reminderTime,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory VaccinationRecord.fromMap(Map<String, dynamic> map, String docId) {
    return VaccinationRecord(
      id: docId,
      petId: map['petId'] ?? '',
      type: map['type'] ?? 'Vaccine',
      doseName: map['doseName'] ?? '',
      dateGiven: (map['dateGiven'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vetName: map['vetName'] ?? '',
      dosage: map['dosage'] ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: map['isCompleted'] ?? true,
      notes: map['notes'] ?? '',
      reminderTime: map['reminderTime'],
    );
  }
}

// --- 3. DAILY ACTIVITY DIARY MODEL ---
class DailyActivityLog {
  final String id;
  final String petId;
  final DateTime date;
  final String appetite; // Good, Normal, Poor
  final String stool; // Normal, Soft, Hard, None
  final String waterIntake; // Good, Normal, Low
  final String activityLevel; // Active, Normal, Lethargic
  final bool wentForWalk;
  final String notes;

  DailyActivityLog({
    required this.id,
    required this.petId,
    required this.date,
    required this.appetite,
    required this.stool,
    required this.waterIntake,
    required this.activityLevel,
    required this.wentForWalk,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'date': Timestamp.fromDate(date),
      'appetite': appetite,
      'stool': stool,
      'waterIntake': waterIntake,
      'activityLevel': activityLevel,
      'wentForWalk': wentForWalk,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory DailyActivityLog.fromMap(Map<String, dynamic> map, String docId) {
    return DailyActivityLog(
      id: docId,
      petId: map['petId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appetite: map['appetite'] ?? 'Normal',
      stool: map['stool'] ?? 'Normal',
      waterIntake: map['waterIntake'] ?? 'Normal',
      activityLevel: map['activityLevel'] ?? 'Normal',
      wentForWalk: map['wentForWalk'] ?? false,
      notes: map['notes'] ?? '',
    );
  }
}
