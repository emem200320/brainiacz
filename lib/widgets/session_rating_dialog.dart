// lib/widgets/session_rating_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SessionRatingDialog extends StatefulWidget {
  final String tutorId;
  final String sessionId;
  final String sessionDuration;
  final Function(int) onRatingSubmitted;

  const SessionRatingDialog({
    Key? key,
    required this.tutorId,
    required this.sessionId,
    required this.sessionDuration,
    required this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<SessionRatingDialog> createState() => _SessionRatingDialogState();
}

class _SessionRatingDialogState extends State<SessionRatingDialog> {
  int _rating = 5; // Default to 5 stars
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismiss by back button
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rate Your Tutor'),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              splashRadius: 24,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Session Ended',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Display session duration
              Text(
                'Duration: ${widget.sessionDuration}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Rating text
              const Text(
                'Rate your tutor',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.star,
                        size: 40,
                        color:
                            index < _rating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _isSubmitting = true;
                          });

                          try {
                            widget.onRatingSubmitted(_rating);
                            if (kDebugMode) {
                              print('Rating submitted: $_rating stars');
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print('Error submitting rating: $e');
                            }
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
