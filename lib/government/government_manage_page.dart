import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../layouts/layout.dart';
import '../layouts/category_tabs.dart';
import '../layouts/post_card.dart';
import 'government_create_announcement_page.dart';
import 'government_create_poll_page.dart';

class GovernmentManagePage extends StatefulWidget {
  const GovernmentManagePage({super.key});

  @override
  State<GovernmentManagePage> createState() => _GovernmentManagePageState();
}

class _GovernmentManagePageState extends State<GovernmentManagePage> {
  int selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Manage',
      showTabs: true,
      actions: [
        GestureDetector(
          onTap: () {
            if (selectedCategory == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateAnnouncementPage(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePollPage()),
              );
            }
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
      tabs: CategoryTabs(
        customLabels: const ['Announcements', 'Polls'],
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
        return _buildFirestoreList('announcements', 'Announcement');
      case 1:
        return _buildFirestoreList('polls', 'Poll');
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
                  showEdit: collection == 'announcements',
                  showDelete: collection == 'announcements',
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CreateAnnouncementPage(
                              announcementId: docId,
                              initialData: data,
                            ),
                      ),
                    );
                  },

                  onDelete: () async {
                    await showCupertinoModalPopup(
                      context: context,
                      builder:
                          (_) => CupertinoActionSheet(
                            title: const Text('Delete Announcement'),
                            message: const Text(
                              'Are you sure you want to delete this announcement?',
                            ),
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance
                                      .collection('announcements')
                                      .doc(docId)
                                      .delete();
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
