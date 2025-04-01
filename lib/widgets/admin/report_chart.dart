// lib/widgets/admin/report_chart.dart
import 'package:flutter/material.dart';

class ReportChart extends StatelessWidget {
  final String title;
  final int value;

  const ReportChart({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18)),
            Text('$value', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}