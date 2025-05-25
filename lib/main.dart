import 'package:balaghnyv1/onboarding_page.dart';
import 'package:balaghnyv1/post_cards_detailed/citizen_announcement_detail_page.dart';
import 'package:balaghnyv1/services/notification_service.dart';
import 'package:balaghnyv1/splash_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'advertiser/advertiser_create_ad_page.dart';
import 'congratulations_page.dart';
import 'firebase_options.dart';
import 'citizen/main_citizen.dart';
import 'citizen/citizen_chat_page.dart';
import 'government/main_government.dart';
import 'government/government_chat_page.dart';
import 'signup_page.dart';
import 'login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotification();

  //Handle push notification taps from background state
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final route = message.data['route'];
    final timestamp = message.data['timestamp'];

    if (route == 'announcement' && timestamp != null) {
      navigatorKey.currentState?.pushNamed(
        '/post_cards_detailed/citizen_announcement_detail_page',
        arguments: DateTime.tryParse(timestamp),
      );
    }
  });

  //Handle foreground push messages (optional if using FCM)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService().showNotification(
      title: message.notification?.title ?? 'New message',
      body: message.notification?.body ?? '',
      payloadTimestamp: DateTime.now(), // ✅ fallback if no timestamp
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Balaghny',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(surface: Colors.white),
      ),
      home: const SplashPage(),
      routes: {
        '/splash': (context) => const SplashPage(),
        '/congratulations': (context) => const CongratulationsPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/citizen/home': (context) => const MainCitizen(),
        '/citizen/citizen_chat_page': (context) => const CitizenChatPage(),
        '/government/chat': (context) => const GovernmentChatPage(),
        '/admin': (context) => const MainGovernment(),
        '/advertiser': (context) => const CreateAdPage(),
        '/government/home': (context) => const MainGovernment(),
        '/post_cards_detailed/citizen_announcement_detail_page': (context) {
          final timestamp =
              ModalRoute.of(context)!.settings.arguments as DateTime;
          return CitizenAnnouncementDetailPage(timestamp: timestamp);
        },
      },
    );
  }
}
