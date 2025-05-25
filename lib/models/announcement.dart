import 'dart:io';

enum Region {
  firstSettlement,
  fifthSettlement,
  thirdSettlement,
}

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

class Announcement {
  final String id;
  final String title;
  final String details;
  final DateTime postedAt;
  final Region region;
  final Category category;
  final File? attachment;

  Announcement({
    required this.id,
    required this.title,
    required this.details,
    required this.postedAt,
    required this.region,
    required this.category,
    this.attachment,
  });

  //get time
  String get timeAgo {
    final duration = DateTime.now().difference(postedAt);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hr ago';
    return '${duration.inDays} days ago';
  }

  //readable strings
  String get regionLabel => region.name.replaceAll('Settlement', ' Settlement').capitalize();
  String get categoryLabel => category.name.capitalize();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
