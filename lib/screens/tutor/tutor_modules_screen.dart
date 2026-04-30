import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ModuleSection extends StatefulWidget {
  @override
  _ModuleSectionState createState() => _ModuleSectionState();
}

class _ModuleSectionState extends State<ModuleSection> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _levelController = TextEditingController();
  final _linkController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _addModule() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = _auth.currentUser?.uid;
        await _firestore.collection('modules').add({
          'tutorId': userId,
          'subject': _subjectController.text,
          'level': _levelController.text,
          'link': _linkController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Clear form
        _subjectController.clear();
        _levelController.clear();
        _linkController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Module added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding module: $e')),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  void _showEditDialog(String moduleId, Map<String, dynamic> moduleData) {
    final editSubjectController =
        TextEditingController(text: moduleData['subject']);
    final editLevelController =
        TextEditingController(text: moduleData['level']);
    final editLinkController = TextEditingController(text: moduleData['link']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Module', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _darkTextField(editSubjectController, 'Subject', Icons.subject_rounded),
              const SizedBox(height: 16),
              _darkTextField(editLevelController, 'Year/Grade/Level', Icons.grade_rounded),
              const SizedBox(height: 16),
              _darkTextField(editLinkController, 'Module Link', Icons.link_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('modules').doc(moduleId).update({
                  'subject': editSubjectController.text,
                  'level': editLevelController.text,
                  'link': editLinkController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Module updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating module: $e')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
  Widget _darkTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF6C3FD8), size: 20),
        filled: true,
        fillColor: const Color(0xFF0A0A0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Module Form
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C3FD8).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add New Module',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextFormField(
                        controller: _subjectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          labelStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.subject_rounded, color: Color(0xFF6C3FD8), size: 20),
                          filled: true,
                          fillColor: const Color(0xFF0A0A0F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a subject'
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _levelController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Year/Grade/Level',
                          labelStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.grade_rounded, color: Color(0xFF6C3FD8), size: 20),
                          filled: true,
                          fillColor: const Color(0xFF0A0A0F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a level'
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _linkController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Module Link (Google Drive)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          hintText: 'Enter your Google Drive link',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                          prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF6C3FD8), size: 20),
                          filled: true,
                          fillColor: const Color(0xFF0A0A0F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a link'
                            : null,
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C3FD8).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _addModule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C3FD8),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Module',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Modules List
            const Text(
              'My Modules',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Stream of modules
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('modules')
                  .where('tutorId', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No modules added yet',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final module = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C3FD8).withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          iconColor: const Color(0xFF6C3FD8),
                          collapsedIconColor: Colors.white38,
                          title: Text(
                            module['subject'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            module['level'],
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Color(0xFF6C3FD8), size: 20),
                                onPressed: () => _showEditDialog(
                                  snapshot.data!.docs[index].id,
                                  module,
                                ),
                              ),
                              const Icon(Icons.expand_more, color: Colors.white38),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(color: Color(0xFF6C3FD8), thickness: 0.2),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Module Link:',
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _launchURL(module['link']),
                                    child: Text(
                                      module['link'],
                                      style: const TextStyle(
                                        color: Color(0xFFA78BFA),
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFFA78BFA),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _levelController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}
