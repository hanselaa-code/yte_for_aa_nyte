import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import 'package:intl/intl.dart';

class LogScreen extends StatelessWidget {
  final List<LogEntry> logs;

  const LogScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final sortedLogs = List<LogEntry>.from(logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'HISTORIKK',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: sortedLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingen registreringer ennå',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beveg deg eller nyt en kald en!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              itemCount: sortedLogs.length,
              itemBuilder: (context, index) {
                final entry = sortedLogs[index];
                return _buildLogItem(entry);
              },
            ),
    );
  }

  Widget _buildLogItem(LogEntry entry) {
    final isYte = entry.type == LogType.yte;
    final primaryColor = isYte
        ? const Color(0xFF3B82F6)
        : const Color(0xFFF2B90D);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isYte ? Icons.directions_run : Icons.sports_bar,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYte ? 'Treningsøkt' : 'Nytelse (0.5L)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'EEEE d. MMMM - HH:mm',
                    'nb_NO',
                  ).format(entry.timestamp),
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isYte ? "+" : "-"}${entry.calories.toInt()} kcal',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isYte ? Colors.green : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isYte ? 'TJENT' : 'BRUKT',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
