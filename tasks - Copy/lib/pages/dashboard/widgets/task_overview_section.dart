import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_provider.dart';

class TaskOverviewSection extends StatelessWidget {
  const TaskOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Today\'s Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final allTasks = taskProvider.tasks;
              final completedTasks = allTasks.where((task) => task.stage.toLowerCase() == 'completed').length;
              final inProgressTasks = allTasks.where((task) => task.stage.toLowerCase() == 'inprogress').length;
              final todoTasks = allTasks.where((task) => task.stage.toLowerCase() == 'todo').length;

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTaskCard(
                    title: 'TASKS',
                    count: allTasks.length,
                    color: const Color(0xffdbeafe),
                    icon: Icons.apps,
                    iconColor: const Color(0xff3b82f6),
                  ),
                  _buildTaskCard(
                    title: 'COMPLETED',
                    count: completedTasks,
                    color: const Color(0xffdcfce7),
                    icon: Icons.task_alt,
                    iconColor: const Color(0xff22c55e),
                  ),
                  _buildTaskCard(
                    title: 'IN PROGRESS',
                    count: inProgressTasks,
                    color: const Color(0xffffedd5),
                    icon: Icons.pending_actions,
                    iconColor: const Color(0xfff97316),
                  ),
                  _buildTaskCard(
                    title: 'TO DO',
                    count: todoTasks,
                    color: const Color(0xfffce7f3),
                    icon: Icons.list_alt,
                    iconColor: const Color(0xffec4899),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: iconColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 