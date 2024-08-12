import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/errorMessage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:logger/logger.dart';

class VocabularyChapter extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted;

  const VocabularyChapter({required this.data, required this.onExerciseAttempted, super.key});
  
  @override
  State<VocabularyChapter> createState() => _VocabularyChapterState();
}

class _VocabularyChapterState extends State<VocabularyChapter> {
  Logger logger = Logger();
  List<dynamic> vocabulary = [];
  String title = '';
  int currentIndex = 0;
  bool showTranslation = false;

  @override
  void initState() {
    super.initState();
    vocabulary = widget.data['vocabulary'];
    title = widget.data['title'];
    _addWordsToUserVocabulary(Provider.of<UserProvider>(context, listen: false));
  }

  Future<void> _addWordsToUserVocabulary(UserProvider userProvider) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.e('User not logged in');
      return;
    }

    final userVocabularyRef = FirebaseFirestore.instance.collection(
        'users/${user.uid}/vocabulary/${userProvider.activeLanguage}/vocabulary');

    for (var wordPair in vocabulary) {
      if (wordPair is Map<String, dynamic> &&
          wordPair.containsKey('word') &&
          wordPair.containsKey('meaning')) {
        try {
          // Query for existing documents with the same entry
          QuerySnapshot existingDocs = await userVocabularyRef
              .where('entry', isEqualTo: wordPair['word'])
              .limit(1)
              .get();

          if (existingDocs.docs.isNotEmpty) {
            // If a document with this entry exists, update it
            await existingDocs.docs.first.reference.update({
              'translation': wordPair['meaning'],
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            // If no document with this entry exists, create a new one
            await userVocabularyRef.add({
              'entry': wordPair['word'],
              'translation': wordPair['meaning'],
              'timestamp': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          logger.e('Error adding/updating word in user vocabulary: $e');
          _showErrorDialog(context, 'Error updating vocabulary. Please try again.');
        }
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return ErrorMessage(message: message);
      },
    );
  }

  Future<void> _nextCard(UserProvider userProvider) async {
    // Check if the user has enough hearts to proceed
    if (!(await userProvider.progressService.checkHeartsAndProceed(context))) {
      return; // Stop if the user doesn't have enough hearts
    }

    setState(() {
      if (currentIndex < vocabulary.length - 1) {
        currentIndex++;
      } else {
        // Update stars and score if it's the first time completing the chapter
        currentIndex = 0; // Loop back to the first card if needed
      }

      if (currentIndex == vocabulary.length - 1) {
        if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
          userProvider.updateStars(3); // Assume full stars for completing all cards
          userProvider.updateScore(5); // Update score by 5 points for the exercise completion
        }
        widget.onExerciseAttempted(true); // Notify completion when all cards are viewed
      }

      showTranslation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Progress: ${currentIndex + 1}/${vocabulary.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Center(
            child: Card(
              elevation: 5,
              child: Container(
                width: 300,
                height: 200,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vocabulary[currentIndex]['word'],
                        style: const TextStyle(fontSize: 24, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        vocabulary[currentIndex]['meaning'],
                        style: const TextStyle(fontSize: 20, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (vocabulary[currentIndex]['example'] != null)
                          Text(
                          vocabulary[currentIndex]['example'],
                          style:
                              const TextStyle(fontSize: 16, color: Colors.black),
                          textAlign: TextAlign.center,
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: ElevatedButton.icon(
            onPressed: () => _nextCard(userProvider),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
