import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  late Stream<StepCount> _stepCountStream;

  int _baseSteps = -1;
  int _currentSteps = 0;

  final _stepsController = StreamController<int>.broadcast();
  Stream<int> get stepsStream => _stepsController.stream;

  Future<bool> initialize() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _initPedometer();
      return true;
    }
    return false;
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;

    _stepCountStream
        .listen((StepCount event) {
          if (_baseSteps == -1) {
            _baseSteps = event.steps;
          }
          _currentSteps = event.steps - _baseSteps;
          _stepsController.add(_currentSteps);
        })
        .onError((error) {
          print("Pedometer Error: $error");
        });
  }

  int get currentSteps => _currentSteps;

  void dispose() {
    _stepsController.close();
  }
}
