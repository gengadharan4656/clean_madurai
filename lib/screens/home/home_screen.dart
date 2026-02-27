// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../report/report_screen.dart';
import '../complaints/my_complaints_screen.dart';
import '../feed/public_feed_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ReportScreen(),
    const MyComplaintsScreen(),
    const PublicFeedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();

    return StreamBuilder<UserModel?>(
      stream: userService.userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Report'),
                const BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'My Reports'),
                const BottomNavigationBarItem(icon: Icon(Icons.public_outlined), activeIcon: Icon(Icons.public), label: 'Feed'),
                BottomNavigationBarItem(
                  icon: user?.badges.isNotEmpty == true
                      ? Stack(
                          children: [
                            const Icon(Icons.person_outline),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
