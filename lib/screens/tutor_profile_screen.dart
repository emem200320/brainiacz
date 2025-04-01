//lib/screens/tutor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../providers/tutor_provider.dart';
import '../services/session_service.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';
import 'dart:async'; // Add this import for StreamSubscription

class TutorProfileScreen extends StatefulWidget {
  final String? tutorId;
  
  const TutorProfileScreen({this.tutorId, super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tutorData;
  Map<String, dynamic>? _ratingsData;
  final SessionService _sessionService = SessionService();
  late bool _isViewingOwnProfile;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _ratingsStream;

  @override
  void initState() {
    super.initState();
    _isViewingOwnProfile = widget.tutorId == null || 
                         widget.tutorId == _auth.currentUser?.uid;
    _loadTutorData();
  }
  
  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed
    _ratingsStream?.cancel();
    super.dispose();
  }

  Future<void> _loadTutorData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final userId = widget.tutorId ?? _auth.currentUser?.uid;
      
      if (userId == null) {
        throw 'User ID not available';
      }
      
      if (kDebugMode) {
        print("Loading tutor profile for $userId");
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw 'User profile not found';
      }
      
      // Get the user data and verify they are a tutor
      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role']?.toString().toLowerCase();
      
      if (userRole != 'tutor') {
        throw 'This user is not a tutor';
      }
      
      if (kDebugMode) {
        print("User data successfully loaded: ${userData.keys.toList()}");
        
        // Specifically print rating information for debugging
        print("TUTOR DEBUG - Rating: ${userData['rating']}");
        print("TUTOR DEBUG - AverageRating: ${userData['averageRating']}");
        print("TUTOR DEBUG - RatingCount: ${userData['ratingCount']}");
      }
      
      // Check if the user is viewing their own profile
      _isViewingOwnProfile = userId == _auth.currentUser?.uid;
      
      // If the user is viewing their own profile, load additional data
      if (_isViewingOwnProfile) {
      }
      
      // Direct query to Firestore ratings collection for the most accurate, current ratings
      try {
        final QuerySnapshot ratingSnapshot = await _firestore
          .collection('ratings')
          .where('tutorId', isEqualTo: userId)
          .get();
          
        if (ratingSnapshot.docs.isNotEmpty) {
          // Calculate the average rating directly from the ratings collection
          double ratingSum = 0.0;
          for (var doc in ratingSnapshot.docs) {
            final ratingData = doc.data() as Map<String, dynamic>;
            ratingSum += (ratingData['rating'] as num).toDouble();
          }
          
          final int directRatingCount = ratingSnapshot.docs.length;
          final double directAverageRating = directRatingCount > 0 ? 
              ratingSum / directRatingCount : 0.0;
              
          // Make sure we have the ratings in the userData
          userData['ratingCount'] = directRatingCount;
          userData['averageRating'] = directAverageRating;
          userData['rating'] = directAverageRating;
          
          if (kDebugMode) {
            print("DIRECT RATING CALCULATION: count=$directRatingCount, average=$directAverageRating");
          }
          
          // Update the rating in Firestore to ensure consistency
          await _firestore.collection('users').doc(userId).update({
            'ratingCount': directRatingCount,
            'averageRating': directAverageRating,
            'rating': directAverageRating,
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error calculating direct ratings: $e");
        }
      }

      // Update the state with the tutor data
      if (mounted) {
        setState(() {
          _tutorData = userData;
          _isLoading = false;
        });
      }
      
      // Load ratings data after tutor profile is loaded
      _loadRatingsData(userId);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading profile data: $e");
      }
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRatingsData(String userId) async {
    if (kDebugMode) {
      print("LOADING RATINGS DATA for userId: $userId");
    }

    try {
      // Use the SessionService to get detailed ratings information
      final ratingsData = await _sessionService.getTutorRatings(userId);
      
      if (kDebugMode) {
        print("Fetched ratings data: $ratingsData");
        // ignore: unnecessary_null_comparison
        print("RATINGS DEBUG - Has ratings data? ${ratingsData != null}");
        print("RATINGS DEBUG - Average rating: ${ratingsData['averageRating']}");
        print("RATINGS DEBUG - Rating count: ${ratingsData['ratingCount']}");
        print("RATINGS DEBUG - Detailed ratings: ${ratingsData['detailedRatings']}");
      }
      
      // Update the tutor data with the latest ratings info
      if (_tutorData != null) {
        // Get the latest average rating
        double avgRating = (ratingsData['averageRating'] as num?)?.toDouble() ?? 0.0;
        int ratingCount = (ratingsData['ratingCount'] as int?) ?? 0;
        
        // Update both rating and averageRating to ensure consistency
        if (avgRating > 0 && ratingCount > 0) {
          // Update local state
          setState(() {
            _tutorData!['rating'] = avgRating;
            _tutorData!['averageRating'] = avgRating;
            _tutorData!['ratingCount'] = ratingCount;
          });
          
          // Update Firestore to ensure data consistency
          await _firestore.collection('users').doc(userId).update({
            'rating': avgRating,
            'averageRating': avgRating,
            'ratingCount': ratingCount,
          });
          
          if (kDebugMode) {
            print("Updated user profile with latest rating data: $avgRating ($ratingCount ratings)");
          }
        }
      }
      
      setState(() {
        _ratingsData = ratingsData;
      });
      
      // Subscribe to real-time ratings updates
      _ratingsStream = _firestore
        .collection('ratings')
        .where('tutorId', isEqualTo: userId)
        .snapshots()
        .listen((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            // Calculate the average rating directly from the ratings collection
            double ratingSum = 0.0;
            for (var doc in querySnapshot.docs) {
              final ratingData = doc.data();
              ratingSum += (ratingData['rating'] as num).toDouble();
            }
            
            final int directRatingCount = querySnapshot.docs.length;
            final double directAverageRating = directRatingCount > 0 ? 
                ratingSum / directRatingCount : 0.0;
                
            // Update the tutor data with the latest ratings info
            if (_tutorData != null) {
              setState(() {
                _tutorData!['rating'] = directAverageRating;
                _tutorData!['averageRating'] = directAverageRating;
                _tutorData!['ratingCount'] = directRatingCount;
              });
            }
          }
        });
    } catch (e) {
      if (kDebugMode) {
        print("Error loading ratings data: $e");
      }
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ratings: $e')),
      );
      
      setState(() {
        _ratingsData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Tutor Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Add a refresh button to manually reload data
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Force reload both tutor data and ratings
              _loadTutorData();
              
              // Show a snackbar to confirm refresh
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing profile data...')),
              );
            },
          ),
          if (_isViewingOwnProfile) 
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final updatedData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(tutorData: _tutorData),
                  ),
                );
                
                // Check if we received updated data
                if (updatedData != null && updatedData is Map<String, dynamic>) {
                  // Update the local data immediately for a responsive UI
                  setState(() {
                    // Preserve the existing tutorData but update with new values
                    _tutorData = {
                      ..._tutorData!,
                      ...updatedData,
                    };
                  });
                  
                  if (kDebugMode) {
                    print("Profile updated with returned data: $updatedData");
                  }
                  
                  // Also refresh from Firestore to ensure everything is in sync
                  _loadTutorData();
                } else {
                  // If no data returned (e.g., user canceled), still refresh to be safe
                  _loadTutorData();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tutorData == null
              ? Center(child: Text('No profile data found'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header with Image
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Image
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue[100],
                              backgroundImage: _tutorData!['profileImageUrl'] != null
                                  ? NetworkImage(_tutorData!['profileImageUrl'])
                                  : null,
                              child: _tutorData!['profileImageUrl'] == null
                                  ? Icon(Icons.person, size: 60, color: Colors.blue[800])
                                  : null,
                            ),
                            SizedBox(height: 16),
                            
                            // Name
                            Text(
                              _tutorData!['name'] ?? 'Name not available',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            // Rating summary - show for all users (including tutor's own profile)
                            _buildRatingSection(),
                          ],
                        ),
                      ),
                      
                      // Detailed ratings
                      if (_ratingsData != null && _ratingsData!['detailedRatings'] != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildDetailedRatings(),
                        ),
                      
                      // Profile Details
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                              Icons.mail,
                              'Email',
                              _tutorData!['email'] ?? 'Not available',
                            ),
                            _buildDetailItem(
                              Icons.book,
                              'Subjects',
                              (_tutorData!['subjects'] as List<dynamic>?)
                                      ?.join(', ') ??
                                  'Not specified',
                            ),
                            _buildDetailItem(
                              Icons.attach_money,
                              'Hourly Rate',
                              _tutorData!['hourlyRate'] != null
                                  ? '₱${_tutorData!['hourlyRate']}'
                                  : 'Not specified',
                            ),
                          ],
                        ),
                      ),
                      
                      // Education and Experience Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Education
                            _buildDetailItem(
                              Icons.school,
                              'Education',
                              _tutorData!['education'] ?? 'Not specified',
                            ),
                            Divider(),
                            // Experience
                            _buildDetailItem(
                              Icons.work,
                              'Experience',
                              _tutorData!['experience'] ?? 'Not specified',
                            ),
                          ],
                        ),
                      ),
                      
                      // Bio Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Me',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _tutorData!['bio'] ?? 'No bio available',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Toggle Availability Button
                      if (_isViewingOwnProfile)
                        Container(
                          margin: EdgeInsets.all(16),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              _tutorData!['isAvailable'] == true
                                  ? Icons.toggle_on
                                  : Icons.toggle_off,
                            ),
                            label: Text(
                              _tutorData!['isAvailable'] == true
                                  ? 'Set as Unavailable'
                                  : 'Set as Available',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _tutorData!['isAvailable'] == true
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            onPressed: () async {
                              try {
                                final tutorProvider = Provider.of<TutorProvider>(context, listen: false);
                                await tutorProvider.updateAvailability(!(_tutorData!['isAvailable'] ?? false));
                                _loadTutorData(); // Refresh data
                              } catch (e) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating availability: $e')),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[700], size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    // Get the rating from either the detailed ratings data or directly from tutor data
    double averageRating = 0.0;
    
    // First try to get the rating from the detailed ratings data (most accurate)
    if (_ratingsData != null && _ratingsData!.containsKey('averageRating')) {
      averageRating = (_ratingsData!['averageRating'] as num).toDouble();
      if (kDebugMode) {
        print("Using rating from _ratingsData: $averageRating");
      }
    } 
    // Fallback to the rating in the tutor profile if available
    else if (_tutorData != null) {
      // Try all possible field names where rating might be stored
      if (_tutorData!.containsKey('averageRating') && _tutorData!['averageRating'] != null) {
        averageRating = (_tutorData!['averageRating'] as num).toDouble();
        if (kDebugMode) {
          print("Using rating from averageRating field: $averageRating");
        }
      } else if (_tutorData!.containsKey('rating') && _tutorData!['rating'] != null) {
        averageRating = (_tutorData!['rating'] as num).toDouble();
        if (kDebugMode) {
          print("Using rating from rating field: $averageRating");
        }
      }
    }
    
    // Check if we have detailed ratings data
    final hasDetailedData = _ratingsData != null;
    final uniqueStudents = hasDetailedData ? (_ratingsData!['uniqueStudentCount'] ?? 0) : 0;
    final sessionCount = hasDetailedData ? (_ratingsData!['sessionCount'] ?? 0) : 0;
    final ratingCount = hasDetailedData ? (_ratingsData!['ratingCount'] ?? 0) : 
                        (_tutorData != null ? (_tutorData!['ratingCount'] as int?) ?? 0 : 0);
    
    if (kDebugMode) {
      print("RATING SECTION DEBUG - Final rating value: $averageRating, count: $ratingCount");
      if (averageRating == 0.0) {
        print("WARNING: Rating is still 0.0 - checking why:");
        if (_tutorData != null) {
          print("_tutorData contents: ${_tutorData!.keys.toList()}");
          print("averageRating field: ${_tutorData!['averageRating']}");
          print("rating field: ${_tutorData!['rating']}");
        } else {
          print("_tutorData is null");
        }
      }
    }
    
    // Only show ratings if there are actual ratings (greater than 0)
    if (averageRating <= 0 || ratingCount <= 0) {
      return SizedBox.shrink(); // Return empty container when no real ratings exist
    }
    
    return Column(
      children: [
        // Star Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 4),
            Text(
              '${averageRating.toStringAsFixed(1)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '($ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        // Session and student count - only show if we have data
        if (hasDetailedData && (sessionCount > 0 || uniqueStudents > 0))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sessions count
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined, size: 16, color: Colors.blue[700]),
                      SizedBox(width: 4),
                      Text(
                        '$sessionCount ${sessionCount == 1 ? 'Session' : 'Sessions'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8),
                
                // Unique students
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: Colors.green[700]),
                      SizedBox(width: 4),
                      Text(
                        '$uniqueStudents ${uniqueStudents == 1 ? 'Student' : 'Students'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailedRatings() {
    final detailedRatings = _ratingsData!['detailedRatings'] as List<dynamic>;
    
    if (detailedRatings.isEmpty) {
      // Empty container - no "No ratings yet" text
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Student Ratings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // List of ratings
        ...detailedRatings.map((ratingData) {
          final rating = ratingData['rating'] as int? ?? 0;
          final studentName = ratingData['studentName'] as String? ?? 'Anonymous Student';
          final timestamp = ratingData['timestamp'] as Timestamp?;
          
          // Format date
          String formattedDate = 'Recently';
          if (timestamp != null) {
            final date = timestamp.toDate();
            formattedDate = DateFormat('MMM d, yyyy').format(date);
          }
          
          return Card(
            margin: EdgeInsets.only(bottom: 10),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with rating and student name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Student name
                      Expanded(
                        child: Text(
                          studentName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Rating as stars
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: index < rating ? Colors.amber : Colors.grey[300],
                              size: 16,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 6),
                  
                  // Date
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}