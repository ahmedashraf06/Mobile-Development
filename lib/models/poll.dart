import 'dart:io';

enum Region { firstSettlement, fifthSettlement, thirdSettlement }

enum Category {
  water,
  electricity,
  roadwork,
  transportation,
  safety,
  environment,
  event,
  general,
}

enum PollStatus { active, closed, draft }

class Poll {
  final String id;
  final String title;
  final String details;
  final DateTime postedAt;
  final DateTime endDate;
  final Region region;
  final Category category;
  final File? attachment;
  final List<String> options;
  final PollStatus status;
  final List<Map<String, String>> votes;
  final int option1Count;
  final int option2Count;
  final int totalVotes;

  Poll({
    required this.id,
    required this.title,
    required this.details,
    required this.postedAt,
    required this.endDate,
    required this.region,
    required this.category,
    required this.options,
    required this.status,
    required this.votes,
    required this.option1Count,
    required this.option2Count,
    required this.totalVotes,
    this.attachment,
  });

  String get timeAgo {
    final duration = DateTime.now().difference(postedAt);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hr ago';
    return '${duration.inDays} days ago';
  }

  String get regionLabel =>
      region.name.replaceAll('Settlement', ' Settlement').capitalize();
  String get categoryLabel => category.name.capitalize();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
