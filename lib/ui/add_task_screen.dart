import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:lets_do_it/database/app_data_base.dart';

class AddTaskScreen extends StatefulWidget {
  final AppDatabase database;
  const AddTaskScreen({super.key, required this.database});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _saveTask() async {
    if (_titleController.text.isEmpty) return;

    final newTask = TasksCompanion(
      title: Value(_titleController.text),
      description: Value(_descriptionController.text),
      isCompleted: const Value(false),
    );

    await widget.database.insertTask(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Task Title"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Task Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTask,
              child: const Text("Save Task"),
            ),
          ],
        ),
      ),
    );
  }
}
