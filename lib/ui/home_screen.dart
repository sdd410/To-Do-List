import 'package:flutter/material.dart';
import 'package:lets_do_it/database/app_data_base.dart';

import 'add_task_screen.dart';
import 'task_analysis_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppDatabase database;
  const HomeScreen({super.key, required this.database});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      TaskListScreen(database: widget.database),
      AnalysisScreen(database: widget.database),
    ];

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("To-Do List"),
        backgroundColor: Colors.pink.shade300,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.pink.shade300,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.pink.shade100,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Insights",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                backgroundColor: Colors.pink.shade300,
                onPressed: () async {
                  bool? added = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              AddTaskScreen(database: widget.database),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                    ),
                  );
                  if (added == true) setState(() {});
                },
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }
}

class TaskListScreen extends StatelessWidget {
  final AppDatabase database;
  const TaskListScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: database.watchAllTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          );
        }
        final tasks = snapshot.data!;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: Key(task.id.toString()),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                child: const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
              onDismissed: (direction) async {
                await database.deleteTask(task.id);
              },
              child: ListTile(
                tileColor: Colors.pink.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  task.title,
                  style: const TextStyle(color: Colors.black),
                ),
                subtitle: Text(
                  task.isCompleted ? "Completed" : "Pending",
                  style: TextStyle(color: Colors.pink.shade900),
                ),
                trailing: Checkbox(
                  activeColor: Colors.pink.shade400,
                  value: task.isCompleted,
                  onChanged: (value) async {
                    await database.updateTask(
                      task.copyWith(isCompleted: value!),
                    );
                  },
                ),
                onTap: () async {
                  bool? updated = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              TaskDetailScreen(database: database, task: task),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                    ),
                  );
                  if (updated == true) {}
                },
              ),
            );
          },
        );
      },
    );
  }
}
