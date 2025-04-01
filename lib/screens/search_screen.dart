//lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tutor_provider.dart';
import '../widgets/tutor_card.dart';

class SearchScreen extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorProvider = Provider.of<TutorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Find Tutors'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by subject or tutor name',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    tutorProvider.searchTutors(_searchController.text);
                  },
                ),
              ),
              onChanged: (query) {
                tutorProvider.searchTutors(query);
              },
            ),
          ),
          Expanded(
            child: tutorProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : tutorProvider.tutors.isEmpty
                    ? Center(child: Text('No tutors found.'))
                    : ListView.builder(
                        itemCount: tutorProvider.tutors.length,
                        itemBuilder: (context, index) {
                          final tutor = tutorProvider.tutors[index];
                          return TutorCard(
                            name: tutor['name'],
                            subjects: List<String>.from(tutor['subjects'] ?? []),
                            rating: tutor['rating'] ?? 0.0,
                            onTap: () {
                              Navigator.pushNamed(context, '/tutorDetails', arguments: tutor);
                            },
                            subject: _searchController.text,
                            specialtySubject: tutor['specialtySubject'],
                            hadSessionWithCurrentStudent: tutor['hadSessionWithCurrentStudent'] ?? false,
                            uniqueStudentCount: tutor['uniqueStudentCount'] ?? 0,
                            onRequest: () {
                              // Navigate to request session screen
                              Navigator.pushNamed(
                                context, 
                                '/requestSession',
                                arguments: tutor,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}