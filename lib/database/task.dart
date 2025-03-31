import 'package:drift/drift.dart';

@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); // Task ID
  TextColumn get title => text().withLength(min: 1, max: 255)(); // Task Name
  TextColumn get description => text().nullable()(); // Optional Description
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))(); // Task Status
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)(); // When Task Was Created
}
