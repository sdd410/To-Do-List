import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:lets_do_it/database/app_data_base.dart';

class AddTaskScreen extends StatefulWidget {
  final AppDatabase database;
  const AddTaskScreen({super.key, required this.database});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  void _saveTask() async {
    if (_titleController.text.isEmpty) return;

    final newTask = TasksCompanion(
      title: Value(_titleController.text),
      description: Value(_descriptionController.text),
      isCompleted: const Value(false),
    );

    await widget.database.insertTask(newTask);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Add Task"),
        backgroundColor: Colors.pink,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Task Title",
                  labelStyle: TextStyle(color: Colors.pink[700]),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink[200]!),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Task Description",
                  labelStyle: TextStyle(color: Colors.pink[700]),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink[200]!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _saveTask,
                  child: const Text(
                    "Save Task",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
