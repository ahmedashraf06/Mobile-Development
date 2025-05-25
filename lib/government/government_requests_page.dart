import 'package:balaghnyv1/layouts/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../layouts/layout.dart';
import '../layouts/category_tabs.dart';

class GovernmentRequestsPage extends StatefulWidget {
  const GovernmentRequestsPage({super.key});

  @override
  State<GovernmentRequestsPage> createState() => _GovernmentRequestsPageState();
}

class _GovernmentRequestsPageState extends State<GovernmentRequestsPage> {
  int selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Requests',
      showTabs: true,
      tabs: CategoryTabs(
        customLabels: const ['Advertisements', 'Reports'],
        selectedIndex: selectedCategory,
        onSelect: (index) => setState(() => selectedCategory = index),
        underlineFullWord: true,
        tabSpacing: 100,
      ),
      child: _buildSelectedCategoryView(),
    );
  }

  Widget _buildSelectedCategoryView() {
    switch (selectedCategory) {
      case 0:
        return _buildFirestoreList('ads', 'Ad');
      case 1:
        return _buildFirestoreList('reports', 'Report');
      default:
        return const Center(child: Text('Unknown category'));
    }
  }

  Widget _buildFirestoreList(String collection, String typeLabel) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(collection)
              .orderBy('postedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final docId = post.id;

            final bool isAd = collection == 'ads';
            final bool isApprovedAd = isAd && data['status'] == 'approved';

            return Column(
              children: [
                PostCard(
                  title: data['title'] ?? '',
                  description: data['details'] ?? '',
                  type: typeLabel,
                  category: data['category'] ?? '',
                  imageUrl: data['attachment'],
                  timestamp:
                      (data['postedAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),

                  showEdit: false,
                  showDelete: isApprovedAd, // ✅ only if ad is approved

                  onDelete: () async {
                    await showCupertinoModalPopup(
                      context: context,
                      builder:
                          (_) => CupertinoActionSheet(
                            title: const Text('Delete Ad'),
                            message: const Text(
                              'Are you sure you want to delete this ad?',
                            ),
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () async {
                                  Navigator.pop(context); // Close the sheet

                                  // First delete from Firestore
                                  await FirebaseFirestore.instance
                                      .collection('ads')
                                      .doc(docId)
                                      .delete();

                                  // Then send deletion email
                                  final callable = FirebaseFunctions.instance
                                      .httpsCallable('sendAdDeletedEmail');
                                  await callable.call({
                                    'email': data['contactEmail'],
                                    'title': data['title'],
                                  });
                                },
                                isDestructiveAction: true,
                                child: const Text('Delete'),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                    );
                  },
                ),
                const Divider(height: 16, thickness: 0.5),
              ],
            );
          },
        );
      },
    );
  }
}
