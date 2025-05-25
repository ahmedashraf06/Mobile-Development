import 'package:balaghnyv1/layouts/post_navigator.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final String category;
  final String? imageUrl;
  final DateTime timestamp;

  final bool showEdit;
  final bool showDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.imageUrl,
    required this.timestamp,
    this.showEdit = false,
    this.showDelete = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(timestamp);
    final formattedCategory = _capitalizeCategory(category);

    return InkWell(
      onTap: () => navigateToPostDetail(context, type, timestamp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttachmentPreview(context),
            const SizedBox(width: 12),

            // Text content and icons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(type),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Category + time + icons row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              formattedCategory,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF98A2B3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF98A2B3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showEdit)
                        GestureDetector(
                          onTap: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF344054),
                            ),
                          ),
                        ),
                      if (showDelete)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.delete,
                              size: 18,
                              color: Color(0xFF344054),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          // If it's not a valid image (PDF, DOCX, etc.)
          return Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insert_drive_file, color: Colors.black54),
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, color: Colors.white),
    );
  }

  String _capitalize(String str) =>
      str.isEmpty ? '' : '${str[0].toUpperCase()}${str.substring(1)}';

  String _capitalizeCategory(String category) {
    return category
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return "just now";
    if (duration.inMinutes < 60) return "${duration.inMinutes}m ago";
    if (duration.inHours < 24) return "${duration.inHours}h ago";
    return "${duration.inDays}d ago";
  }
}
