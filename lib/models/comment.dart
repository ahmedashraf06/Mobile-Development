import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final DateTime postTimestamp;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isAnonymous;
  final String? parentId;

  Comment({
    required this.id,
    required this.postTimestamp,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isAnonymous = false,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postTimestamp': postTimestamp,      
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt,              
      'isAnonymous': isAnonymous,
      'parentId': parentId,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      postTimestamp: (map['postTimestamp'] as Timestamp).toDate(), 
      authorName: map['authorName'],
      content: map['content'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),         
      isAnonymous: map['isAnonymous'] ?? false,
      parentId: map['parentId'],
    );
  }
}
