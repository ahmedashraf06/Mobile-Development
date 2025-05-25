import 'package:cloud_firestore/cloud_firestore.dart';

class InAppNotification {
  final String id;
  final String title;
  final String body;
  final String? type;         // "report", "announcement", etc. (optional for admin use later)
  final DateTime createdAt;
  final bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.type,
  });

  factory InAppNotification.fromMap(String id, Map<String, dynamic> data) {
    return InAppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'], // nullable
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
