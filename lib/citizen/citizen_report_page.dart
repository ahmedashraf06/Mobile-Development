import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/layouts/layout.dart';
import '/layouts/post_card.dart';
import 'citizen_create_report_page.dart';

class CitizenReportPage extends StatelessWidget {
  const CitizenReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('You must be logged in')));
    }

    final userEmail = currentUser.email;

    return Layout(
      title: 'Report',
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateReportPage()),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_circle_outline,
                size: 28,
                color: Colors.black,
                weight: 700,
              ),
            ),
          ),
        ),
      ],
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('reports')
                .where(
                  'submittedBy',
                  isEqualTo: userEmail,
                ) 
                .orderBy('postedAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reports submitted yet'));
          }

          final reports = snapshot.data!.docs;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data() as Map<String, dynamic>;
              return PostCard(
                title: data['title'] ?? '',
                description: data['details'] ?? '',
                type: 'Report',
                category: data['category'] ?? '',
                imageUrl: data['attachment'],
                timestamp:
                    (data['postedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            },
          );
        },
      ),
    );
  }
}
