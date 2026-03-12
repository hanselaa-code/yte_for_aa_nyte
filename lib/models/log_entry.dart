import 'package:cloud_firestore/cloud_firestore.dart';

enum LogType { yte, nyte }

class LogEntry {
  final String? id;
  final DateTime timestamp;
  final double calories;
  final LogType type;
  final String? description;

  LogEntry({
    this.id,
    required this.timestamp,
    required this.calories,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'calories': calories,
      'type': type.name,
      'description': description,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map, {String? id}) {
    try {
      final timestampData = map['timestamp'];
      DateTime timestamp;
      if (timestampData is String) {
        timestamp = DateTime.parse(timestampData);
      } else if (timestampData is Timestamp) {
        timestamp = timestampData.toDate();
      } else {
        timestamp = DateTime.now();
      }

      return LogEntry(
        id: id,
        timestamp: timestamp,
        calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
        type: LogType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => LogType.yte,
        ),
        description: map['description'] as String?,
      );
    } catch (e) {
      print("LogEntry: Error parsing Map: $e. Map content: $map");
      return LogEntry(
        id: id,
        timestamp: DateTime.now(),
        calories: 0,
        type: LogType.yte,
        description: "Error parsing entry",
      );
    }
  }
}
