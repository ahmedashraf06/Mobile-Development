import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/comment.dart';

class CitizenCommentsPage extends StatefulWidget {
  final DateTime timestamp;

  const CitizenCommentsPage({super.key, required this.timestamp});

  @override
  State<CitizenCommentsPage> createState() => _CitizenCommentsPageState();
}

class _CitizenCommentsPageState extends State<CitizenCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  String fullName = '';
  bool isLoadingName = true;
  bool isAnonymous = false;
  Comment? _replyTo;
  final Set<String> _expandedCommentIds = {};

  @override
  void initState() {
    super.initState();
    fetchFullName();
  }

  Future<void> fetchFullName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snapshot.data();

    if (data != null && mounted) {
      setState(() {
        fullName = data['fullName'] ?? 'User';
        isLoadingName = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || isLoadingName) return;

    // 🧠 Call moderation function before uploading
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'moderateComment',
      );
      final result = await callable.call({'text': content});
      final allowed = result.data['allowed'] as bool;

      if (!allowed) {
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text("Comment Blocked"),
                content: const Text(
                  "Your comment contains inappropriate language.",
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );

        return; // Don't post the comment
      }
    } catch (e) {
      print('Moderation error: $e');
      // Optional: allow posting if there's a network/API error
    }

    // ✅ If clean, save the comment
    final newComment = Comment(
      id: const Uuid().v4(),
      postTimestamp: widget.timestamp,
      authorName: isAnonymous ? 'Anonymous' : fullName,
      content: content,
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
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
    final diff = DateTime.now().difference(timestamp);
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
        body:
            isLoadingName
                ? const Center(child: CircularProgressIndicator())
                : Column(
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
                                .where(
                                  'postTimestamp',
                                  isLessThanOrEqualTo: upperBound,
                                )
                                .where('parentId', isNull: true)
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final comments = snapshot.data!.docs;
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text('No comments yet.'),
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children:
                                comments.map((doc) {
                                  final comment = Comment.fromMap(
                                    doc.data() as Map<String, dynamic>,
                                  );
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildCommentTile(
                                        comment,
                                        isReply: false,
                                      ),
                                      _buildReplies(doc.id),
                                    ],
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ),
                    _buildInputArea(),
                  ],
                ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, -1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: isAnonymous,
                    activeColor: const Color(0xFF667080),
                    onChanged: (value) => setState(() => isAnonymous = value),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Post anonymously',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText:
                          _replyTo != null
                              ? 'Replying to @${_replyTo!.authorName}...'
                              : isAnonymous
                              ? 'Posting anonymously...'
                              : 'Type your comment',
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
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.authorName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(comment.content, style: const TextStyle(fontFamily: 'Poppins')),
          const SizedBox(height: 2),
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
              const SizedBox(width: 8),
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
}
