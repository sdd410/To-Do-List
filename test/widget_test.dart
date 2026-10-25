import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_do_it/database/app_data_base.dart';
import 'package:lets_do_it/main.dart';
import 'package:lets_do_it/ui/task_analysis_screen.dart';
import 'package:lets_do_it/ui/task_detail_screen.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('App launches with title and bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(database: database));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('To-Do List'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('No tasks yet! Tap + to create one.'), findsOneWidget);

    // Allow drift stream timers to flush
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Can navigate to Add Task screen and create a task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(database: database));
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap the '+' floating action button
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify Add Task screen is shown
    expect(find.text('Add Task'), findsOneWidget);

    // Enter task details
    await tester.enterText(
      find.widgetWithText(TextField, 'Task Title'),
      'Test Task',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Task Description'),
      'Test Description',
    );

    // Tap Save Task button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Task'));
    await tester.pumpAndSettle();

    // Verify returned to home screen and task is visible
    expect(find.text('Test Task'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    // Allow drift stream timers to flush
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  test('Database cascade delete removes associated time logs', () async {
    final taskId = await database.insertTask(
      const TasksCompanion(
        title: drift.Value('Cascade Test Task'),
        isCompleted: drift.Value(false),
      ),
    );

    final now = DateTime.now();
    await database.into(database.taskTimeLogs).insert(
      TaskTimeLogsCompanion(
        taskId: drift.Value(taskId),
        startTime: drift.Value(now),
        endTime: drift.Value(now.add(const Duration(minutes: 5))),
      ),
    );

    var logs = await database.getTaskTimeLogs(taskId);
    expect(logs.length, 1);

    // Delete task
    await database.deleteTask(taskId);

    // Verify time logs are cascaded
    logs = await database.getTaskTimeLogs(taskId);
    expect(logs, isEmpty);
  });

  testWidgets('Task Detail Screen allows editing task and updating UI', (
    WidgetTester tester,
  ) async {
    final taskId = await database.insertTask(
      const TasksCompanion(
        title: drift.Value('Initial Title'),
        description: drift.Value('Initial Desc'),
        isCompleted: drift.Value(false),
      ),
    );
    final task = (await database.getAllTasks()).firstWhere((t) => t.id == taskId);

    await tester.pumpWidget(MaterialApp(
      home: TaskDetailScreen(database: database, task: task),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Task: Initial Title'), findsOneWidget);
    expect(find.text('Description: Initial Desc'), findsOneWidget);

    // Tap Edit
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Change title and description
    await tester.enterText(
      find.widgetWithText(TextField, 'Task Title'),
      'Updated Title',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Task Description'),
      'Updated Desc',
    );

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify updated on screen
    expect(find.text('Task: Updated Title'), findsOneWidget);
    expect(find.text('Description: Updated Desc'), findsOneWidget);

    // Verify updated in database
    final updatedInDb = await database.getAllTasks();
    expect(updatedInDb.first.title, 'Updated Title');
    expect(updatedInDb.first.description, 'Updated Desc');
  });

  testWidgets('Timer starts, stops, and saves time logs cleanly', (
    WidgetTester tester,
  ) async {
    final taskId = await database.insertTask(
      const TasksCompanion(
        title: drift.Value('Timer Task'),
        isCompleted: drift.Value(false),
      ),
    );
    final task = (await database.getAllTasks()).firstWhere((t) => t.id == taskId);

    await tester.pumpWidget(MaterialApp(
      home: TaskDetailScreen(database: database, task: task),
    ));
    await tester.pumpAndSettle();

    // Start timer
    await tester.tap(find.text('Start Timer'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Stop Timer'), findsOneWidget);

    // Stop timer
    await tester.tap(find.text('Stop Timer'));
    await tester.pumpAndSettle();

    expect(find.text('Start Timer'), findsOneWidget);

    // Verify time log exists in DB
    final logs = await database.getTaskTimeLogs(taskId);
    expect(logs, isNotEmpty);
    expect(logs.first.endTime, isNotNull);
  });

  testWidgets('Insights screen renders without errors', (
    WidgetTester tester,
  ) async {
    final taskId = await database.insertTask(
      const TasksCompanion(
        title: drift.Value('Insights Task'),
        isCompleted: drift.Value(false),
      ),
    );

    final now = DateTime.now();
    await database.into(database.taskTimeLogs).insert(
      TaskTimeLogsCompanion(
        taskId: drift.Value(taskId),
        startTime: drift.Value(now.subtract(const Duration(minutes: 30))),
        endTime: drift.Value(now),
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: AnalysisScreen(database: database),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Analysis & Insights'), findsOneWidget);
    expect(find.text('Insights Task'), findsWidgets);
  });
}
