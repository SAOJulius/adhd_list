import 'package:flutter/material.dart';
import 'screens/to_do_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo List',
      theme: ThemeData.dark().copyWith(
        hintColor: Colors.teal,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.teal),
        ),
      ),
      home: ToDoList(),
    );
  }
}
