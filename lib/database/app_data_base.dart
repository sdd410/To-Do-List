import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'task.dart';
import 'task_dao.dart';
import 'task_time_log.dart';

part 'app_data_base.g.dart';

@DriftDatabase(tables: [Tasks, TaskTimeLogs], daos: [TaskDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // Insert a new task
  Future<int> insertTask(TasksCompanion task) async {
    return into(tasks).insert(task);
  }

  // Fetch all tasks as a stream (auto-updates)
  Stream<List<Task>> watchAllTasks() {
    return select(tasks).watch();
  }

  // Update a task
  Future<bool> updateTask(Task task) async {
    return update(tasks).replace(task);
  }

  // Delete a task and its time logs
  Future<int> deleteTask(int id) async {
    await (delete(taskTimeLogs)..where((l) => l.taskId.equals(id))).go();
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Task>> getAllTasks() async {
    return await select(tasks).get();
  }

  Future<List<TaskTimeLog>> getTaskTimeLogs(int taskId) {
    return (select(taskTimeLogs)
      ..where((log) => log.taskId.equals(taskId))).get();
  }

  Future<void> insertTaskTimeLog(TaskTimeLogsCompanion log) async {
    await into(taskTimeLogs).insert(log);
  }
}

// Database connection function
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tasks.sqlite'));
    return NativeDatabase(file);
  });
}
