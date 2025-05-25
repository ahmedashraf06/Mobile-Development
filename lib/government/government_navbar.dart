import 'package:flutter/material.dart';

class GovernmentNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GovernmentNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E0E0), // Light gray line
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1877F2),
        unselectedItemColor: Color(0xFF4E4B66),
        selectedLabelStyle: const TextStyle(fontFamily: 'Poppins'),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins'),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Emergency'),
        ],
      ),
    );
  }
}
