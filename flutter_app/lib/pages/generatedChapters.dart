import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/pages/conjugationExercise.dart';
import 'package:flutter_app/pages/fillInTheBlankMutlipleChoice.dart';
import 'package:flutter_app/pages/theory.dart';
import 'package:flutter_app/pages/fillInTheBlank.dart';
import 'package:flutter_app/pages/vocabularyExercise.dart';
import 'package:flutter_app/pages/readingExercise.dart';
import 'package:flutter_app/pages/questionAnswerExercise.dart';
import 'package:flutter_app/pages/vocabularyChapter.dart';
import 'package:flutter_app/pages/verbConjugation.dart';
import 'package:flutter_app/pages/writingExercise.dart';
import 'package:flutter_app/utils/exercise_utils.dart';


class ExercisePageWrapper extends StatelessWidget {
  final Widget child;

  const ExercisePageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          iconSize: 40,
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: child,
    );
  }
}

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}


class Library extends StatefulWidget {
  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allDocuments = [];
  List<DocumentSnapshot> _filteredDocuments = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  void _fetchDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users/${user.uid}/generatedChapters')
          .get();

      setState(() {
        _allDocuments = querySnapshot.docs;
        _filteredDocuments = _allDocuments;
      });
    }
  }

  void _filterDocuments(String query) {
    setState(() {
      _filteredDocuments = _allDocuments.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] as String? ?? '';
        final content = data['content'] as String? ?? '';
        return title.toLowerCase().contains(query.toLowerCase()) ||
            content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'My Library',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
              Container(
                height: 2,
                width: 200,
                color: Colors.blue,
                margin: const EdgeInsets.only(top: 4),
              ),
            ],
          ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Vocabulary',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      _filterDocuments(value);
                    },
                  ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDocuments.length,
              itemBuilder: (context, index) {
                final doc = _filteredDocuments[index];
                final data = doc.data() as Map<String, dynamic>;
                return ExerciseCard(
                  data: data,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ExerciseCard({Key? key, required this.data}) : super(key: key);

  void _navigateToExercise(BuildContext context, Map<String, dynamic> data) async {
    int type = data['type'] ?? -1; // Get the type from data, with a fallback

    // Use the getExercisePageWidget function to generate the appropriate widget
    Widget exercisePage = getExercisePageWidget(
      type: type,
      data: data,
      onExerciseAttempted: (success) {
        // Handle exercise attempt logic here, e.g., show a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Exercise completed!' : 'Exercise not completed')),
        );
      },
    );

    // Navigate to the selected exercise page using the custom page route
    Navigator.push(
      context,
      CustomPageRoute(child: ExercisePageWrapper(child: exercisePage)),
    );
  }

  String get typeString {
    switch (data['type']) {
      case 0:
        return 'Informational';
      case 1:
        return 'Fill-in-the-Blank';
      case 2:
        return 'Conjugation Exercise';
      case 3:
        return 'Fill-in-the-Blank Multiple Choice';
      case 4:
        return 'Vocabulary Matching';
      case 5:
        return 'Reading';
      case 6:
        return 'Question and Answer';
      case 7:
        return 'Vocabulary';
      case 8:
        return 'Conjugation';
      case 9:
        return 'Writing';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(data['title']),
        subtitle: Text(typeString, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () async {
          _navigateToExercise(context, data);
        },
      ),
    );
  }
}
