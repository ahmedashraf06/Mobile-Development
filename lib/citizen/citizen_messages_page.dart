import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../layouts/layout.dart';

class CitizenMessagesPage extends StatelessWidget {
  const CitizenMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final citizenUid = FirebaseAuth.instance.currentUser?.uid;

    if (citizenUid == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Layout(
      title: 'Messages',
      showNotificationAndFilter: false,
      child: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .doc(citizenUid)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'No messages yet.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final lastMessage = data['lastMessage'] ?? '';
          final timestamp = (data['lastUpdated'] as Timestamp?)?.toDate();

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('chats')
                    .doc(citizenUid)
                    .collection('messages')
                    .where('isRead', isEqualTo: false)
                    .where('sender', isEqualTo: 'Government')
                    .limit(1)
                    .snapshots(),
            builder: (context, unreadSnapshot) {
              final hasUnread = unreadSnapshot.data?.docs.isNotEmpty ?? false;

              return ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  GestureDetector(
                    onTap: () async {
                      // ✅ Mark unread messages as read
                      final unread =
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(citizenUid)
                              .collection('messages')
                              .where('isRead', isEqualTo: false)
                              .where('sender', isEqualTo: 'Government')
                              .get();

                      for (var doc in unread.docs) {
                        doc.reference.update({'isRead': true});
                      }

                      Navigator.pushNamed(
                        context,
                        '/citizen/citizen_chat_page',
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            hasUnread
                                ? Border.all(
                                  color: const Color(0xFF1877F2),
                                  width: 1.5,
                                )
                                : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Government',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMessage,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatTime(timestamp),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
