import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GovernmentChatPage extends StatefulWidget {
  const GovernmentChatPage({super.key});

  @override
  State<GovernmentChatPage> createState() => _GovernmentChatPageState();
}

class _GovernmentChatPageState extends State<GovernmentChatPage> {
  late final String citizenUid;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    citizenUid = ModalRoute.of(context)!.settings.arguments as String;
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final unreadMessages =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(citizenUid)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where(
              'sender',
              isEqualTo: 'citizen',
            ) // ✅ citizen messages to government
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
          'sender': 'Government', // Capital G
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false, // Important for unread indicator
        });

    await FirebaseFirestore.instance.collection('chats').doc(citizenUid).set({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Chat',
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
                  _markMessagesAsRead(); // 🔥 live marking
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final isSender = msg['sender'] == 'Government';
                    final timestamp =
                        (msg['timestamp'] as Timestamp?)?.toDate();

                    // Date separator logic
                    bool showDate = false;
                    if (index == 0) {
                      showDate = true;
                    } else {
                      final prev =
                          docs[index - 1].data() as Map<String, dynamic>;
                      final prevTime =
                          (prev['timestamp'] as Timestamp?)?.toDate();
                      if (timestamp != null &&
                          prevTime != null &&
                          timestamp.day != prevTime.day) {
                        showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate && timestamp != null)
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
                                  formatDate(timestamp),
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
                            text: msg['text'] ?? '',
                            isSender: isSender,
                            timestamp: timestamp,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
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

  String formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.day}/${date.month}/${date.year}';
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
