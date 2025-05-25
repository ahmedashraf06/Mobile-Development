import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenChatPage extends StatefulWidget {
  const CitizenChatPage({super.key});

  @override
  State<CitizenChatPage> createState() => _CitizenChatPageState();
}

class _CitizenChatPageState extends State<CitizenChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String citizenUid;
  String senderName = 'Citizen';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      citizenUid = user.uid;
      fetchProfileName();

      // Mark messages as read on open
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markMessagesAsRead();
      });
    } else {
      citizenUid = 'unknown';
    }
  }

  Future<void> fetchProfileName() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(citizenUid)
            .get();
    final data = doc.data();
    if (data != null && data['fullName'] != null) {
      setState(() {
        senderName = data['fullName'];
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final unreadMessages =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(citizenUid)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where('sender', isEqualTo: 'Government') // ✅ Correct sender
            .get();

    for (final doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(citizenUid)
        .collection('messages')
        .add({
          'text': text,
          'sender': 'citizen',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

    await FirebaseFirestore.instance.collection('chats').doc(citizenUid).set({
      'senderName': senderName,
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _controller.clear();
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Government',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(citizenUid)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isNotEmpty) {
                  _markMessagesAsRead(); // ✅ live update
                }
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final current = docs[index].data() as Map<String, dynamic>;
                    final currentTimestamp =
                        (current['timestamp'] as Timestamp?)?.toDate();
                    final isSender = current['sender'] == 'citizen';

                    bool showDateLabel = false;
                    if (index == 0) {
                      showDateLabel = true;
                    } else {
                      final previous =
                          docs[index - 1].data() as Map<String, dynamic>;
                      final prevTimestamp =
                          (previous['timestamp'] as Timestamp?)?.toDate();
                      if (prevTimestamp != null &&
                          currentTimestamp != null &&
                          prevTimestamp.day != currentTimestamp.day) {
                        showDateLabel = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateLabel && currentTimestamp != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  formatDate(currentTimestamp),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Align(
                          alignment:
                              isSender
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: ChatBubble(
                            text: current['text'] ?? '',
                            isSender: isSender,
                            timestamp: currentTimestamp,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: const Color(0xFFF0F2F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1877F2)),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;
  final DateTime? timestamp;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isSender,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeText =
        timestamp != null
            ? TimeOfDay.fromDateTime(timestamp!).format(context)
            : '';

    return Column(
      crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: isSender ? const Color(0xFF1877F2) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isSender ? const Radius.circular(16) : Radius.zero,
              bottomRight: isSender ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isSender ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            timeText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
