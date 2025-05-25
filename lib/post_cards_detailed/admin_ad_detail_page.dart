import 'package:balaghnyv1/government/government_comments_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaghnyv1/layouts/detail_screen.dart';



class AdminAdDetailPage extends StatefulWidget {
  final DateTime timestamp;

  const AdminAdDetailPage({super.key, required this.timestamp});

  @override
  State<AdminAdDetailPage> createState() => _AdminAdDetailPageState();
}

class _AdminAdDetailPageState extends State<AdminAdDetailPage> {
  Map<String, dynamic>? adData;
  String? adDocId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdByTimestamp();
  }

  Future<void> fetchAdByTimestamp() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('ads')
            .where('postedAt', isEqualTo: Timestamp.fromDate(widget.timestamp))
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        adData = snapshot.docs.first.data();
        adDocId = snapshot.docs.first.id;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateAdStatus(String status) async {
    if (adDocId == null) return;
    await FirebaseFirestore.instance.collection('ads').doc(adDocId!).update({
      'status': status,
    });
    fetchAdByTimestamp(); // refresh
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (adData == null) {
      return const Scaffold(body: Center(child: Text('Ad not found')));
    }

    final title = adData!['title'] ?? '';
    final details = adData!['details'] ?? '';
    final imageUrl = adData!['attachment'];
    final status = adData!['status'] ?? 'pending';
    final postedAt = (adData!['postedAt'] as Timestamp).toDate();

    return DetailLayout(
      title: title,
      description: details,
      category: adData!['category'] ?? '',
      timestamp: postedAt,
      imageUrl: imageUrl,
      type: 'ad',
      locationUrl: adData!['locationUrl'],
      onCommentsTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GovernmentCommentsPage(timestamp: widget.timestamp),
          ),
        );
      },
      bottomSection: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE0E0E0), // Light gray separator line
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child:
            status == 'pending'
                ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateAdStatus('approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BA88),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateAdStatus('rejected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC30052),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA0A3BD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      status == 'approved' ? 'Accepted' : 'Rejected',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
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
