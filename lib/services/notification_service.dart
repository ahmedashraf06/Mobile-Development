import 'package:balaghnyv1/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          final timestamp = DateTime.tryParse(payload);
          if (timestamp != null) {
            navigatorKey.currentState?.pushNamed(
              '/post_cards_detailed/citizen_announcement_detail_page',
              arguments: timestamp,
            );
          }
        }
      },
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    DateTime? payloadTimestamp, // ✅ make optional
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payloadTimestamp?.toIso8601String(), // ✅ won't crash if null
    );
  }
}
