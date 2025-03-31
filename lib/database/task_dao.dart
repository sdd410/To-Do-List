import 'package:drift/drift.dart';
import 'package:lets_do_it/database/task.dart';
import 'package:lets_do_it/database/task_time_log.dart';

import 'app_data_base.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks, TaskTimeLogs]) // Include your tables here
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // Insert a Task
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  // Get all Tasks
  Future<List<Task>> getAllTasks() => select(tasks).get();

  // Get a specific Task by ID
  Future<Task?> getTaskById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Update a Task
  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  // Delete a Task
  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // Insert a Time Log
  Future<int> insertTimeLog(TaskTimeLogsCompanion log) =>
      into(taskTimeLogs).insert(log);

  // Get all Time Logs for a specific task
  Future<List<TaskTimeLog>> getTimeLogsForTask(int taskId) =>
      (select(taskTimeLogs)..where((log) => log.taskId.equals(taskId))).get();
}
