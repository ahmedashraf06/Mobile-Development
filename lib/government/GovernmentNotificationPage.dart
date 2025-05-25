import 'package:balaghnyv1/models/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class GovernmentNotificationPage extends StatelessWidget {
  const GovernmentNotificationPage({super.key});

  Stream<List<InAppNotification>> _fetchAdminNotifications() {
    return FirebaseFirestore.instance
        .collection('adminNotifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InAppNotification.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email != 'admin@balaghny.online') {
      return const Scaffold(body: Center(child: Text("Access denied")));
    }

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<InAppNotification>>(
        stream: _fetchAdminNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          final today =
              notifications
                  .where(
                    (n) =>
                        n.createdAt.year == now.year &&
                        n.createdAt.month == now.month &&
                        n.createdAt.day == now.day,
                  )
                  .toList();

          final yesterday =
              notifications
                  .where(
                    (n) =>
                        n.createdAt.year == now.year &&
                        n.createdAt.month == now.month &&
                        n.createdAt.day == now.day - 1,
                  )
                  .toList();

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (today.isNotEmpty) ...[
                Text(
                  "Today, ${DateFormat.MMMM().format(now)} ${now.day}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...today.map((n) => NotificationTile(notification: n)).toList(),
              ],
              if (yesterday.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  "Yesterday, ${DateFormat.MMMM().format(now)} ${now.day - 1}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...yesterday
                    .map((n) => NotificationTile(notification: n))
                    .toList(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final InAppNotification notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            timeago.format(notification.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
