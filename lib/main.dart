import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    startTimer();
  }

  Future<void> loadTasks() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? taskList = prefs.getStringList('tasks');

    if (taskList != null) {
      setState(() {
        tasks = taskList.map((task) => Task.fromMap(task)).toList();
        // Sort tasks by color
        tasks.sort((a, b) {
          if (a.getTaskColor() == Colors.red && b.getTaskColor() == Colors.green) {
            return -1; // Red tasks first
          } else if (b.getTaskColor() == Colors.red && a.getTaskColor() == Colors.green) {
            return 1; // Green tasks last
          } else {
            return 0; // Both have the same color or other colors
          }
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

      // Archive completed tasks
      archivedTasks.addAll(completedTasks);
      saveArchivedTasks();
    });
  }

  Color getTaskColor(Task task) {
    DateTime now = DateTime.now();
    DateTime taskTime = task.creationTime;
    if (now.difference(taskTime).inMinutes >= 2) {
      return Colors.red; // Red after 2 minutes
    } else if (now.difference(taskTime).inMinutes >= 1) {
      return Colors.orange; // Orange after 1 minute
    } else {
      return Colors.green; // Green immediately
    }
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
                            Row(
                              children: List.generate(
                                3,
                                    (starIndex) => IconButton(
                                  icon: Icon(
                                    tasks[index].stars[starIndex] ? Icons.star : Icons.star_border,
                                    color: tasks[index].stars[starIndex] ? Colors.yellow : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      for (int i = 0; i <= starIndex; i++) {
                                        tasks[index].stars[i] = !tasks[index].stars[i];
                                      }
                                      saveTasks();
                                    });
                                  },
                                ),
                              ),
                            ),
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
                      stars: [false, false, false],
                    ));
                    saveTasks();
                    taskController.clear(); // Clear the text input field
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
                          stars: [false, false, false],
                        ));
                        saveTasks();
                        taskController.clear(); // Clear the text input field
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
    );
  }

  @override
  void dispose() {
    archiveTimer.cancel();
    super.dispose();
  }
}

class ArchivePage extends StatefulWidget {
  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late SharedPreferences prefs;
  late List<Task> archivedTasks;

  @override
  void initState() {
    super.initState();
    loadArchivedTasks();
  }

  Future<void> loadArchivedTasks() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? archivedTaskList = prefs.getStringList('archivedTasks');

    if (archivedTaskList != null) {
      setState(() {
        archivedTasks = archivedTaskList.map((task) => Task.fromMap(task)).toList();
        // Sort archived tasks by color
        archivedTasks.sort((a, b) {
          if (a.getTaskColor() == Colors.red && b.getTaskColor() == Colors.green) {
            return -1; // Red tasks first
          } else if (b.getTaskColor() == Colors.red && a.getTaskColor() == Colors.green) {
            return 1; // Green tasks last
          } else {
            return 0; // Both have the same color or other colors
          }
        });
      });
    } else {
      setState(() {
        archivedTasks = [];
      });
    }
  }

  Future<void> saveArchivedTasks() async {
    List<String> archivedTaskList = archivedTasks.map((task) => task.toMap()).toList();
    await prefs.setStringList('archivedTasks', archivedTaskList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archived Tasks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: archivedTasks.isEmpty
            ? Center(
          child: Text('No archived tasks.'),
        )
            : ListView.builder(
          itemCount: archivedTasks.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.grey, // Change this according to your preferences
              ),
              child: Card(
                elevation: 3.0,
                child: ListTile(
                  title: Text(
                    archivedTasks[index].taskName,
                    style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        archivedTasks.removeAt(index);
                        saveArchivedTasks();
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Task {
  String taskName;
  bool isDone;
  DateTime creationTime;
  List<bool> stars;

  Task({
    required this.taskName,
    required this.isDone,
    required this.creationTime,
    required this.stars,
  });

  Task.fromMap(String task)
      : this.taskName = task.split('|')[0],
        this.isDone = task.split('|')[1] == 'true',
        this.creationTime = DateTime.parse(task.split('|')[2]),
        this.stars = task.split('|')[3].split(',').map((star) => star == 'true').toList();

  String toMap() {
    return '$taskName|${isDone.toString()}|${creationTime.toIso8601String()}|${stars.join(',')}';
  }

  Color getTaskColor() {
    DateTime now = DateTime.now();
    if (now.difference(creationTime).inMinutes >= 2) {
      return Colors.red; // Red after 2 minutes
    } else if (now.difference(creationTime).inMinutes >= 1) {
      return Colors.orange; // Orange after 1 minute
    } else {
      return Colors.green; // Green immediately
    }
  }
}
