import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_do_it/database/app_data_base.dart';

class TaskDetailScreen extends StatefulWidget {
  final AppDatabase database;
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.database,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _currentTask;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool isRunning = false;
  DateTime? startTime;
  bool isEditing = false;
  List<TaskTimeLog> _timeLogs = [];
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _loadTimeLogs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeLogs() async {
    final logs = await widget.database.getTaskTimeLogs(_currentTask.id);
    if (!mounted) return;
    setState(() {
      _timeLogs = logs;
    });
  }

  Future<void> _updateTask() async {
    final updatedTask = _currentTask.copyWith(
      title: _titleController.text,
      description: Value(_descriptionController.text),
    );
    await widget.database.updateTask(updatedTask);
    if (!mounted) return;
    setState(() {
      _currentTask = updatedTask;
      isEditing = false;
    });
  }

  Future<void> _deleteTask() async {
    _timer?.cancel();
    await widget.database.deleteTask(_currentTask.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _toggleTimer() {
    if (isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      isRunning = true;
      startTime = DateTime.now();
      _elapsedTime = Duration.zero;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedTime = DateTime.now().difference(startTime!);
      });
    });
  }

  Future<void> _stopTimer() async {
    _timer?.cancel();
    if (startTime == null) return;
    final now = DateTime.now();
    final end = now.isBefore(startTime!) ? startTime! : now;
    await widget.database
        .into(widget.database.taskTimeLogs)
        .insert(
          TaskTimeLogsCompanion(
            taskId: Value(_currentTask.id),
            startTime: Value(startTime!),
            endTime: Value(end),
          ),
        );
    if (!mounted) return;
    setState(() {
      isRunning = false;
      startTime = null;
    });
    _loadTimeLogs();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _timer?.cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Task Details"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing) ...[
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Task Title"),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Task Description",
                  ),
                ),
              ] else ...[
                Text(
                  "Task: ${_currentTask.title}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("Description: ${_currentTask.description ?? ''}"),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEditing = !isEditing;
                        if (!isEditing) {
                          _titleController.text = _currentTask.title;
                          _descriptionController.text = _currentTask.description ?? '';
                        }
                      });
                    },
                    child: Text(isEditing ? "Cancel" : "Edit"),
                  ),
                  if (isEditing)
                    ElevatedButton(
                      onPressed: _updateTask,
                      child: const Text("Save Changes"),
                    ),
                  ElevatedButton(
                    onPressed: _deleteTask,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Delete Task"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleTimer,
                child: Text(isRunning ? "Stop Timer" : "Start Timer"),
              ),
              if (isRunning)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Elapsed Time: ${_elapsedTime.inHours}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text("Time Logs:"),
              Expanded(
                child: ListView.builder(
                  itemCount: _timeLogs.length,
                  itemBuilder: (context, index) {
                    final log = _timeLogs[index];
                    return ListTile(
                      title: Text(
                        "Start: ${DateFormat('hh:mm a').format(log.startTime)} - End: ${log.endTime != null ? DateFormat('hh:mm a').format(log.endTime!) : 'Ongoing'}",
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
