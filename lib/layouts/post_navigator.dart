import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../post_cards_detailed/admin_announcement_detail_page.dart';
import '../post_cards_detailed/admin_poll_detail_page.dart';
import '../post_cards_detailed/admin_ad_detail_page.dart';
import '../post_cards_detailed/admin_report_detail_page.dart';
import '../post_cards_detailed/citizen_announcement_detail_page.dart';
import '../post_cards_detailed/citizen_poll_detail_page.dart';
import '../post_cards_detailed/citizen_ad_detail_page.dart';
import '../post_cards_detailed/citizen_report_detail_page.dart';

void navigateToPostDetail(BuildContext context, String type, DateTime timestamp) {
  final email = FirebaseAuth.instance.currentUser?.email ?? '';
  final isAdmin = email.endsWith('@balaghny.online'); // adjust as needed

  Widget? page;

  switch (type.toLowerCase()) {
    case 'announcement':
      page = isAdmin
          ? AdminAnnouncementDetailPage(timestamp: timestamp)
          : CitizenAnnouncementDetailPage(timestamp: timestamp);
      break;
    case 'poll':
      page = isAdmin
          ? AdminPollDetailPage(timestamp: timestamp)
          : CitizenPollDetailPage(timestamp: timestamp);
      break;
    case 'ad':
      page = isAdmin
          ? AdminAdDetailPage(timestamp: timestamp)
          : CitizenAdDetailPage(timestamp: timestamp);
      break;
    case 'report':
      page = isAdmin
          ? AdminReportDetailPage(timestamp: timestamp)
          : CitizenReportDetailPage(timestamp: timestamp);
      break;
  }

  if (page != null) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    }
}
