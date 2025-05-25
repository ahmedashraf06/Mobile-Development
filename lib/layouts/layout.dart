import 'package:flutter/material.dart';

class Layout extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showTabs;
  final Widget? tabs;
  final bool showNotificationAndFilter;
  final bool showAddButton;
  final VoidCallback? onAdd;
  final List<Widget>? actions;
  final VoidCallback? onFilter;
  final VoidCallback? onNotificationTap; // 👈 NEW

  const Layout({
    super.key,
    required this.title,
    required this.child,
    this.showTabs = false,
    this.tabs,
    this.showNotificationAndFilter = false,
    this.showAddButton = false,
    this.onAdd,
    this.actions,
    this.onFilter,
    this.onNotificationTap, // 👈 NEW
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> trailingWidgets =
        actions ??
        [
          if (showNotificationAndFilter)
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed:
                  onNotificationTap ??
                  () {
                    // Default fallback: do nothing
                  },
              tooltip: 'Notifications',
            ),
          if (showNotificationAndFilter && onFilter != null)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: onFilter,
              tooltip: 'Filter',
            ),
          if (showAddButton && onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
              tooltip: 'Add',
            ),
        ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset('assets/images/balaghny_logo.png', height: 35),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              if (trailingWidgets.isNotEmpty) Row(children: trailingWidgets),
            ],
          ),
          const SizedBox(height: 12),
          if (showTabs && tabs != null) ...[tabs!, const SizedBox(height: 24)],
          Expanded(child: child),
        ],
      ),
    );
  }
}
