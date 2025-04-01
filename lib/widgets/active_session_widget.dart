// lib/widgets/active_session_widget.dart
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

class ActiveSessionWidget extends StatelessWidget {
  final SessionModel session;
  final Function() onEndSession;
  final String? currentUserId;
  
  const ActiveSessionWidget({
    super.key,
    required this.session,
    required this.onEndSession,
    this.currentUserId,
  });
  
  @override
  Widget build(BuildContext context) {
    final sessionService = SessionService();
    
    return StreamBuilder<Duration>(
      stream: sessionService.sessionTimerStream,
      initialData: session.remainingTime,
      builder: (context, snapshot) {
        final Duration remaining = snapshot.data ?? session.remainingTime;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active Session',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    sessionService.formatDuration(remaining),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: remaining.inMinutes < 5 ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.play_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Session is active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: onEndSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('End Session'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
