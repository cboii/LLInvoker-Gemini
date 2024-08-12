/* 
* This service handles all user progress and scoring logic within the language learning app.
* It provides methods for validating exercise submissions, updating user scores, tracking
* chapter completion, and managing the user's progress throughout the course.
* By centralizing this logic, the ProgressService promotes code modularity, making it easier
* to maintain, test, and extend the app's functionality in the future.
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:flutter/material.dart';

class ProgressService {
  final UserProvider userProvider;

  ProgressService(this.userProvider);

  Future<bool> validateExercise(String userAnswer, String correctAnswer) async {
    // Logic to validate the exercise
    return userAnswer == correctAnswer;
  }

  Future<void> updateProgress(DocumentReference chapterRef) async {
    if (!userProvider.progress.contains(chapterRef)) {
      await userProvider.updateProgress(chapterRef);
    }
  }

  Future<void> updateScore(int points) async {
    await userProvider.updateScore(points);
  }

  Future<bool> checkAndEnableNextChapter(DocumentReference currentChapterRef, bool isExerciseAttempted, bool isExerciseCorrect) async {
    // Ensure the exercise was attempted and was correct
    if (isExerciseAttempted && isExerciseCorrect) {
        return true;
    }
    return false;
  }

  Future<void> resetProgress(String courseId, String level) async {
    // Logic to reset the progress for a course/level
    // This could be useful for allowing users to restart a course or chapter
  }

  Future<bool> checkHeartsAndProceed(BuildContext context) async {
    if (userProvider.hearts < 1) {
      _showNoHeartsDialog(context);
      return false;
    }
    return true;
  }

  void _showNoHeartsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Not Enough Hearts'),
          content: const Text('You do not have enough hearts to continue. Please try again later or refill your hearts.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}