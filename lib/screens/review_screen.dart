//lib/screens/review_screen.dart
import 'package:flutter/material.dart';
import '../widgets/rating_widget.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave a Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('How was your session?', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            RatingWidget(rating: 0), // Initial rating
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Write a review',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Submit review
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Review submitted!')),
                );
              },
              child: Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}