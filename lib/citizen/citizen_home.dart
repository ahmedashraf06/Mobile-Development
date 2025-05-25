import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../layouts/layout.dart';
import '../layouts/category_tabs.dart';
import '../layouts/post_card.dart';
import '../layouts/filter_sheet.dart';
import 'citizen_notification_page.dart';


class CitizenHomePage extends StatefulWidget {
  const CitizenHomePage({super.key});

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage> {
  int selectedCategory = 0;
  FilterData? appliedFilter;
  String? currentUserRegion;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserRegion();
  }

  Future<void> fetchCurrentUserRegion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists && userDoc.data()?['region'] != null) {
      final rawRegion = userDoc['region']; // e.g. "First Settlement"
      final normalized = rawRegion
          .toString()
          .replaceAll(' ', '') // Remove spaces
          .replaceFirstMapped(
            // Lowercase first letter
            RegExp(r'^[A-Z]'),
            (m) => m.group(0)!.toLowerCase(),
          );

      setState(() {
        currentUserRegion = normalized; // becomes "firstSettlement"
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserRegion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Layout(
      title: 'Home',
      showTabs: true,
      showNotificationAndFilter: true,
      onNotificationTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CitizenNotificationPage()),
        );
      },
      onFilter: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isScrollControlled: true,
          builder:
              (_) => FilterSheet(
                onApply: (filterData) {
                  setState(() {
                    appliedFilter = filterData;
                  });
                },
                initialFilter: appliedFilter,
              ),
        );
      },
      tabs: CategoryTabs(
        customLabels: const ['All', 'Announcements', 'Polls', 'Ads', 'Reports'],
        selectedIndex: selectedCategory,
        onSelect: (index) => setState(() => selectedCategory = index),
        underlineFullWord: true,
      ),
      child: _buildSelectedCategoryView(),
    );
  }

  Widget _buildSelectedCategoryView() {
    switch (selectedCategory) {
      case 1:
        return _buildFilteredFirestoreList('announcements', 'Announcement');
      case 2:
        return _buildFilteredFirestoreList('polls', 'Poll');
      case 3:
        return _buildFilteredFirestoreList('ads', 'Ad');
      case 4:
        return _buildFilteredFirestoreList('reports', 'Report');
      case 0:
      default:
        return _buildCombinedList();
    }
  }

  Widget _buildFilteredFirestoreList(String collection, String typeLabel) {
    Query query = FirebaseFirestore.instance
        .collection(collection)
        .where('region', isEqualTo: currentUserRegion);

    if (collection == 'ads') {
      query = query.where('status', isEqualTo: 'approved');
    }

    query = query.orderBy('postedAt', descending: true);

    if (appliedFilter?.category != null) {
      query = query.where('category', isEqualTo: appliedFilter!.category);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        final posts =
            snapshot.data!.docs.where((doc) {
              final postedAt = (doc['postedAt'] as Timestamp).toDate();
              final from = appliedFilter?.from;
              final to = appliedFilter?.to;
              if (from != null && postedAt.isBefore(from)) return false;
              if (to != null && postedAt.isAfter(to)) return false;
              return true;
            }).toList();

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
            return PostCard(
              title: data['title'] ?? '',
              description: data['details'] ?? '',
              type: typeLabel,
              category: data['category'] ?? '',
              imageUrl: data['attachment'],
              timestamp: (data['postedAt'] as Timestamp).toDate(),
            );
          },
        );
      },
    );
  }

Widget _buildCombinedList() {
  final collections = [
    {'name': 'announcements', 'type': 'Announcement'},
    {'name': 'polls', 'type': 'Poll'},
    {'name': 'ads', 'type': 'Ad'},
    {'name': 'reports', 'type': 'Report'},
  ];

  List<Stream<List<Map<String, dynamic>>>> streams = collections.map((c) {
    Query query = FirebaseFirestore.instance
        .collection(c['name']!)
        .where('region', isEqualTo: currentUserRegion);

    if (c['name'] == 'ads') {
      query = query.where('status', isEqualTo: 'approved');
    }

    query = query.orderBy('postedAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final postedAt = (data['postedAt'] as Timestamp).toDate();
        final from = appliedFilter?.from;
        final to = appliedFilter?.to;
        final categoryMatch =
            appliedFilter?.category == null ||
            data['category'] == appliedFilter!.category;

        if ((from == null || !postedAt.isBefore(from)) &&
            (to == null || !postedAt.isAfter(to)) &&
            categoryMatch) {
          return {'data': data, 'type': c['type']};
        } else {
          return null;
        }
      }).whereType<Map<String, dynamic>>().toList();
    });
  }).toList();

  return StreamBuilder<List<List<Map<String, dynamic>>>>(
    stream: CombineLatestStream.list(streams),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.expand((e) => e).isEmpty) {
        return const Center(child: Text('No posts yet'));
      }

      final allDocs = snapshot.data!.expand((e) => e).toList();
      allDocs.sort((a, b) {
        final aTimestamp = a['data']['postedAt'];
        final bTimestamp = b['data']['postedAt'];
        return (bTimestamp as Timestamp).toDate().compareTo(
          (aTimestamp as Timestamp).toDate(),
        );
      });

      return ListView.builder(
        itemCount: allDocs.length,
        itemBuilder: (context, index) {
          final post = allDocs[index];
          final data = post['data'] as Map<String, dynamic>;
          return PostCard(
            title: data['title'] ?? '',
            description: data['details'] ?? '',
            type: post['type'],
            category: data['category'] ?? '',
            imageUrl: data['attachment'],
            timestamp:
                (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        },
      );
    },
  );
}

}
