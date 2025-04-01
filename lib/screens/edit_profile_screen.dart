//lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brainiacz/providers/tutor_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? tutorData;
  const EditProfileScreen({Key? key, required this.tutorData}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _subjectsController;
  late TextEditingController _rateController;
  late TextEditingController _educationController;
  late TextEditingController _experienceController;
  late TextEditingController _specialtySubjectController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tutorData?['name'] ?? '');
    _emailController = TextEditingController(text: widget.tutorData?['email'] ?? '');
    _bioController = TextEditingController(text: widget.tutorData?['bio'] ?? '');
    _subjectsController = TextEditingController(text: widget.tutorData?['subjects'] != null
        ? (widget.tutorData!['subjects'] is List 
            ? (widget.tutorData!['subjects'] as List).join(', ')
            : widget.tutorData!['subjects'].toString())
        : '');
    _rateController = TextEditingController(text: widget.tutorData?['hourlyRate']?.toString() ?? '');
    _educationController = TextEditingController(text: widget.tutorData?['education'] ?? '');
    _experienceController = TextEditingController(text: widget.tutorData?['experience'] ?? '');
    _specialtySubjectController = TextEditingController(text: widget.tutorData?['specialtySubject'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _subjectsController.dispose();
    _rateController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _specialtySubjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const Text(
                        'Edit Your Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter your email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.description,
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your bio' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _subjectsController,
                  label: 'Subjects (comma separated)',
                  icon: Icons.book,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter at least one subject' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _educationController,
                  label: 'Education',
                  icon: Icons.school,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your education' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _experienceController,
                  label: 'Experience',
                  icon: Icons.work,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your experience' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _specialtySubjectController,
                  label: 'Specialty Subject',
                  icon: Icons.star,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your specialty subject' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _rateController,
                  label: 'Hourly Rate (₱)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter your hourly rate';
                    if (double.tryParse(value!) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tutorProvider = Provider.of<TutorProvider>(context, listen: false);
      
      double hourlyRate = double.tryParse(_rateController.text) ?? 0.0;
      List<String> subjects = _subjectsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      await tutorProvider.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        bio: _bioController.text,
        subjects: subjects,
        education: _educationController.text,
        experience: _experienceController.text,
        hourlyRate: hourlyRate,
        specialtySubject: _specialtySubjectController.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      
      final updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        'subjects': subjects,
        'education': _educationController.text,
        'experience': _experienceController.text,
        'hourlyRate': hourlyRate,
        'specialtySubject': _specialtySubjectController.text,
      };
      
      Navigator.pop(context, updatedData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }
}