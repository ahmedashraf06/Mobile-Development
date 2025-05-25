import 'dart:io';

enum Region { firstSettlement, fifthSettlement, thirdSettlement }

enum AdStatus { pending, approved, rejected }

enum AdCategory {
  foodAndBeverage,
  retailAndShops,
  services,
  health,
  dealsAndOffers,
  newInTheArea,
  other,
}

class Ad {
  final String id;
  final String title;
  final String details;
  final DateTime postedAt;
  final Region region;
  final AdCategory category;
  final File? attachment;
  final AdStatus status;

  Ad({
    required this.id,
    required this.title,
    required this.details,
    required this.postedAt,
    required this.region,
    required this.category,
    this.attachment,
    this.status = AdStatus.pending,
  });

  String get timeAgo {
    final duration = DateTime.now().difference(postedAt);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hr ago';
    return '${duration.inDays} days ago';
  }

  String get categoryLabel =>
      category.name
          .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
          .capitalize();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
