import 'package:drift/drift.dart';

@DataClassName('TaskTimeLog')
class TaskTimeLogs extends Table {
  IntColumn get id => integer().autoIncrement()(); // Log Entry ID
  IntColumn get taskId =>
      integer().customConstraint(
        'REFERENCES tasks(id) ON DELETE CASCADE',
      )(); // Foreign Key to Tasks
  DateTimeColumn get startTime => dateTime()(); // When user started the task
  DateTimeColumn get endTime =>
      dateTime().nullable()(); // When user stopped (nullable until stopped)
  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, startTime}, // Ensuring a unique start time per task
  ];
  @override
  List<String> get customConstraints => [
    'CHECK (endTime IS NULL OR endTime > startTime)', // Ensuring endTime > startTime if not null
  ];
}
