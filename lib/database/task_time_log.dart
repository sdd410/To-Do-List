import 'package:drift/drift.dart';
import 'task.dart';

@DataClassName('TaskTimeLog')
class TaskTimeLogs extends Table {
  IntColumn get id => integer().autoIncrement()(); // Log Entry ID
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)(); // Foreign Key to Tasks
  DateTimeColumn get startTime => dateTime()(); // When user started the task
  DateTimeColumn get endTime =>
      dateTime().nullable()(); // When user stopped (nullable until stopped)
  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, startTime}, // Ensuring a unique start time per task
  ];
  @override
  List<String> get customConstraints => [
    'CHECK (end_time IS NULL OR end_time >= start_time)', // Ensuring end_time >= start_time if not null
  ];
}
