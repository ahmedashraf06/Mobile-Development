import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../layouts/layout.dart';

class GovernmentMessagesPage extends StatelessWidget {
  const GovernmentMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Messages',
      showNotificationAndFilter: false,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .orderBy('lastUpdated', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No messages yet.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['senderName'] ?? 'Unknown';
              final String lastMessage = data['lastMessage'] ?? '';
              final DateTime? lastTime =
                  (data['lastUpdated'] as Timestamp?)?.toDate();
              final uid = docs[index].id;

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('chats')
                        .doc(uid)
                        .collection('messages')
                        .where('isRead', isEqualTo: false)
                        .where('sender', isEqualTo: 'citizen')
                        .limit(1)
                        .snapshots(),
                builder: (context, unreadSnapshot) {
                  final hasUnread =
                      unreadSnapshot.data?.docs.isNotEmpty ?? false;

                  return GestureDetector(
                    onTap: () async {
                      final unread =
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(uid)
                              .collection('messages')
                              .where('isRead', isEqualTo: false)
                              .where('sender', isEqualTo: 'citizen')
                              .get();

                      for (var doc in unread.docs) {
                        doc.reference.update({'isRead': true});
                      }

                      Navigator.pushNamed(
                        context,
                        '/government/chat',
                        arguments: uid,
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
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
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
                                if (lastTime != null)
                                  Text(
                                    formatTime(lastTime),
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
                  );
                },
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
