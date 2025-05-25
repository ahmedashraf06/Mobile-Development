import 'dart:io';

enum ReportCategory {
  water,
  electricity,
  roadwork,
  transportation,
  safety,
  environment,
  event,
  general,
}

enum ReportStatus { pending, approved, rejected }

class Report {
  final String id;
  final String title;
  final String details;
  final ReportCategory category;
  final DateTime postedOn;
  final File? attachment;
  final String? locationUrl; // optional location link
  final ReportStatus status;
  final String submittedBy;

  Report({
    required this.id,
    required this.title,
    required this.details,
    required this.category,
    required this.postedOn,
    required this.submittedBy,
    this.attachment,
    this.locationUrl,
    this.status = ReportStatus.pending,
  });

  String get timeAgo {
    final duration = DateTime.now().difference(postedOn);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hr ago';
    return '${duration.inDays} days ago';
  }

  String get categoryLabel => category.name.capitalize();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
