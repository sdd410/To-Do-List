# Debug Analysis and Architecture Fixes

This document records the issues identified in the **To-Do-List** application, the root causes, the technical decisions made, and the verification steps taken.

---

## 1. Summary of Issues Found

When analyzing and executing the project, the application suffered from issues across database initialization, state management, test suites, and package dependencies:

| Category | Issue | Impact |
| :--- | :--- | :--- |
| **Dependencies** | `flutter pub get` uninitialized & `drift_dev` missing | Over 900 analyzer errors due to unresolved symbols; `build_runner` had no builder for Drift. |
| **Database** | Invalid column names in SQLite CHECK constraint | Table creation failed with `SqliteException(1): no such column: endTime`. |
| **Database** | Foreign keys disabled by default in SQLite | Cascade delete did not trigger, or failed with `FOREIGN KEY constraint failed`. |
| **UI / State** | Task edit did not update `TaskDetailScreen` UI | Saving task changes updated the database but the UI kept showing stale task details. |
| **Memory / Concurrency** | Timer leaked in `TaskDetailScreen` without `dispose()` | `setState()` called indefinitely after screen disposal, causing continuous console errors and memory leak. |
| **Analysis / Chart** | Millisecond epochs used as bar chart X indices | Bar chart x-coordinates in the trillions (~1.79e12) broke interval calculations in `fl_chart`. |
| **Analysis / Chart** | Task duration truncated to 0 for short intervals | Durations under 1 minute resulted in `0.0` hours and invisible bars. |
| **Tests** | Default counter test present in `test/widget_test.dart` | `flutter test` failed immediately on launch. |
| **Platform** | CocoaPods missing for macOS/iOS desktop runners | `flutter run -d macos` fails because CocoaPods is not installed on the host. |

---

## 2. Detailed Technical Root Causes & Fixes Applied

### A. SQLite Table Initialization Failure (`lib/database/task_time_log.dart`)
- **Root Cause**: The table defined `CHECK (endTime IS NULL OR endTime > startTime)`. Drift maps Dart field names `startTime` and `endTime` to SQLite column names `start_time` and `end_time`. SQLite failed during `CREATE TABLE` with `no such column: endTime`. Furthermore, the strict `>` rejected immediate timer stops.
- **Fix**:
  1. Updated constraint to `CHECK (end_time IS NULL OR end_time >= start_time)`.
  2. Replaced the raw SQL foreign key string with type-safe Drift API:
     ```dart
     IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
     ```
  3. Added `drift_dev: ^2.26.0` to `pubspec.yaml` and regenerated Drift database files with `build_runner`.

### B. Foreign Key Enforcement & Cascading Deletes (`lib/database/app_data_base.dart`)
- **Root Cause**: SQLite disables foreign keys by default unless `PRAGMA foreign_keys = ON;` is executed on connection open.
- **Fix**:
  1. Added `MigrationStrategy` in `AppDatabase` to run `PRAGMA foreign_keys = ON;` in `beforeOpen`.
  2. Updated `deleteTask(int id)` to explicitly delete associated `taskTimeLogs` before deleting the task.
  3. Added an optional `QueryExecutor? executor` parameter to `AppDatabase` to support in-memory SQLite (`NativeDatabase.memory()`) during automated tests.

### C. Task Edit State Invalidation (`lib/ui/task_detail_screen.dart`)
- **Root Cause**: `TaskDetailScreen` rendered `widget.task.title` and `widget.task.description`. When `_updateTask()` wrote changes to the database, `widget.task` remained unchanged, so the UI continued displaying the old title and description.
- **Fix**:
  1. Added stateful variable `late Task _currentTask` initialized to `widget.task`.
  2. Updated `_currentTask` upon database update.
  3. Bound title and description displays to `_currentTask`.

### D. Timer Leak and Post-Dispose `setState` (`lib/ui/task_detail_screen.dart`)
- **Root Cause**: `_TaskDetailScreenState` had no `dispose()` method. When navigating back while the timer was active, `Timer.periodic` continued firing every second, calling `setState()` on a defunct element. Text controllers were also never disposed.
- **Fix**:
  1. Implemented `dispose()` cancelling `_timer` and disposing `_titleController` and `_descriptionController`.
  2. Added `mounted` checks before calling `setState()` or `Navigator.pop()`.
  3. Added `PopScope` to guarantee timer cancellation when the user navigates back.

### E. Analysis & Bar Chart Calculations (`lib/ui/task_analysis_screen.dart`)
- **Root Cause**:
  1. `DropdownButton<Task>` used task object equality; updates to tasks caused dropdown value mismatch assertions in Flutter.
  2. `log.endTime!.difference(log.startTime).inMinutes / 60.0` resulted in `0.0` for any duration under 60 seconds.
  3. `x: entry.key.millisecondsSinceEpoch` created huge index intervals in `fl_chart`.
- **Fix**:
  1. Changed dropdown value to `int? selectedTaskId`.
  2. Auto-selects the first available task when opening Insights.
  3. Changed duration calculation to `.inSeconds / 3600.0`.
  4. Mapped dates to sequential integers `0, 1, 2, ...` for `BarChartGroupData.x`, and looked up corresponding dates in `bottomTitles.getTitlesWidget`.
  5. Enhanced tooltip formatting: displays minutes if duration is `< 0.1h`, otherwise decimal hours.

### F. Screen Cleanliness and Validation (`lib/ui/add_task_screen.dart`, `lib/ui/home_screen.dart`)
- **Add Task**: Added input validation preventing blank tasks with user feedback (SnackBar) and disposed controllers.
- **Home Screen**: Added empty state text (`No tasks yet! Tap + to create one.`) when the list is empty, and added vertical padding to task tiles.

### G. Test Suite Overhaul (`test/widget_test.dart`)
- **Fix**: Replaced the boilerplate counter test with 6 test cases:
  1. App launch with title, bottom navigation, and empty state.
  2. Navigating to Add Task, inputting text, and creating a task.
  3. SQLite cascading delete of associated time logs.
  4. Task editing and UI reflection.
  5. Timer start, periodic tick, stop, and database persistence.
  6. Insights screen rendering with chart data.

---

## 3. Host Platform Notes

If attempting to run natively on macOS or iOS:
- **macOS / iOS CocoaPods**: CocoaPods is not currently installed on the host system (`brew install cocoapods`). `sqlite3_flutter_libs` and `path_provider` require CocoaPods for macOS/iOS builds.
- **ARM Rosetta**: Flutter doctor advises running `sudo softwareupdate --install-rosetta --agree-to-license` for x86 compatibility.

---

## 4. Verification

The fixes were validated via automated test and analysis suites:
- **`dart analyze`**: Passed with 0 issues (`No issues found!`).
- **`flutter test`**: All 6 tests passed in 2 seconds (`All tests passed!`).
