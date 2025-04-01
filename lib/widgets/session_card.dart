//lib/widgets session_card.dart
import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final String studentName;
  final String tutorName;
  final String subject;
  final String date;
  final String time;
  final String status;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const SessionCard({super.key, 
    this.studentName = 'N/A',
    this.tutorName = 'N/A',
    required this.subject,
    required this.date,
    required this.time,
    required this.status,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(studentName != 'N/A' ? 'Session with $studentName' : 'Session with $tutorName'),
        subtitle: Text('$subject - $date $time'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'pending' && onAccept != null && onReject != null)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: onAccept,
              ),
            if (status == 'pending' && onAccept != null && onReject != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onReject,
              ),
            if (status == 'pending' && onCancel != null && onReschedule != null)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: onCancel,
              ),
            if (status == 'pending' && onCancel != null && onReschedule != null)
              IconButton(
                icon: const Icon(Icons.schedule, color: Colors.blue),
                onPressed: onReschedule,
              ),
            if (status == 'accepted')
              const Icon(Icons.check_circle, color: Colors.green),
            if (status == 'rejected')
              const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }
}