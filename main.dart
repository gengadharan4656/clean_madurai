import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/complaint/complaint_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/map/dustbin_map_screen.dart';
import 'screens/points/points_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/collector/collector_screen.dart';
import 'services/notification_service.dart';
import 'services/n8n_service.dart';
import 'services/ai_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (catch errors gracefully for dev without google-services.json)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped (no google-services.json?): $e');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Notifications
  await NotificationService.initialize();

  // Schedule daily n8n morning messages
  await N8nService.scheduleDailyMorningMessages();

  // Configure AI service API key
  // In production: load from secure storage or environment
  // AiService.setApiKey('your-anthropic-api-key-here');
  // Or use: --dart-define=ANTHROPIC_API_KEY=sk-ant-xxx when building

  // Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: CleanMaduraiApp()));
}

class CleanMaduraiApp extends ConsumerWidget {
  const CleanMaduraiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Clean Madurai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/complaint': (context) => const ComplaintScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/dustbin-map': (context) => const DustbinMapScreen(),
        '/points': (context) => const PointsScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/collector': (context) => const CollectorScreen(),
      },
    );
  }
}
