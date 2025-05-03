import 'package:flutter/material.dart';

class TaskTitleRow extends StatelessWidget {
  final String taskTitle;
  final String priority;
  final IconData icon;
  final Color priorityColor;
  const TaskTitleRow(
      {super.key,
      required this.taskTitle,
      required this.priority,
      required this.icon,
      required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskTitle,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                    ),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                    ),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: priorityColor,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    priority,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )
          ],
        ),
        const Divider(
          thickness: 0.5,
        )
      ],
    );
  }
}
