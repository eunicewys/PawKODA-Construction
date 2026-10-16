import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_notification_model.dart';

/// UserNotificationService: Manages notification history logs and preferences in Firestore.
/// Enforces the 30-day retention rule and handles filtering for 7, 14, 21, and 30 days.
class UserNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Log a past notification to USERS/{userId}/NOTIFICATIONS
  Future<void> logNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
  }) async {
    if (userId.isEmpty) return;

    try {
      // Check if user has notifications enabled
      final isEnabled = await getNotificationSettings(userId);
      if (!isEnabled) {
        debugPrint("Notifications disabled for user $userId. Skipping notification log.");
        return;
      }

      final notification = UserNotificationModel(
        id: '',
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
        isRead: false,
      );

      await _db
          .collection('USERS')
          .doc(userId)
          .collection('NOTIFICATIONS')
          .add(notification.toMap());

      debugPrint("Logged notification for user $userId: $title");

      // Auto trigger cleanup of old notifications (>30 days)
      await cleanupOldNotifications(userId);
    } catch (e) {
      debugPrint("Error logging notification: $e");
    }
  }

  /// Stream notifications filtered by past days (7, 14, 21, or 30 days)
  Stream<List<UserNotificationModel>> streamNotifications(String userId, {int pastDays = 30}) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: pastDays));

    return _db
        .collection('USERS')
        .doc(userId)
        .collection('NOTIFICATIONS')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserNotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Automatically remove notifications older than 30 days
  Future<void> cleanupOldNotifications(String userId) async {
    if (userId.isEmpty) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _db
          .collection('USERS')
          .doc(userId)
          .collection('NOTIFICATIONS')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("Purged ${snapshot.docs.length} notifications older than 30 days for user $userId.");
      }
    } catch (e) {
      debugPrint("Error cleaning up old notifications: $e");
    }
  }

  /// Get user notification preference (ON/OFF switch state)
  Future<bool> getNotificationSettings(String userId) async {
    if (userId.isEmpty) return true;

    try {
      final doc = await _db.collection('USERS').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['notificationsEnabled'] ?? true;
      }
    } catch (e) {
      debugPrint("Error fetching notification settings: $e");
    }
    return true;
  }

  /// Toggle user notification settings (ON/OFF switch)
  Future<void> setNotificationSettings(String userId, bool enabled) async {
    if (userId.isEmpty) return;

    try {
      await _db.collection('USERS').doc(userId).set({
        'notificationsEnabled': enabled,
      }, SetOptions(merge: true));
      debugPrint("Set notification preference for $userId: $enabled");
    } catch (e) {
      debugPrint("Error updating notification settings: $e");
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;

    try {
      final snapshot = await _db
          .collection('USERS')
          .doc(userId)
          .collection('NOTIFICATIONS')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  /// Clear all notification history for user
  Future<void> clearAllNotifications(String userId) async {
    if (userId.isEmpty) return;

    try {
      final snapshot = await _db
          .collection('USERS')
          .doc(userId)
          .collection('NOTIFICATIONS')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error clearing notifications: $e");
    }
  }
}
