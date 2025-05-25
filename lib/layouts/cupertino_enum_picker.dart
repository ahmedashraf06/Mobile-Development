import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoEnumPicker {
  static void showStringPicker({
    required BuildContext context,
    required List<String> values,
    required String? currentValue,
    required void Function(String) onSelected,
  }) {
    final scrollController = FixedExtentScrollController(
      initialItem: currentValue != null ? values.indexOf(currentValue) : 0,
    );

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 16, top: 12),
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: scrollController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      onSelected(values[index]);
                    },
                    children:
                        values
                            .map(
                              (r) => Center(
                                child: Text(
                                  r,
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
