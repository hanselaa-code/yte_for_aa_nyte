import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math' as math;

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/log_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/pedometer_service.dart';
import 'models/log_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  await initializeDateFormatting('nb_NO', null);
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
  final StorageService _storageService = StorageService();
  final PedometerService _pedometerService = PedometerService();
  int _previousBeers = 0;
  int _currentSteps = 0;
  bool _settingsLoaded = false; // Added this line
  double _beerKcal = 215.0; // Default 0.5L
  List<LogEntry> _lastLogs = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousBeers();
    _pedometerService.initialize();
    _pedometerService.stepsStream.listen((steps) {
      if (mounted) {
        setState(() {
          _currentSteps = steps;
        });
        _checkMilestones(_lastLogs);
      }
    });
  }

  Future<void> _loadPreviousBeers() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _previousBeers = prefs.getInt('previous_beers') ?? 0;
        double size = prefs.getDouble('selected_beer_size') ?? 0.5;
        _beerKcal = (size * 430.0); // 43 kcal per 100ml -> 430 kcal per liter
        _settingsLoaded = true;
      });
      print("MainNavigation: Loaded previous beers count: $_previousBeers, beer size kcal: $_beerKcal");
    }
  }

  Future<void> _savePreviousBeers(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('previous_beers', count);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addLog(double kcal, LogType type) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      calories: kcal,
      type: type,
    );
    await _storageService.addLog(entry);
  }

  void _checkMilestones(List<LogEntry> logs) async {
    _lastLogs = logs;
    if (!_settingsLoaded) {
      print("MainNavigation: Skipping milestone check, settings not loaded yet");
      return;
    }
    double burnedFromLogs = logs
        .where((e) => e.type == LogType.yte)
        .fold(0, (sum, e) => sum + e.calories);

    double burnedFromSteps = _currentSteps / 20.0;

    double consumedTotal = logs
        .where((e) => e.type == LogType.nyte)
        .fold(0, (sum, e) => sum + e.calories);

    double balance = (burnedFromLogs + burnedFromSteps) - consumedTotal;

    int currentBeers = math.max(0, (balance / _beerKcal).floor());

    if (currentBeers > _previousBeers) {
      int newBeersCount = currentBeers - _previousBeers;
      print("MainNavigation: Milestone reached! $currentBeers beers (Prev: $_previousBeers, New: $newBeersCount)");

      final prefs = await SharedPreferences.getInstance();
      bool enabled = prefs.getBool('notifications_enabled') ?? true;

      // Trigger a notification for EACH new beer earned
      for (int i = 1; i <= newBeersCount; i++) {
        int beerNum = _previousBeers + i;
        if (enabled) {
          print("MainNavigation: Showing notification for beer #$beerNum");
          await NotificationService().showBeerMilestone(beerNum);
          // Small delay between notifications to avoid system flooding/overlap
          if (newBeersCount > 1) await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _previousBeers = currentBeers;
      _savePreviousBeers(currentBeers);
    } else if (currentBeers < _previousBeers) {
      _previousBeers = currentBeers;
      _savePreviousBeers(currentBeers);
    }
  }

  void _addManualActivity(double kcal, String activity) {
    _addLog(kcal, LogType.yte);
  }

  void _removeOneBeer(double currentBalance) {
    if (currentBalance >= _beerKcal) {
      _addLog(_beerKcal, LogType.nyte);
      
      double size = (_beerKcal / 430.0).toDouble();
      String label = 'enhet';
      if (size > 0.32 && size < 0.34) label = 'småboks';
      if (size > 0.39 && size < 0.41) label = 'enhet';
      if (size > 0.49 && size < 0.51) label = 'halvliter';
      if (size > 0.59 && size < 0.61) label = 'stor enhet';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skål! 🍺 Ny $label registrert.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } else {
      double size = _beerKcal / 430.0;
      String label = 'enhet';
      if (size > 0.49 && size < 0.51) label = 'halvliter';
      if (size > 0.32 && size < 0.34) label = 'småboks';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Du har ikke tjent nok til en $label ennå!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LogEntry>>(
      stream: _storageService.getLogs(),
      builder: (context, snapshot) {
        final List<LogEntry> logs = snapshot.data ?? [];
        _lastLogs = logs;

        if (snapshot.hasData) {
          _checkMilestones(logs);
        }

        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);

        final List<LogEntry> todayLogs = logs.where((e) {
          final DateTime logDate = DateTime(
            e.timestamp.year,
            e.timestamp.month,
            e.timestamp.day,
          );
          return logDate.isAtSameMomentAs(today);
        }).toList();

        double burnedToday = todayLogs
            .where((e) => e.type == LogType.yte)
            .fold(0, (sum, e) => sum + e.calories);

        double consumedToday = todayLogs
            .where((e) => e.type == LogType.nyte)
            .fold(0, (sum, e) => sum + e.calories);

        double balanceToday = (burnedToday + (_currentSteps / 20.0)) - consumedToday;

        double size = (_beerKcal / 430.0);
        String currentLabel = 'ENHETER TILGJENGELIG';
        if (size > 0.32 && size < 0.34) currentLabel = 'SMÅBOKSER TILGJENGELIG';
        if (size > 0.49 && size < 0.51) currentLabel = 'HALVLITERE TILGJENGELIG';
        if (size > 0.59 && size < 0.61) currentLabel = 'STORE ENHETER TILGJENGELIG';

        final List<Widget> screens = [
          DashboardScreen(
            balance: balanceToday,
            burned: burnedToday,
            consumed: consumedToday,
            steps: _currentSteps,
            beerKcal: _beerKcal,
            beerLabel: currentLabel,
            onScanTrening: () {},
            onScanNyte: () {
              // Reload size right before registration to be sure
              _loadPreviousBeers();
              _removeOneBeer(balanceToday);
            },
            onManualAdd: _addManualActivity,
          ),
          LogScreen(
            logs: logs,
            onDelete: (id) => _storageService.deleteLogEntry(id),
          ),
          ProfileScreen(onSettingsChanged: _loadPreviousBeers),
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
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
      },
    );
  }
}
