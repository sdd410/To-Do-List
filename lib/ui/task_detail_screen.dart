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
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool isRunning = false;
  DateTime? startTime;
  bool isEditing = false;
  List<TaskTimeLog> _timeLogs = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _loadTimeLogs();
  }

  Future<void> _loadTimeLogs() async {
    final logs = await widget.database.getTaskTimeLogs(widget.task.id);
    setState(() {
      _timeLogs = logs;
    });
  }

  Future<void> _updateTask() async {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: Value(_descriptionController.text),
    );
    await widget.database.updateTask(updatedTask);
    setState(() {
      isEditing = false;
    });
  }

  Future<void> _deleteTask() async {
    await widget.database.deleteTask(widget.task.id);
    Navigator.pop(context, true);
  }

  Future<void> _toggleTimer() async {
    if (isRunning) {
      await widget.database
          .into(widget.database.taskTimeLogs)
          .insert(
            TaskTimeLogsCompanion(
              taskId: Value(widget.task.id),
              startTime: Value(startTime!),
              endTime: Value(DateTime.now()),
            ),
          );
      _loadTimeLogs();
      setState(() {
        isRunning = false;
        startTime = null;
      });
    } else {
      setState(() {
        isRunning = true;
        startTime = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
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
                "Task: ${widget.task.title}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Description: ${widget.task.description}"),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
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
    );
  }
}
