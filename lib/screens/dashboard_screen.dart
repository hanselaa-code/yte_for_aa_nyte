import 'package:flutter/material.dart';
import '../services/pedometer_service.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  final double balance;
  final double burned;
  final double consumed;
  final VoidCallback onScanTrening;
  final VoidCallback onScanNyte;
  final Function(double kcal, String activity) onManualAdd;

  const DashboardScreen({
    super.key,
    required this.balance,
    required this.burned,
    required this.consumed,
    required this.onScanTrening,
    required this.onScanNyte,
    required this.onManualAdd,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PedometerService _pedometerService = PedometerService();
  int _currentSteps = 0;
  String _selectedActivity = 'Løping';
  final TextEditingController _kcalController = TextEditingController();

  final List<String> _activities = [
    'Løping',
    'Sykling',
    'Styrketrening',
    'Gåtur',
    'Svømming',
    'Annet',
  ];

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  Future<void> _initPedometer() async {
    bool granted = await _pedometerService.initialize();
    if (granted) {
      _pedometerService.stepsStream.listen((steps) {
        if (mounted) {
          setState(() {
            _currentSteps = steps;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pedometerService.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  // 1 beer = ~215 kcal. If 1 step = 0.04 kcal, then 1 beer = 5375 steps.
  double get _stepsCalories => _currentSteps * 0.04;
  double get _totalBurned => widget.burned + _stepsCalories;
  double get _currentBalance => _totalBurned - widget.consumed;
  int get _beersAvailable => math.max(0, (_currentBalance / 215).floor());
  double get _nextBeerProgress => (_currentBalance % 215) / 215.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBeerCard(),
          const SizedBox(height: 20),
          _buildProgressCard(),
          const SizedBox(height: 20),
          _buildStepCard(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 30),
          _buildRegistrationSection(),
        ],
      ),
    );
  }

  Widget _buildBeerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TILGJENGELIGE HALVLITERE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(Icons.remove, widget.onScanNyte),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '$_beersAvailable',
                  style: const TextStyle(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              _circleButton(Icons.add, widget.onScanTrening),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nyt med god samvittighet!',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }

  Widget _buildProgressCard() {
    int stepsToNext = (215 - (_currentBalance % 215)) ~/ 0.04;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2B90D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2B90D).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Neste halvliter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${(_nextBeerProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFF2B90D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _nextBeerProgress,
              minHeight: 12,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF2B90D),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bare $stepsToNext skritt igjen til en velfortjent 0.5L!',
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Skritt i dag',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+12%',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_currentSteps',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Du har tjent $_currentSteps skritt så langt!',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    double distance = (_currentSteps * 0.7) / 1000.0;
    return Row(
      children: [
        Expanded(
          child: _statSmallCard(
            'Distanse',
            '${distance.toStringAsFixed(1)}',
            'km',
            Icons.directions_walk,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _statSmallCard(
            'Kalorier',
            '${_totalBurned.toInt()}',
            'kcal',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statSmallCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2B90D).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REGISTRER TRENING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFFF2B90D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TJEN FLERE HALVLITERE VED Å FORBRENNE MER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedActivity,
            decoration: _inputDecoration('Aktivitetstype'),
            items: _activities.map((String activity) {
              return DropdownMenuItem(value: activity, child: Text(activity));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedActivity = val!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _kcalController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Kalorier (kcal)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(_kcalController.text);
              if (val != null) {
                widget.onManualAdd(val, _selectedActivity);
                _kcalController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trening lagret!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2B90D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Lagre økt',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
