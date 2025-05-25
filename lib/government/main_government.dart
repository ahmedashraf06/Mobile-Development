import 'package:flutter/material.dart';
import 'government_home_page.dart';
import 'government_navbar.dart';
import 'government_manage_page.dart';
import 'government_requests_page.dart';
import 'government_messages_page.dart';
import 'government_emergency_page.dart';

class MainGovernment extends StatefulWidget {
  const MainGovernment({super.key});

  @override
  State<MainGovernment> createState() => _MainGovernmentState();
}

class _MainGovernmentState extends State<MainGovernment> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const GovernmentHomePage(),
    const GovernmentManagePage(),
    const GovernmentRequestsPage(),
    const GovernmentMessagesPage(),
    const GovernmentEmergencyPage(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: GovernmentNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}