// lib/screens/tutor_details_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brainiacz/screens/tutor_modules_view_screen.dart';

class TutorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tutor;

  const TutorDetailsScreen({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    // Extract tutor data with null safety
    final String name = tutor['name'] ?? 'Tutor';
    final List<String> subjects =
        tutor['subjects'] != null ? List<String>.from(tutor['subjects']) : [];
    final double rating = tutor['rating'] ?? 4.0;
    final String bio = tutor['bio'] ?? 'No bio available for this tutor.';
    final String education = tutor['education'] ?? 'Not specified';
    final String experience = tutor['experience'] ?? 'Not specified';
    final dynamic rate = tutor['rate'] ?? tutor['hourlyRate'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tutor Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Tutor Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'T',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tutor Name
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : (index < rating)
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tutor Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subjects
                  _buildSectionTitle('Subjects'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects
                        .map((subject) => Chip(
                              label: Text(subject),
                              backgroundColor: Colors.blue.shade100,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Bio
                  _buildSectionTitle('About'),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Education
                  _buildSectionTitle('Education'),
                  const SizedBox(height: 8),
                  _buildDetailItem(Icons.school, education),
                  const SizedBox(height: 24),

                  // Experience
                  _buildSectionTitle('Experience'),
                  const SizedBox(height: 8),
                  _buildDetailItem(Icons.work, experience),
                  const SizedBox(height: 24),

                  // Hourly Rate
                  _buildSectionTitle('Hourly Rate'),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                      Icons.attach_money,
                      rate != null && rate > 0
                          ? '₱${rate.toString()}/hour'
                          : 'Not specified'),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      // Request Tutor Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () =>
                                _showRequestDialog(context, tutor['id'] ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Request Tutor',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Space between buttons
                      // Modules Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TutorModulesViewScreen(
                                    tutorId: tutor['id'] ?? '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Modules',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _showRequestDialog(BuildContext context, String tutorId) {
    final String subject =
        tutor['subjects'] != null && tutor['subjects'].isNotEmpty
            ? tutor['subjects'][0]
            : 'General';

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Request'),
        content: Text('Would you like to send a request to this tutor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // Navigate to the request form screen
              Navigator.pushNamed(
                context,
                '/requestForm',
                arguments: {
                  'tutorId': tutorId,
                  'tutorName': tutor['name'],
                  'subject': subject,
                },
              );
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
}
