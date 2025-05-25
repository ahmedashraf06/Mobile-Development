import 'package:balaghnyv1/layouts/map_preview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailLayout extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final DateTime timestamp;
  final String? imageUrl;
  final String type; // 'poll', 'announcement', 'ad', 'report'
  final String? submittedBy; // only for reports
  final VoidCallback onCommentsTap;
  final Widget bottomSection;
  final Widget? extraSection;
  final String? locationUrl;

  const DetailLayout({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    required this.bottomSection,
    required this.onCommentsTap,
    required this.type,
    this.submittedBy,
    this.imageUrl,
    this.extraSection,
    this.locationUrl,
  });

  @override
  State<DetailLayout> createState() => _DetailLayoutState();
}

class _DetailLayoutState extends State<DetailLayout> {
  String displayName = 'Government';

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    if (widget.type == 'report' && widget.submittedBy != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.submittedBy)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        setState(() {
          displayName = userData['fullName'] ?? 'Citizen';
        });
      } else {
        setState(() {
          displayName = 'Citizen';
        });
      }
    } else if (widget.type == 'ad') {
      setState(() => displayName = 'Advertisement');
    } else {
      setState(() => displayName = 'Government');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTimeAgo = _getTimeAgo(widget.timestamp);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      formattedTimeAgo,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF98A2B3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onCommentsTap,
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF4E4B66),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) {
                    return GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(widget.imageUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Couldn't open file")),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFE0E0E0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.insert_drive_file,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Tap to open file',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            Text(
              widget.category,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF344054),
              ),
            ),

            if ((widget.type == 'report' || widget.type == 'ad') &&
                widget.locationUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: MapPreview(locationUrl: widget.locationUrl!),
              ),

            if (widget.type == 'poll' && widget.extraSection != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: widget.extraSection!,
              ),
          ],
        ),
      ),
      bottomNavigationBar: widget.bottomSection,
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM yyyy').format(time);
  }
}
