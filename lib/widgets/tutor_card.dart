// lib/widgets/tutor_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorCard extends StatelessWidget {
  final String name;
  final List<String> subjects;
  final double rating;
  final VoidCallback onTap;
  final VoidCallback onRequest;
  final String subject;
  final String? specialtySubject;
  final bool hadSessionWithCurrentStudent;
  final int uniqueStudentCount;
  final bool isAvailable;

  const TutorCard({
    super.key, 
    required this.name,
    required this.subjects,
    required this.rating,
    required this.onTap,
    required this.onRequest,
    required this.subject,
    this.specialtySubject,
    this.hadSessionWithCurrentStudent = false,
    this.uniqueStudentCount = 0,
    this.isAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort subjects to show specialty subject first if it matches the search
    List<String> sortedSubjects = List.from(subjects);
    final bool hasMatchingSpecialty = specialtySubject != null && 
                                    subject.toLowerCase() == specialtySubject!.toLowerCase();
    
    if (hasMatchingSpecialty) {
      sortedSubjects.remove(specialtySubject);
      sortedSubjects.insert(0, specialtySubject!);
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: hasMatchingSpecialty ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade400, width: 2),
      ) : null,
      child: Stack(
        children: [
          if (hasMatchingSpecialty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Specialist',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Add student count badge at the top right for specialists (under the specialist badge)
          if (hasMatchingSpecialty)
            Positioned(
              top: 40, // Positioned below the specialist badge
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '$uniqueStudentCount ${uniqueStudentCount == 1 ? 'student' : 'students'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          // Add student count badge at the top right for non-specialists
          if (!hasMatchingSpecialty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '$uniqueStudentCount ${uniqueStudentCount == 1 ? 'student' : 'students'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(name[0]),
                      radius: 24,
                      backgroundColor: hasMatchingSpecialty ? Colors.green.shade100 : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isAvailable ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                isAvailable ? 'Available' : 'Not Available',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isAvailable ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                // If student had previous sessions with this tutor, show a badge
                if (hadSessionWithCurrentStudent)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Previous session',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedSubjects.map((subj) {
                    final isSpecialty = hasMatchingSpecialty && 
                                    subj.toLowerCase() == specialtySubject!.toLowerCase();
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSpecialty ? Colors.green.shade50 : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: isSpecialty ? Border.all(color: Colors.green.shade400) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSpecialty) ...[
                            Icon(
                              Icons.workspace_premium,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 4),
                          ],
                          Text(
                            subj,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSpecialty ? FontWeight.w600 : FontWeight.normal,
                              color: isSpecialty ? Colors.green.shade700 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: onTap,
                      child: Text('View Profile'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onRequest,
                      child: Text('Request Tutor'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}