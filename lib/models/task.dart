import 'package:flutter/material.dart';

class Task {
  String taskName;
  bool isDone;
  DateTime creationTime;
  DateTime actionDate; // Neues Attribut für das Datum der letzten Aktion

  Task({
    required this.taskName,
    required this.isDone,
    required this.creationTime,
    required this.actionDate,
  });

  Task.fromMap(String task)
      : this.taskName = task.split('|')[0],
        this.isDone = task.split('|')[1] == 'true',
        this.creationTime = DateTime.parse(task.split('|')[2]),
        this.actionDate = DateTime.parse(task.split('|')[3]);

  String toMap() {
    return '$taskName|${isDone.toString()}|${creationTime.toIso8601String()}|${actionDate.toIso8601String()}';
  }

  Color getTaskColor() {
    DateTime now = DateTime.now();
    DateTime actionDate = this.actionDate;

    if (now.difference(actionDate).inDays >= 1) {
      return Colors.red;
    } else if (now.difference(actionDate).inHours >= 1) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
