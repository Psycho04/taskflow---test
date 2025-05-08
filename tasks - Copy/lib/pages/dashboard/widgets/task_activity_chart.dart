import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/task_provider.dart';

class TaskActivityChart extends StatelessWidget {
  const TaskActivityChart({super.key});

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
                  Icons.timeline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Activity (Last 7 Days)',
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
              // Generate dates for the last 7 days
              final now = DateTime.now();
              final dates = List.generate(7, (index) {
                return DateTime(
                  now.year,
                  now.month,
                  now.day - (6 - index),
                );
              });

              // Get real task data from the task provider
              final allTasks = taskProvider.tasks;

              // Calculate tasks created per day for the last 7 days
              final createdTasksData = List.filled(7, 0);
              final completedTasksData = List.filled(7, 0);

              for (final task in allTasks) {
                // Check if the task was created in the last 7 days
                for (int i = 0; i < 7; i++) {
                  final date = dates[i];
                  final taskDate = DateTime(
                    task.date.year,
                    task.date.month,
                    task.date.day,
                  );

                  // Count tasks created on this date
                  if (taskDate.year == date.year &&
                      taskDate.month == date.month &&
                      taskDate.day == date.day) {
                    createdTasksData[i]++;
                  }

                  // Count tasks completed on this date (if status is 'Completed')
                  if (task.stage.toLowerCase() == 'completed' &&
                      taskDate.year == date.year &&
                      taskDate.month == date.month &&
                      taskDate.day == date.day) {
                    completedTasksData[i]++;
                  }
                }
              }

              return SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 3,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: _getDrawingLine,
                      getDrawingVerticalLine: _getDrawingLine,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= dates.length) {
                              return const SizedBox.shrink();
                            }
                            final date = dates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('E').format(date),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 3,
                          getTitlesWidget: _leftTitleWidgets,
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: _calculateMaxY(createdTasksData, completedTasksData),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.shade700,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final date = dates[spot.x.toInt()];
                            final dayName = DateFormat('E').format(date);
                            final value = spot.y.toInt();
                            final String tooltipText;

                            if (spot.barIndex == 0) {
                              tooltipText = 'Created Tasks : $value';
                            } else {
                              tooltipText = 'Completed Tasks : $value';
                            }

                            return LineTooltipItem(
                              '$dayName\n$tooltipText',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Created tasks line
                      LineChartBarData(
                        spots: List.generate(7, (index) {
                          return FlSpot(index.toDouble(),
                              createdTasksData[index].toDouble());
                        }),
                        isCurved: true,
                        color: const Color(0xff3b82f6), // Blue
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0x333b82f6),
                        ),
                      ),
                      // Completed tasks line
                      LineChartBarData(
                        spots: List.generate(7, (index) {
                          return FlSpot(index.toDouble(),
                              completedTasksData[index].toDouble());
                        }),
                        isCurved: true,
                        color: const Color(0xff22c55e), // Green
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0x3322c55e),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Completed Tasks', const Color(0xff22c55e)),
              const SizedBox(width: 24),
              _buildLegendItem('Created Tasks', const Color(0xff3b82f6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// Helper functions for chart styling
FlLine _getDrawingLine(double value) {
  return const FlLine(
    color: Color(0xFFE0E0E0),
    strokeWidth: 1,
  );
}

Widget _leftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Colors.grey,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  return Text(
    value.toInt().toString(),
    style: style,
    textAlign: TextAlign.left,
  );
}

// Calculate the maximum Y value for the chart based on actual data
double _calculateMaxY(List<int> createdData, List<int> completedData) {
  // Find the maximum value in both datasets
  int maxCreated =
      createdData.isNotEmpty ? createdData.reduce((a, b) => a > b ? a : b) : 0;
  int maxCompleted = completedData.isNotEmpty
      ? completedData.reduce((a, b) => a > b ? a : b)
      : 0;

  // Get the overall maximum
  int maxValue = maxCreated > maxCompleted ? maxCreated : maxCompleted;

  // Add some padding to the top of the chart (20%)
  double maxY = (maxValue * 1.2).ceilToDouble();

  // Ensure a minimum value for better visualization
  return maxY < 5 ? 5.0 : maxY;
}
