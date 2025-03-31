import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_do_it/database/app_data_base.dart';

class AnalysisScreen extends StatefulWidget {
  final AppDatabase database;
  const AnalysisScreen({super.key, required this.database});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Task? selectedTask;
  List<Task> tasks = [];
  Map<DateTime, double> timeSpentPerDay = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final allTasks = await widget.database.getAllTasks();
    setState(() {
      tasks = allTasks;
    });
  }

  Future<void> _loadTimeLogs() async {
    if (selectedTask == null) return;
    final logs = await widget.database.getTaskTimeLogs(selectedTask!.id);
    final timeMap = <DateTime, double>{};
    for (var log in logs) {
      if (log.endTime != null) {
        final date = DateTime(
          log.startTime.year,
          log.startTime.month,
          log.startTime.day,
        );
        final duration =
            log.endTime!.difference(log.startTime).inMinutes / 60.0;
        timeMap[date] = (timeMap[date] ?? 0) + duration;
      }
    }
    setState(() {
      timeSpentPerDay = timeMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analysis & Insights")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<Task>(
              hint: const Text("Select a Task"),
              value: selectedTask,
              isExpanded: true,
              onChanged: (task) {
                setState(() {
                  selectedTask = task;
                });
                _loadTimeLogs();
              },
              items:
                  tasks.map((task) {
                    return DropdownMenuItem(
                      value: task,
                      child: Text(task.title),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  timeSpentPerDay.isEmpty
                      ? const Center(child: Text("No data available"))
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  DateTime date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt(),
                                      );
                                  return Text(DateFormat('MM/dd').format(date));
                                },
                                reservedSize: 30,
                              ),
                            ),
                          ),
                          barGroups:
                              timeSpentPerDay.entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key.millisecondsSinceEpoch,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value,
                                      color: Colors.blue,
                                      width: 16,
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
