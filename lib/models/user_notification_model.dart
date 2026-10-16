import 'package:cloud_firestore/cloud_firestore.dart';

/// UserNotificationModel: Data class representing a past notification sent to the user.
class UserNotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'booking', 'vaccine', 'deworming', 'health', 'system'
  final bool isRead;

  UserNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = 'system',
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'isRead': isRead,
    };
  }

  factory UserNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['timestamp'] is Timestamp) {
      parsedDate = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedDate = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UserNotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: parsedDate,
      type: map['type'] ?? 'system',
      isRead: map['isRead'] ?? false,
    );
  }
}
