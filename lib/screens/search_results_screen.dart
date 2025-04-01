// lib/screens/search_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tutor_provider.dart';
import '../widgets/tutor_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchTutors();
  }

  Future<void> _searchTutors() async {
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);
    await tutorProvider.searchTutors(widget.searchQuery);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _sendTutorRequest(BuildContext context, String tutorId, String subject) {
    Navigator.pushNamed(
      context,
      '/requestForm',
      arguments: {
        'tutorId': tutorId,
        'subject': subject,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutorProvider = Provider.of<TutorProvider>(context);
    final tutors = tutorProvider.tutors;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.searchQuery}"'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found ${tutors.length} tutors for "${widget.searchQuery}"',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: tutors.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No tutors found for "${widget.searchQuery}"',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Try another search'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: tutors.length,
                            itemBuilder: (context, index) {
                              final tutor = tutors[index];
                              return TutorCard(
                                name: tutor['name'] ?? 'Tutor',
                                subjects: tutor['subjects'] != null
                                    ? List<String>.from(tutor['subjects'])
                                    : [],
                                rating: tutor['rating'] ?? 4.0,
                                onTap: () => Navigator.pushNamed(
                                  context, 
                                  '/tutorDetails',
                                  arguments: tutor,
                                ),
                                onRequest: () => _sendTutorRequest(
                                  context, 
                                  tutor['id'] ?? '', 
                                  widget.searchQuery,
                                ),
                                subject: widget.searchQuery,
                                specialtySubject: tutor['specialtySubject'],
                                uniqueStudentCount: tutor['uniqueStudentCount'] ?? 0,
                                hadSessionWithCurrentStudent: tutor['hadSessionWithCurrentStudent'] ?? false,
                                isAvailable: tutor['isAvailable'] ?? false,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
