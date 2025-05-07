import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_provider.dart';

class RecentTasksSection extends StatelessWidget {
  const RecentTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.list_alt,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Task Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.grey.shade200,
                  height: 1,
                ),
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    final recentTasks = taskProvider.recentTasks;

                    if (recentTasks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('No tasks'),
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(recentTasks.length, (index) {
                        final task = recentTasks[index];
                        IconData priorityIcon;
                        Color priorityColor;

                        switch (task.priority.toLowerCase()) {
                          case 'high':
                            priorityIcon = Icons.keyboard_double_arrow_up;
                            priorityColor = const Color(0xffef4444);
                            break;
                          case 'medium':
                            priorityIcon = Icons.keyboard_arrow_up;
                            priorityColor = const Color(0xfff59e0b);
                            break;
                          case 'low':
                            priorityIcon = Icons.keyboard_arrow_down;
                            priorityColor = const Color(0xff10b981);
                            break;
                          default:
                            priorityIcon = Icons.remove;
                            priorityColor = Colors.grey;
                        }

                        return Column(
                          children: [
                            _buildTaskRow(
                              taskTitle: task.title,
                              priority: task.priority,
                              icon: priorityIcon,
                              priorityColor: priorityColor,
                            ),
                            if (index < recentTasks.length - 1)
                              Divider(
                                color: Colors.grey.shade200,
                                height: 1,
                              ),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow({
    required String taskTitle,
    required String priority,
    required IconData icon,
    required Color priorityColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              taskTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: priorityColor.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: priorityColor,
                ),
                const SizedBox(width: 4),
                Text(
                  priority,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
