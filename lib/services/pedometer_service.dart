import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  late Stream<StepCount> _stepCountStream;
  int _baseSteps = -1;
  int _currentSteps = 0;

  final _stepsController = StreamController<int>.broadcast();
  Stream<int> get stepsStream => _stepsController.stream;

  Future<bool> initialize() async {
    print("PedometerService: Initializing...");
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _initPedometer();
      return true;
    }
    return false;
  }

  void _initPedometer() {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen((StepCount event) {
        if (_baseSteps == -1) {
          _baseSteps = event.steps;
        }
        _currentSteps = event.steps - _baseSteps;
        _stepsController.add(_currentSteps);
      }).onError((error) {
        print("Pedometer Error: $error");
      });
    } catch (e) {
      print("Pedometer Error during init: $e");
    }
  }

  int get currentSteps => _currentSteps;

  void dispose() {
    _stepsController.close();
  }
}
