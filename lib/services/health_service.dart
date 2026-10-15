import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_model.dart';

class HealthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. HEALTH ISSUES / DISEASES ---
  Stream<List<HealthIssue>> streamHealthIssues(String userId, String petId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('HEALTH_ISSUES')
        .orderBy('diagnosisDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthIssue.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addHealthIssue(String userId, String petId, HealthIssue issue) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('HEALTH_ISSUES')
        .add(issue.toMap());
  }

  Future<void> updateHealthIssue(String userId, String petId, String issueId, HealthIssue issue) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('HEALTH_ISSUES')
        .doc(issueId)
        .update(issue.toMap());
  }

  Future<void> deleteHealthIssue(String userId, String petId, String issueId) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('HEALTH_ISSUES')
        .doc(issueId)
        .delete();
  }

  // --- 2. VACCINATIONS & DEWORMS ---
  Stream<List<VaccinationRecord>> streamVaccinations(String userId, String petId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('VACCINATIONS')
        .orderBy('dateGiven', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VaccinationRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> addVaccination(String userId, String petId, VaccinationRecord record) async {
    final ref = await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('VACCINATIONS')
        .add(record.toMap());
    return ref.id;
  }

  Future<void> updateVaccination(String userId, String petId, String recordId, VaccinationRecord record) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('VACCINATIONS')
        .doc(recordId)
        .update(record.toMap());
  }

  Future<void> deleteVaccination(String userId, String petId, String recordId) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('VACCINATIONS')
        .doc(recordId)
        .delete();
  }

  // --- 3. DAILY ACTIVITY DIARY LOGS ---
  Stream<List<DailyActivityLog>> streamDailyActivityLogs(String userId, String petId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('DAILY_LOGS')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addDailyActivityLog(String userId, String petId, DailyActivityLog log) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('DAILY_LOGS')
        .add(log.toMap());
  }

  Future<void> updateDailyActivityLog(String userId, String petId, String logId, DailyActivityLog log) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('DAILY_LOGS')
        .doc(logId)
        .update(log.toMap());
  }

  Future<void> deleteDailyActivityLog(String userId, String petId, String logId) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('DAILY_LOGS')
        .doc(logId)
        .delete();
  }
}
