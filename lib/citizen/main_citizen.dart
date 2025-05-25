import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'citizen_home.dart';
import 'citizen_emergency_page.dart';
import 'citizen_report_page.dart';
import 'citizen_messages_page.dart';
import 'citizen_profile_page.dart';
import 'citizen_navbar.dart';
import '../services/notification_service.dart';

class MainCitizen extends StatefulWidget {
  const MainCitizen({super.key});

  @override
  State<MainCitizen> createState() => _MainCitizenState();
}

class _MainCitizenState extends State<MainCitizen> {
  int _currentIndex = 0;
  String? currentRegion;
  StreamSubscription? announcementListener;

  final List<Widget> _pages = [
    const CitizenHomePage(),
    const CitizenEmergencyPage(),
    const CitizenReportPage(),
    const CitizenMessagesPage(),
    const CitizenProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _startListeningToAnnouncements(String region) {
    // Cancel previous listener if exists
    announcementListener?.cancel();

    final normalizedUserRegion =
        region.toLowerCase().replaceAll(' ', '').trim();
    print('🟡 Listening for announcements for region: $normalizedUserRegion');

    announcementListener = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('postedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isEmpty) return;

          final doc = snapshot.docs.first;
          final postedAt = (doc['postedAt'] as Timestamp).toDate();
          final now = DateTime.now();
          final diff = now.difference(postedAt);

          final docRegionRaw = doc['region']?.toString() ?? '';
          final normalizedDocRegion =
              docRegionRaw.toLowerCase().replaceAll(' ', '').trim();

          print('📣 Announcement detected!');
          print('👤 userRegion: "$region" → "$normalizedUserRegion"');
          print('📢 docRegion : "$docRegionRaw" → "$normalizedDocRegion"');
          print('⏱️ diff: ${diff.inSeconds}s');

          if (normalizedDocRegion == normalizedUserRegion &&
              diff.inSeconds < 5) {
            print('✅ Region matched. Sending notification!');
            NotificationService().showNotification(
              title: 'New Announcement',
              body: doc['title'] ?? 'Tap to view the announcement',
              payloadTimestamp: postedAt,
            );
          } else {
            print('❌ Not sent — region mismatch or outdated post');
          }
        });
  }

  @override
  void dispose() {
    announcementListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('User not logged in.')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final liveRegion = userData?['region']?.toString().trim();

        if (liveRegion == null || liveRegion.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No region found for this user.')),
          );
        }

        // If region changed, restart listener
        if (liveRegion != currentRegion) {
          print('🔁 Region updated: "$currentRegion" → "$liveRegion"');
          currentRegion = liveRegion;
          _startListeningToAnnouncements(currentRegion!);
        }

        return Scaffold(
          body: SafeArea(child: _pages[_currentIndex]),
          bottomNavigationBar: CitizenNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        );
      },
    );
  }
}
