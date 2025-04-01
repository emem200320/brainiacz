//lib/screens/student_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainiacz/services/firestore_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

class StudentProfileScreen extends StatefulWidget {
  final String? studentId;

  const StudentProfileScreen({
    super.key, 
    this.studentId, // Optional student ID to view other student's profile
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isViewingOtherProfile = false;
  
  @override
  void initState() {
    super.initState();
    _isViewingOtherProfile = widget.studentId != null && 
                             widget.studentId != _auth.currentUser?.uid;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final studentId = widget.studentId ?? _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isViewingOtherProfile ? 'Student Profile' : 'My Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading && !_isViewingOtherProfile)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: firestoreService.getUser(studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load profile', style: GoogleFonts.poppins(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Try Again'),
                  )
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Error message when viewing another student's profile that doesn't exist
            if (_isViewingOtherProfile) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Student profile not found', style: GoogleFonts.poppins(fontSize: 18)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Go Back'),
                    )
                  ],
                ),
              );
            }
            
            // Create a new user profile if none exists (only for own profile)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text('Let\'s set up your profile', style: GoogleFonts.poppins(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Initialize with Firebase Auth data
                      _nameController.text = _auth.currentUser?.displayName ?? '';
                      _emailController.text = _auth.currentUser?.email ?? '';
                      setState(() {});
                    },
                    child: Text('Create Profile'),
                  )
                ],
              ),
            );
          }

          final userData = snapshot.data!;
          // Only set controllers if they're empty (to avoid losing user edits)
          if (_nameController.text.isEmpty) {
            _nameController.text = userData['name'] ?? _auth.currentUser?.displayName ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = userData['email'] ?? _auth.currentUser?.email ?? '';
          }
          if (_bioController.text.isEmpty) {
            _bioController.text = userData['bio'] ?? '';
          }
          if (_gradeController.text.isEmpty) {
            _gradeController.text = userData['grade'] ?? '';
          }

          // For viewing other student's profile - show limited info
          if (_isViewingOtherProfile) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile Icon
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: userData['profileImageUrl'] != null && 
                                           userData['profileImageUrl'].isNotEmpty ? 
                                           NetworkImage(userData['profileImageUrl']) : null,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: userData['profileImageUrl'] == null || 
                                  userData['profileImageUrl'].isEmpty ? 
                                  Icon(Icons.person, size: 60, color: Colors.white) : null,
                          ),
                          
                          const SizedBox(height: 16),
                          Text(
                            userData['name'] ?? 'Student',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (userData['grade'] != null && userData['grade'].isNotEmpty)
                            Text(
                              'Grade/Year: ${userData['grade']}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Bio Section
                    if (userData['bio'] != null && userData['bio'].isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userData['bio'],
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          // Original UI for viewing own profile
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Icon (static, no upload functionality)
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                        
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _emailController.text,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          
                          // Name Field
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            readOnly: true, // Email should be read-only as it's linked to auth
                          ),
                          const SizedBox(height: 16),
                          
                          // Grade/Year Level
                          TextField(
                            controller: _gradeController,
                            decoration: InputDecoration(
                              labelText: 'Grade/Year Level',
                              prefixIcon: const Icon(Icons.school),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Bio Field
                          TextField(
                            controller: _bioController,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveProfile(firestoreService, studentId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _saveProfile(FirestoreService firestoreService, String studentId) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print("Saving profile for student: $studentId");
      }
      
      await firestoreService.updateProfile(
        userId: studentId,
        name: _nameController.text,
        email: _emailController.text,
        additionalData: {
          'bio': _bioController.text,
          'grade': _gradeController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // Update Firebase Auth display name
      if (_auth.currentUser != null && _auth.currentUser!.displayName != _nameController.text) {
        await _auth.currentUser!.updateDisplayName(_nameController.text);
      }
      
      if (kDebugMode) {
        print("Profile updated successfully for student: $studentId");
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error updating profile: $e");
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}