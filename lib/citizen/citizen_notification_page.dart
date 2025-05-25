import 'package:balaghnyv1/models/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class CitizenNotificationPage extends StatelessWidget {
  const CitizenNotificationPage({super.key});

  Stream<List<InAppNotification>> _notificationStream(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Not signed in"));
    }

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
        stream: _notificationStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final now = DateTime.now();
          final today =
              snapshot.data!
                  .where(
                    (n) =>
                        n.createdAt.year == now.year &&
                        n.createdAt.month == now.month &&
                        n.createdAt.day == now.day,
                  )
                  .toList();

          final yesterday =
              snapshot.data!
                  .where(
                    (n) =>
                        n.createdAt.year == now.year &&
                        n.createdAt.month == now.month &&
                        n.createdAt.day == now.day - 1,
                  )
                  .toList();

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
