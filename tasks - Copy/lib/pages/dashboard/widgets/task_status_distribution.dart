import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_provider.dart';

class TaskStatusDistribution extends StatefulWidget {
  const TaskStatusDistribution({super.key});

  @override
  State<TaskStatusDistribution> createState() => _TaskStatusDistributionState();
}

class _TaskStatusDistributionState extends State<TaskStatusDistribution>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Start the animation once
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(15),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with icon and title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Status Distribution',
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
              final completedTasks = taskProvider.completedTasks;
              final inProgressTasks = taskProvider.inProgressTasks;
              final todoTasks = taskProvider.todoTasks;
              final totalTasks = completedTasks + inProgressTasks + todoTasks;

              // Debug print to check task counts
              debugPrint('Task Status Distribution:');
              debugPrint('Completed: $completedTasks');
              debugPrint('In Progress: $inProgressTasks');
              debugPrint('To Do: $todoTasks');
              debugPrint('Total: $totalTasks');

              // Calculate percentages
              final completedPercentage = totalTasks > 0
                  ? (completedTasks / totalTasks * 100).round()
                  : 0;
              final inProgressPercentage = totalTasks > 0
                  ? (inProgressTasks / totalTasks * 100).round()
                  : 0;
              final todoPercentage =
                  totalTasks > 0 ? (todoTasks / totalTasks * 100).round() : 0;

              return SizedBox(
                height: 300,
                child: totalTasks > 0
                    ? Column(
                        children: [
                          // Pie Chart with grow animation
                          SizedBox(
                            height: 200,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    startDegreeOffset: 270, // Start from top
                                    sections: [
                                      PieChartSectionData(
                                        color: const Color(0xff22c55e), // Green for completed
                                        value: completedTasks.toDouble(),
                                        title: '',
                                        radius: 80 * _animationController.value,
                                        showTitle: false,
                                        badgePositionPercentageOffset: 0.9,
                                        badgeWidget: _touchedIndex == 0 
                                            ? _buildBadge('Completed', const Color(0xff22c55e))
                                            : null,
                                        titlePositionPercentageOffset: 0.55,
                                        borderSide: _touchedIndex == 0
                                            ? const BorderSide(color: Colors.white, width: 2)
                                            : BorderSide.none,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(0xfff97316), // Orange for in progress
                                        value: inProgressTasks.toDouble(),
                                        title: '',
                                        radius: 80 * _animationController.value,
                                        showTitle: false,
                                        badgePositionPercentageOffset: 0.9,
                                        badgeWidget: _touchedIndex == 1
                                            ? _buildBadge('In Progress', const Color(0xfff97316))
                                            : null,
                                        titlePositionPercentageOffset: 0.55,
                                        borderSide: _touchedIndex == 1
                                            ? const BorderSide(color: Colors.white, width: 2)
                                            : BorderSide.none,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(0xff3b82f6), // Blue for to do
                                        value: todoTasks.toDouble(),
                                        title: '',
                                        radius: 80 * _animationController.value,
                                        showTitle: false,
                                        badgePositionPercentageOffset: 0.9,
                                        badgeWidget: _touchedIndex == 2
                                            ? _buildBadge('To Do', const Color(0xff3b82f6))
                                            : null,
                                        titlePositionPercentageOffset: 0.55,
                                        borderSide: _touchedIndex == 2
                                            ? const BorderSide(color: Colors.white, width: 2)
                                            : BorderSide.none,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Legend items in a wrap for better responsiveness
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildLegendItem(
                                  'Completed $completedPercentage%',
                                  const Color(0xff22c55e),
                                  _touchedIndex == 0,
                                ),
                                _buildLegendItem(
                                  'In Progress $inProgressPercentage%',
                                  const Color(0xfff97316),
                                  _touchedIndex == 1,
                                ),
                                _buildLegendItem(
                                  'To Do $todoPercentage%',
                                  const Color(0xff3b82f6),
                                  _touchedIndex == 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'No tasks available',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Build a badge for the pie chart sections
  Widget? _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Build a legend item with improved styling
  Widget _buildLegendItem(String text, Color color, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withAlpha(40) : color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : color.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}
