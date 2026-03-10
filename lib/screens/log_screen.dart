import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_entry.dart';

class LogScreen extends StatelessWidget {
  final List<LogEntry> logs;

  const LogScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'HISTORIKK',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Ingen aktiviteter ennå',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[logs.length - 1 - index];
                final isYte = log.type == LogType.yte;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isYte
                          ? Colors.blueAccent.withOpacity(0.1)
                          : Colors.orangeAccent.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (isYte ? Colors.blueAccent : Colors.orangeAccent)
                                  .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isYte ? Icons.fitness_center : Icons.sports_bar,
                          color: isYte
                              ? Colors.blueAccent
                              : Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isYte ? 'Treningsøkt' : 'Halvliter nytt',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'dd. MMM, HH:mm',
                              ).format(log.timestamp),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isYte ? '+' : '-'}${log.calories.round()} kcal',
                        style: TextStyle(
                          color: isYte
                              ? Colors.blueAccent
                              : Colors.orangeAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
