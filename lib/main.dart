import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/complaint_service.dart';
import 'services/user_service.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/collector/collector_home_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'features/assistant/waste_assistant_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = true;
  Object? firebaseInitError;

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }

    // ✅ ADD THIS LINE HERE (after Firebase init, before runApp)
    await WasteClassifier.loadDataset();

  } catch (e) {
    firebaseReady = false;
    firebaseInitError = e;
    debugPrint('Firebase init error: $e');
  }

  runApp(CleanMaduraiApp(
    firebaseReady: firebaseReady,
    firebaseInitError: firebaseInitError,
  ));
}

class CleanMaduraiApp extends StatelessWidget {
  final bool firebaseReady;
  final Object? firebaseInitError;

  const CleanMaduraiApp({
    super.key,
    required this.firebaseReady,
    this.firebaseInitError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ComplaintService()),
        ChangeNotifierProvider(create: (_) => UserService()),
      ],
      child: MaterialApp(
        title: 'Clean Madurai',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            primary: const Color(0xFF1B5E20),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7F0),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1B5E20), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const AssistantOverlay(),
            ],
          );
        },
        home: firebaseReady
            ? const AuthWrapper()
            : FirebaseErrorScreen(error: firebaseInitError),
      ),
    );
  }
}

// KEY: This handles persistent login.
// Unauthenticated users now see the Landing page.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError) {
          // Show landing page on error so user can try to log in
          return const LandingScreen();
        }

        // User already logged in → route by role
        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }
              final role =
                  userSnap.data?.data()?['role'] as String? ?? 'citizen';
              if (role == 'collector') {
                return const CollectorHomeScreen();
              }
              return const HomeScreen();
            },
          );
        }

        // Not logged in → show scrollable landing page
        return const LandingScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1B5E20),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🧹', style: TextStyle(fontSize: 64)),
            SizedBox(height: 20),
            Text(
              'Clean Madurai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AI-Powered Cleanliness Platform',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final Object? error;
  const FirebaseErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 52),
              const SizedBox(height: 12),
              const Text(
                'Unable to connect to Firebase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please verify firebase_options.dart / google-services configuration and retry.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
