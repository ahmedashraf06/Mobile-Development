import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/comment.dart';

class GovernmentCommentsPage extends StatefulWidget {
  final DateTime timestamp;

  const GovernmentCommentsPage({super.key, required this.timestamp});

  @override
  State<GovernmentCommentsPage> createState() => _GovernmentCommentsPageState();
}

class _GovernmentCommentsPageState extends State<GovernmentCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  Comment? _replyTo;
  final Set<String> _expandedCommentIds = {};

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final newComment = Comment(
      id: const Uuid().v4(),
      postTimestamp: widget.timestamp,
      authorName: 'Government',
      content: content,
      createdAt: DateTime.now(),
      isAnonymous: false,
      parentId: _replyTo?.id,
    );

    final commentDocRef = FirebaseFirestore.instance.collection('comments');

    if (_replyTo == null) {
      await commentDocRef.doc(newComment.id).set(newComment.toMap());
    } else {
      final topParentId = _replyTo!.parentId ?? _replyTo!.id;
      await commentDocRef
          .doc(topParentId)
          .collection('replies')
          .doc(newComment.id)
          .set(newComment.toMap());
    }

    setState(() {
      _commentController.clear();
      _replyTo = null;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d, y').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final lowerBound = Timestamp.fromDate(
      widget.timestamp.subtract(const Duration(seconds: 1)),
    );
    final upperBound = Timestamp.fromDate(
      widget.timestamp.add(const Duration(seconds: 1)),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Comments',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('comments')
                        .where(
                          'postTimestamp',
                          isGreaterThanOrEqualTo: lowerBound,
                        )
                        .where('postTimestamp', isLessThanOrEqualTo: upperBound)
                        .where('parentId', isNull: true)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('🔥 FIRESTORE ERROR: ${snapshot.error}');
                    return const Text('Firestore error occurred');
                  }
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final comments = snapshot.data!.docs;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        comments.map((doc) {
                          final comment = Comment.fromMap(
                            doc.data() as Map<String, dynamic>,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCommentTile(comment, isReply: false),
                              _buildReplies(doc.id),
                            ],
                          );
                        }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplies(String parentCommentId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('comments')
              .doc(parentCommentId)
              .collection('replies')
              .orderBy('createdAt')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final replies =
            snapshot.data!.docs
                .map(
                  (doc) => Comment.fromMap(doc.data() as Map<String, dynamic>),
                )
                .toList();
        if (replies.isEmpty) return const SizedBox.shrink();

        final isExpanded = _expandedCommentIds.contains(parentCommentId);
        final visibleReplies = isExpanded ? replies : [replies.first];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visibleReplies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: _buildCommentTile(reply, isReply: true),
              ),
            ),
            if (replies.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded
                          ? _expandedCommentIds.remove(parentCommentId)
                          : _expandedCommentIds.add(parentCommentId);
                    });
                  },
                  child: Text(
                    isExpanded
                        ? 'Hide replies'
                        : 'See more (${replies.length - 1})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4E4B66),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentTile(Comment comment, {required bool isReply}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20, left: isReply ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.authorName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(comment.content, style: const TextStyle(fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatTimestamp(comment.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4E4B66),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _replyTo = comment;
                    _commentController.text = '@${comment.authorName} ';
                  });
                },
                child: Row(
                  children: const [
                    Icon(CupertinoIcons.reply, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'reply',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4E4B66),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText:
                    _replyTo != null
                        ? 'Replying to @${_replyTo!.authorName}...'
                        : 'Type your comment...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontFamily: 'Poppins',
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCED0D4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
