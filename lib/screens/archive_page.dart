import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

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
        archivedTasks.sort((a, b) {
          if (a.getTaskColor() == Colors.red && b.getTaskColor() == Colors.green) {
            return -1;
          } else if (b.getTaskColor() == Colors.red && a.getTaskColor() == Colors.green) {
            return 1;
          } else {
            return 0;
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
                color: archivedTasks[index].getTaskColor(),
              ),
              child: Card(
                elevation: 3.0,
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          archivedTasks[index].taskName,
                          style: TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            archivedTasks.removeAt(index);
                            saveArchivedTasks(); // Dieser Aufruf speichert die aktualisierte Liste in SharedPreferences
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
    );
  }
}