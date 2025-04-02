import 'package:flutter/material.dart';
import 'package:lets_do_it/database/app_data_base.dart';
import 'package:lets_do_it/ui/home_screen.dart';

void main() {
  final database = AppDatabase();
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;
  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "To-Do List",
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.pink[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.pink[200],
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.pink[900]),
          bodyMedium: TextStyle(color: Colors.pink[700]),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.pinkAccent,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: HomeScreen(database: database),
      ),
    );
  }
}
