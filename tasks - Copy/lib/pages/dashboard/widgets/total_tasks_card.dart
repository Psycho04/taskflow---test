import 'package:flutter/material.dart';

class TotalTasksCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const TotalTasksCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 2.6,
            spreadRadius: 0,
            offset: Offset(
              1.95,
              1.95,
            ),
          ),
        ],
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
