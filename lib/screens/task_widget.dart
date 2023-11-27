import 'package:flutter/material.dart';


class TaskWidget extends StatelessWidget {
  final String taskName;
  final bool isDone;
  final void Function(bool?) onCheckboxChanged; // Updated this line
  final void Function() onDelete;

  const TaskWidget({
    Key? key,
    required this.taskName,
    required this.isDone,
    required this.onCheckboxChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: isDone ? Colors.grey : Colors.green,
      ),
      child: Card(
        elevation: 3.0,
        child: ListTile(
          title: Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: onCheckboxChanged,
              ),
              Text(
                taskName,
                style: TextStyle(
                  color: isDone ? Colors.grey : Colors.white,
                  decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
