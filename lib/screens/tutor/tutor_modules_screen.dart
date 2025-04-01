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
        title: Text('Edit Module'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editSubjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: editLevelController,
                decoration: InputDecoration(
                  labelText: 'Year/Grade/Level',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: editLinkController,
                decoration: InputDecoration(
                  labelText: 'Module Link',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Module Form
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add New Module',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a subject'
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _levelController,
                        decoration: InputDecoration(
                          labelText: 'Year/Grade/Level',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a level'
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _linkController,
                        decoration: InputDecoration(
                          labelText: 'Module Link (Google Drive)',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your Google Drive link',
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a link'
                            : null,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addModule,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Add Module'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Modules List
            Text(
              'My Modules',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
                    child: Text('No modules added yet'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final module = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          module['subject'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(module['level']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(
                                snapshot.data!.docs[index].id,
                                module,
                              ),
                            ),
                            Icon(Icons.expand_more),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Module Link:'),
                                SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _launchURL(module['link']),
                                  child: Text(
                                    module['link'],
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
