import 'package:flutter/material.dart';
import 'widgets/task_overview_section.dart';
import 'widgets/priority_chart_section.dart';
import 'widgets/recent_tasks_section.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TaskOverviewSection(),
            SizedBox(height: 20),
            PriorityChartSection(),
            SizedBox(height: 20),
            RecentTasksSection(),
          ],
        ),
      );
  }
} 