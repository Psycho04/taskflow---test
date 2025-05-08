import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import 'widgets/widgets.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    // Refresh dashboard data when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).refreshDashboardData();
    });
  }

  Future<void> _refreshDashboard() async {
    await Provider.of<TaskProvider>(context, listen: false)
        .refreshDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        physics: AlwaysScrollableScrollPhysics(),
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
            TaskStatusDistribution(),
            SizedBox(height: 20),
            PriorityChartSection(),
            SizedBox(height: 20),
            TaskActivityChart(),
          ],
        ),
      ),
    );
  }
}
