enum LogType { yte, nyte }

class LogEntry {
  final DateTime timestamp;
  final double calories;
  final LogType type;
  final String? description;

  LogEntry({
    required this.timestamp,
    required this.calories,
    required this.type,
    this.description,
  });
}
