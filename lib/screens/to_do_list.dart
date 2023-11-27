import 'dart:async';
import 'dart:typed_data';

import 'package:adhd_list/screens/task_widget.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
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
    loadArchivedTasks(); // Füge diese Zeile hinzu
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

      // Füge die abgeschlossenen Aufgaben zum Archiv hinzu
      archivedTasks.addAll(completedTasks);

      // Speichere die Aufgaben im Archiv
      saveArchivedTasks();
      // Speichere die offenen Aufgaben
      saveTasks();
    });
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
                    task.isDone ? 'Completed' : '[ ]',
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
                  final task = tasks[index];
                  return TaskWidget(
                    taskName: task.taskName,
                    isDone: task.isDone,
                    onCheckboxChanged: (value) {
                      setState(() {
                        task.isDone = value!;
                        saveTasks();
                      });
                    },
                    onDelete: () {
                      setState(() {
                        tasks.removeAt(index);
                        saveTasks();
                      });
                    },
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
                      setState(() {
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
              await moveToArchive();
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

