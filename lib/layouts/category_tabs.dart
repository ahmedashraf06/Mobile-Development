import 'package:flutter/material.dart';

class CategoryTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final bool underlineFullWord;
  final List<String>? customLabels;
  final double tabSpacing;

  const CategoryTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.customLabels,
    this.underlineFullWord = false,
    this.tabSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final tabs =
        customLabels ?? ['All', 'Announcements', 'Polls', 'Ads', 'Reports'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          final label = tabs[index];
          final labelStyle = TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isSelected ? Colors.black : Colors.black54,
          );

          return GestureDetector(
            onTap: () => onSelect(index),
            child: Padding(
              padding: EdgeInsets.only(right: tabSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: labelStyle),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width:
                        isSelected && underlineFullWord
                            ? _textWidth(label, labelStyle)
                            : isSelected
                            ? 20
                            : 0,
                    color:
                        isSelected
                            ? const Color(0xFF1877F2)
                            : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  static double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return painter.width;
  }
}
