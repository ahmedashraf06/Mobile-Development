import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaghnyv1/layouts/detail_screen.dart';
import 'package:balaghnyv1/citizen/citizen_comments_page.dart';


class CitizenAnnouncementDetailPage extends StatelessWidget {
  final DateTime timestamp;

  const CitizenAnnouncementDetailPage({super.key, required this.timestamp});

  Future<Map<String, dynamic>?> _fetchData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .where('postedAt', isEqualTo: Timestamp.fromDate(timestamp))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Announcement not found')),
          );
        }

        return DetailLayout(
          title: data['title'],
          description: data['details'],
          category: data['category'],
          timestamp: data['postedAt'].toDate(),
          imageUrl: data['attachment'],
          type: 'announcement',
          onCommentsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CitizenCommentsPage(
                  timestamp: timestamp,
                ),
              ),
            );
          },
          bottomSection: const SizedBox(height: 0), // Replace with buttons if needed
        );
      },
    );
  }
}
