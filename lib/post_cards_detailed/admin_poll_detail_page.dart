import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaghnyv1/layouts/detail_screen.dart';
import 'package:balaghnyv1/government/government_comments_page.dart';
import 'package:balaghnyv1/post_cards_detailed/admin_view_voters_page.dart';

class AdminPollDetailPage extends StatelessWidget {
  final DateTime timestamp;

  const AdminPollDetailPage({super.key, required this.timestamp});

  Future<Map<String, dynamic>?> _fetchData() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('polls')
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
          return const Scaffold(body: Center(child: Text('Poll not found')));
        }

        return DetailLayout(
          title: data['title'],
          description: data['details'],
          category: data['category'],
          timestamp: (data['postedAt'] as Timestamp).toDate(),
          imageUrl: data['attachment'],
          type: 'poll',
          onCommentsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GovernmentCommentsPage(timestamp: timestamp),
              ),
            );
          },
          bottomSection: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, color: Color(0xFFE0E0E0)), // Gray line
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewVotersPage(timestamp: timestamp),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2), // Bright blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Rounded corners
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Voters',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
