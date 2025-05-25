import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaghnyv1/layouts/detail_screen.dart';
import 'package:balaghnyv1/government/government_comments_page.dart';
import 'package:balaghnyv1/layouts/map_preview.dart';

class AdminReportDetailPage extends StatefulWidget {
  final DateTime timestamp;

  const AdminReportDetailPage({super.key, required this.timestamp});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  bool isResolved = false;
  bool isLoading = true;
  Map<String, dynamic>? reportData;
  String? docId;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    final lower = Timestamp.fromDate(
      widget.timestamp.subtract(const Duration(seconds: 1)),
    );
    final upper = Timestamp.fromDate(
      widget.timestamp.add(const Duration(seconds: 1)),
    );

    final snapshot =
        await FirebaseFirestore.instance
            .collection('reports')
            .where('postedAt', isGreaterThanOrEqualTo: lower)
            .where('postedAt', isLessThanOrEqualTo: upper)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();

      setState(() {
        reportData = data;
        isResolved = data['status'] == 'approved';
        docId = doc.id;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsResolved() async {
    if (docId == null) return;

    await FirebaseFirestore.instance.collection('reports').doc(docId!).update({
      'status': 'approved',
    });

    setState(() => isResolved = true);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (reportData == null) {
      return const Scaffold(body: Center(child: Text('No report found.')));
    }

    return DetailLayout(
      title: reportData!['title'] ?? 'No Title',
      description: reportData!['details'] ?? 'No details provided.',
      category: reportData!['category'] ?? '',
      timestamp: (reportData!['postedAt'] as Timestamp).toDate(),
      imageUrl: reportData!['attachment'],
      type: 'report',
      submittedBy: reportData!['submittedBy'],
      locationUrl: reportData!['locationUrl'],
      onCommentsTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GovernmentCommentsPage(timestamp: widget.timestamp),
          ),
        );
      },
      extraSection:
          reportData!['locationUrl'] != null &&
                  reportData!['locationUrl'].toString().isNotEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: MapPreview(locationUrl: reportData!['locationUrl']),
              )
              : null,
      bottomSection: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isResolved ? null : _markAsResolved,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isResolved
                      ? const Color(0xFFA0A3BD)
                      : const Color(0xFF00BA88),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isResolved ? 'Resolved' : 'Mark as Resolved',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
