//lib/screens/student/student_session_details_screen.dart
import 'package:brainiacz/models/request.dart';
import 'package:brainiacz/models/tutor.dart';
import 'package:brainiacz/providers/session_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class StudentSessionDetailsScreen extends StatelessWidget {
  final String sessionId;

  const StudentSessionDetailsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSessionDetails(sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load session details.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No session details found.'));
        }

        final request = snapshot.data!['request'] as Request;
        final tutor = snapshot.data!['tutor'] as Tutor;

        return Scaffold(
          appBar: AppBar(title: Text('Session Details')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tutor: ${tutor.name}', style: TextStyle(fontSize: 18)),
                Text('Subject: ${request.subjectId}', style: TextStyle(fontSize: 16)),
                Text('Date: ${request.sessionDate}', style: TextStyle(fontSize: 16)),
                Text('Time: ${request.sessionTime}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),

                // Display tutor's contact info if the request is accepted
                if (request.status == 'accepted') ...[
                  Text('Email: ${tutor.email}', style: TextStyle(fontSize: 16)),
                  Text('Phone: ${tutor.phone}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                ],

                ElevatedButton(
                  onPressed: () async {
                    try {
                      await sessionProvider.cancelSession(sessionId);
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Session cancelled successfully!')),
                      );
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context); // Go back to the previous screen
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to cancel session. Please try again.')),
                      );
                    }
                  },
                  child: Text('Cancel Session'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fetch session details and tutor information
  Future<Map<String, dynamic>> _fetchSessionDetails(String sessionId) async {
    try {
      // Fetch the session request
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(sessionId)
          .get();
      if (!requestDoc.exists) {
        throw 'Session not found.';
      }
      final request = Request.fromMap(requestDoc.data()!);

      // Fetch the tutor's details
      final tutorDoc = await FirebaseFirestore.instance
          .collection('tutors')
          .doc(request.tutorId)
          .get();
      if (!tutorDoc.exists) {
        throw 'Tutor not found.';
      }
      final tutor = Tutor.fromMap(tutorDoc.data()!);

      return {'request': request, 'tutor': tutor};
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching session details: $e");
      }
      throw "Failed to fetch session details.";
    }
  }
}