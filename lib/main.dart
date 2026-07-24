import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skillpay/services/push_notification_service.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase (required for FCM push notifications)
  await Firebase.initializeApp();

  // Initialize Supabase — used only for Auth (JWT) and Realtime (chat)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize push notifications (requests permissions, saves FCM token via API)
  await PushNotificationService().initialize();

  runApp(const SkillpayApp());
}

class SkillpayApp extends StatelessWidget {
  const SkillpayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skillpay',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
