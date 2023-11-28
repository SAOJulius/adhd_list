// screens/to_do_list.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'archive_page.dart';
import '../models/task.dart';
import 'package:pdf/widgets.dart' as pw;

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  List<Task> tasks = [];
  List<Task> archivedTasks = [];
  late SharedPreferences prefs;
  late Timer archiveTimer;

  TextEditingController taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTasks();
    loadArchivedTasks();
    startTimer();
  }

  Future<void> loadTasks() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? taskList = prefs.getStringList('tasks');

    if (taskList != null) {
      setState(() {
        tasks = taskList.map((task) => Task.fromMap(task)).toList();
        tasks.sort((a, b) {
          return a.taskName.toLowerCase().compareTo(b.taskName.toLowerCase()); // Alphabetische Sortierung ohne Beachtung der Groß- und Kleinschreibung
        });
      });
    } else {
      setState(() {
        tasks = [];
      });
    }
  }

  Future<void> loadArchivedTasks() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? archivedTaskList = prefs.getStringList('archivedTasks');

    if (archivedTaskList != null) {
      setState(() {
        archivedTasks = archivedTaskList.map((task) => Task.fromMap(task)).toList();
      });
    } else {
      setState(() {
        archivedTasks = [];
      });
    }
  }


  Future<void> saveTasks() async {
    List<String> taskList = tasks.map((task) => task.toMap()).toList();
    await prefs.setStringList('tasks', taskList);
    loadTasks();
  }

  Future<void> saveArchivedTasks() async {
    List<String> archivedTaskList = archivedTasks.map((task) => task.toMap()).toList();
    await prefs.setStringList('archivedTasks', archivedTaskList);
  }

  void startTimer() {
    const oneMinute = const Duration(minutes: 1);
    archiveTimer = Timer.periodic(oneMinute, (timer) async {
      await moveToArchive();
    });
  }

  Future<void> moveToArchive() async {
    setState(() {
      List<Task> completedTasks = tasks.where((task) => task.isDone).toList();
      tasks.removeWhere((task) => task.isDone);
      saveTasks();

      archivedTasks.addAll(completedTasks);
      saveArchivedTasks();
    });
  }

  Color getTaskColor(Task task) {
    DateTime now = DateTime.now();
    DateTime taskTime = task.creationTime;
    if (now.difference(taskTime).inMinutes >= 2) {
      return Colors.red;
    } else if (now.difference(taskTime).inMinutes >= 1) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Future<void> printTasksAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Header(text: 'To-Do List'),
            for (Task task in tasks)
              pw.Row(
                children: [
                  pw.Text(task.taskName),
                  pw.Spacer(),
                  pw.Text(
                    task.isDone ? 'Completed' : 'Open',
                    style: pw.TextStyle(color: task.isDone ? PdfColors.grey : PdfColors.black),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    final Uint8List bytes = await pdf.save();

    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'tasks_${DateTime.now().toString().split(' ')[0]}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: tasks[index].getTaskColor(),
                    ),
                    child: Card(
                      elevation: 3.0,
                      child: ListTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: tasks[index].isDone,
                              onChanged: (value) {
                                setState(() {
                                  tasks[index].isDone = value!;
                                  saveTasks();
                                });
                              },
                            ),
                            Text(
                              tasks[index].taskName,
                              style: TextStyle(
                                color: tasks[index].isDone ? Colors.grey : Colors.white,
                                decoration: tasks[index].isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  tasks.removeAt(index);
                                  saveTasks();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: taskController,
                onSubmitted: (value) {
                  setState(() {
                    tasks.add(Task(
                      taskName: value,
                      isDone: false,
                      creationTime: DateTime.now(),
                    ));
                    saveTasks();
                    taskController.clear();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Enter a new task',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() async {
                        tasks.add(Task(
                          taskName: taskController.text,
                          isDone: false,
                          creationTime: DateTime.now(),
                        ));
                        saveTasks();
                        taskController.clear();
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ArchivePage()),
              );
            },
            child: Icon(Icons.archive),
            backgroundColor: Colors.teal,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              await printTasksAsPdf();
            },
            child: Icon(Icons.print),
            backgroundColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    archiveTimer.cancel();
    super.dispose();
  }
}
