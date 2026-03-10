import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/log_screen.dart';
import 'screens/profile_screen.dart';
// import 'screens/scanner_screen.dart';
import 'models/log_entry.dart';

void main() {
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
          seedColor: const Color(0xFFF2B90D),
          primary: const Color(0xFFF2B90D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'BeVietnamPro',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FAFB),
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: const MainNavigation(),
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
  final List<LogEntry> _logs = [];

  double get _burnedTotal => _logs
      .where((e) => e.type == LogType.yte)
      .fold(0, (sum, e) => sum + e.calories);

  double get _consumedTotal => _logs
      .where((e) => e.type == LogType.nyte)
      .fold(0, (sum, e) => sum + e.calories);

  double get _balance => _burnedTotal - _consumedTotal;

  void _addLog(double kcal, LogType type, [String? description]) {
    setState(() {
      _logs.add(
        LogEntry(timestamp: DateTime.now(), calories: kcal, type: type),
      );
    });
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
          backgroundColor: Color(0xFFF2B90D),
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
        onScanTrening: () {
          // In the new design, the + button can just be an informational or quick add
          // For now, let's keep it as a placeholder or redirect to manual input
        },
        onScanNyte: _removeOneBeer,
        onManualAdd: _addManualActivity,
      ),
      LogScreen(logs: _logs),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFF2B90D),
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
