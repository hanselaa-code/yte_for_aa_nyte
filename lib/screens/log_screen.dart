import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_entry.dart';

class LogScreen extends StatelessWidget {
  final List<LogEntry> logs;
  final Function(String id)? onDelete;

  const LogScreen({super.key, required this.logs, this.onDelete});

  Map<String, List<LogEntry>> _groupLogsByDay() {
    final Map<String, List<LogEntry>> grouped = {};
    for (var log in logs) {
      final dateStr = DateFormat(
        'EEEE, d. MMMM yyyy',
        'nb_NO',
      ).format(log.timestamp);
      if (grouped.containsKey(dateStr)) {
        grouped[dateStr]!.add(log);
      } else {
        grouped[dateStr] = [log];
      }
    }
    return grouped;
  }

  Future<void> _showDeleteDialog(BuildContext context, LogEntry log) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Slett aktivitet?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Er du sikker på at du vil slette denne aktiviteten? Dette kan ikke angres.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('AVBRYT', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              onDelete?.call(log.id!);
              Navigator.pop(context);
            },
            child: const Text('SLETT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _groupLogsByDay();
    final dates = groupedLogs.keys.toList();

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
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final dayLogs = groupedLogs[date]!;

                double dayBurned = dayLogs
                    .where((e) => e.type == LogType.yte)
                    .fold(0, (sum, e) => sum + e.calories);
                double dayConsumed = dayLogs
                    .where((e) => e.type == LogType.nyte)
                    .fold(0, (sum, e) => sum + e.calories);

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        date.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Totalt: +${dayBurned.round()} / -${dayConsumed.round()} kcal',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      iconColor: Colors.blueAccent,
                      collapsedIconColor: Colors.white60,
                      children: dayLogs.map((log) {
                        final isYte = log.type == LogType.yte;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isYte ? Icons.fitness_center : Icons.sports_bar,
                                color: isYte
                                    ? Colors.blueAccent
                                    : Colors.orangeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isYte ? 'Treningsøkt' : 'Enhet registrert',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(log.timestamp),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white24,
                                  size: 20,
                                ),
                                onPressed: () => _showDeleteDialog(context, log),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
