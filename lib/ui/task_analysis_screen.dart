import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_do_it/database/app_data_base.dart';

class AnalysisScreen extends StatefulWidget {
  final AppDatabase database;
  const AnalysisScreen({super.key, required this.database});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int? selectedTaskId;
  List<Task> tasks = [];
  Map<DateTime, double> timeSpentPerDay = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final allTasks = await widget.database.getAllTasks();
    if (!mounted) return;
    setState(() {
      tasks = allTasks;
      if (selectedTaskId == null && tasks.isNotEmpty) {
        selectedTaskId = tasks.first.id;
        _loadTimeLogs();
      }
    });
  }

  Future<void> _loadTimeLogs() async {
    if (selectedTaskId == null) return;
    final logs = await widget.database.getTaskTimeLogs(selectedTaskId!);
    final timeMap = <DateTime, double>{};
    for (var log in logs) {
      if (log.endTime != null) {
        final date = DateTime(
          log.startTime.year,
          log.startTime.month,
          log.startTime.day,
        );
        final duration =
            log.endTime!.difference(log.startTime).inSeconds / 3600.0;
        timeMap[date] = (timeMap[date] ?? 0) + duration;
      }
    }
    if (!mounted) return;
    setState(() {
      timeSpentPerDay = timeMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = timeSpentPerDay.keys.toList()..sort();
    final maxDuration = timeSpentPerDay.values.fold(0.0, (m, v) => v > m ? v : m);
    final chartMaxY = maxDuration > 0 ? math.max(maxDuration * 1.25, 0.2) : 1.0;

    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Analysis & Insights"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              hint: const Text("Select a Task"),
              value: tasks.any((t) => t.id == selectedTaskId) ? selectedTaskId : null,
              isExpanded: true,
              dropdownColor: Colors.pink[100],
              onChanged: (taskId) {
                setState(() {
                  selectedTaskId = taskId;
                });
                _loadTimeLogs();
              },
              items:
                  tasks.map((task) {
                    return DropdownMenuItem<int>(
                      value: task.id,
                      child: Text(
                        task.title,
                        style: const TextStyle(color: Colors.purpleAccent),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  timeSpentPerDay.isEmpty
                      ? const Center(
                        child: Text(
                          "No time log data available",
                          style: TextStyle(color: Colors.purple),
                        ),
                      )
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: chartMaxY,
                          minY: 0,
                          backgroundColor: Colors.white,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const SizedBox.shrink();
                                  if (maxDuration < 0.1) {
                                    final mins = (value * 60).toStringAsFixed(1);
                                    return Text(
                                      "${mins}m",
                                      style: const TextStyle(color: Colors.purple, fontSize: 10),
                                    );
                                  }
                                  return Text(
                                    "${value.toStringAsFixed(1)}h",
                                    style: const TextStyle(color: Colors.purple, fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < sortedDates.length) {
                                    final date = sortedDates[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat('MM/dd').format(date),
                                        style: const TextStyle(
                                          color: Colors.purpleAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          barGroups:
                              sortedDates.asMap().entries.map((entry) {
                                final index = entry.key;
                                final date = entry.value;
                                final duration = timeSpentPerDay[date] ?? 0.0;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: duration,
                                      color: Colors.pinkAccent,
                                      width: 16,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                );
                              }).toList(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.pink[200],
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                final hours = rod.toY;
                                final label = hours < 0.1
                                    ? "${(hours * 60).toStringAsFixed(1)} min"
                                    : "${hours.toStringAsFixed(2)} hrs";
                                return BarTooltipItem(
                                  label,
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
