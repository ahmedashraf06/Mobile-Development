import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaghnyv1/layouts/detail_screen.dart';
import 'package:balaghnyv1/citizen/citizen_comments_page.dart';



class CitizenReportDetailPage extends StatelessWidget {
  final DateTime timestamp;

  const CitizenReportDetailPage({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final lowerBound = Timestamp.fromDate(
      timestamp.subtract(const Duration(seconds: 1)),
    );
    final upperBound = Timestamp.fromDate(
      timestamp.add(const Duration(seconds: 1)),
    );

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('reports')
              .where('postedAt', isGreaterThanOrEqualTo: lowerBound)
              .where('postedAt', isLessThanOrEqualTo: upperBound)
              .limit(1)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(body: Center(child: Text('No report found.')));
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final isResolved = data['status'] == 'approved';

        return DetailLayout(
          title: data['title'] ?? 'No Title',
          description: data['details'] ?? '',
          category: data['category'] ?? '',
          timestamp: (data['postedAt'] as Timestamp).toDate(),
          imageUrl: data['attachment'],
          type: 'report',
          submittedBy: data['submittedBy'],
          locationUrl: data['locationUrl'], // 👈 pass location to DetailLayout
          onCommentsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CitizenCommentsPage(timestamp: timestamp),
              ),
            );
          },
          bottomSection: Container(
            width: double.infinity,
            height: 48,
            alignment: Alignment.center,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isResolved ? Colors.green : const Color(0xFF6E7191),
              ),
              color:
                  isResolved
                      ? const Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ).withOpacity(0.05)
                      : Colors.transparent,
            ),
            child: Text(
              isResolved ? 'Resolved' : 'Not Resolved Yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isResolved ? Colors.green : const Color(0xFF6E7191),
              ),
            ),
          ),
        );
      },
    );
  }
}
