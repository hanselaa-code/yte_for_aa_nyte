import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/log_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'models/log_entry.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  runApp(const YteForNyteApp());
}

class YteForNyteApp extends StatelessWidget {
  const YteForNyteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yte for å Nyte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'BeVietnamPro',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: StreamBuilder(
        stream: AuthService().user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final List<LogEntry> _logs = [];
  int _previousBeers = 0;

  double get _burnedTotal => _logs
      .where((e) => e.type == LogType.yte)
      .fold(0, (sum, e) => sum + e.calories);

  double get _consumedTotal => _logs
      .where((e) => e.type == LogType.nyte)
      .fold(0, (sum, e) => sum + e.calories);

  double get _balance => _burnedTotal - _consumedTotal;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addLog(double kcal, LogType type) async {
    setState(() {
      _logs.add(
        LogEntry(timestamp: DateTime.now(), calories: kcal, type: type),
      );
    });

    // Check for new beer milestone
    int currentBeers = math.max(0, (_balance / 215).floor());
    if (currentBeers > _previousBeers) {
      _previousBeers = currentBeers;

      final prefs = await SharedPreferences.getInstance();
      bool enabled = prefs.getBool('notifications_enabled') ?? true;

      if (enabled) {
        await NotificationService().showBeerMilestone(currentBeers);
      }
    } else {
      // Also update previousBeers if it decreased (e.g. after drinking one)
      _previousBeers = currentBeers;
    }
  }

  void _addManualActivity(double kcal, String activity) {
    _addLog(kcal, LogType.yte);
  }

  void _removeOneBeer() {
    if (_balance >= 215) {
      _addLog(215, LogType.nyte);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skål! 🍺 Ny halvliter registrert.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du har ikke tjent nok til en halvliter ennå!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        balance: _balance,
        burned: _burnedTotal,
        consumed: _consumedTotal,
        onScanTrening: () {},
        onScanNyte: _removeOneBeer,
        onManualAdd: _addManualActivity,
      ),
      LogScreen(logs: _logs),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Oversikt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Historikk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
