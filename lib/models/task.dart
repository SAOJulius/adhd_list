import 'package:flutter/material.dart';

class Task {
  String taskName;
  bool isDone;
  DateTime creationTime;

  Task({
    required this.taskName,
    required this.isDone,
    required this.creationTime,
  });

  Task.fromMap(String task)
      : this.taskName = task.split('|')[0],
        this.isDone = task.split('|')[1] == 'true',
        this.creationTime = DateTime.parse(task.split('|')[2]);

  String toMap() {
    return '$taskName|${isDone.toString()}|${creationTime.toIso8601String()}';
  }

  Color getTaskColor() {
    DateTime now = DateTime.now();
    if (now.difference(creationTime).inMinutes >= 2) {
      return Colors.red;
    } else if (now.difference(creationTime).inMinutes >= 1) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}