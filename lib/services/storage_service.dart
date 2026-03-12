import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/log_entry.dart';

class StorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _logsRef {
    if (_userId == null) throw Exception('User not logged in');
    return _db.collection('users').doc(_userId).collection('logs');
  }

  Future<void> addLog(LogEntry entry) async {
    try {
      final docRef = await _logsRef.add(entry.toMap());
      print("StorageService: Added log with ID: ${docRef.id}");
    } catch (e) {
      print("StorageService: Error adding log: $e");
    }
  }

  Stream<List<LogEntry>> getLogs() {
    print("StorageService: Initializing logs stream for user: $_userId");
    try {
      return _logsRef.orderBy('timestamp', descending: true).snapshots().map((
        snapshot,
      ) {
        print("StorageService: Received ${snapshot.docs.length} logs from Firestore");
        return snapshot.docs.map((doc) {
          try {
            return LogEntry.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
          } catch (e) {
            print("StorageService: Error parsing log ${doc.id}: $e");
            rethrow;
          }
        }).toList();
      });
    } catch (e) {
      print("StorageService: Error in getLogs stream: $e");
      return Stream.value([]);
    }
  }

  // Helper to get logs for a specific day
  Stream<List<LogEntry>> getLogsForDay(DateTime day) {
    DateTime start = DateTime(day.year, day.month, day.day);
    DateTime end = start.add(const Duration(days: 1));

    return _logsRef
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LogEntry.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            );
          }).toList();
        });
  }

  Future<void> deleteLogEntry(String id) async {
    try {
      await _logsRef.doc(id).delete();
      print("StorageService: Deleted log with ID: $id");
    } catch (e) {
      print("StorageService: Error deleting log: $e");
      rethrow;
    }
  }
}
