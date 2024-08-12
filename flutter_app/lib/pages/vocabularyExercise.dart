import 'package:flutter/material.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:logger/web.dart';
import '../components/alertMessage.dart';
import 'package:provider/provider.dart';
import '../components/scoreMessage.dart';
import 'package:logger/logger.dart';
import 'dart:math';

class VocabularyExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted;

  const VocabularyExercise({required this.data, required this.onExerciseAttempted, super.key});

  @override
  State<VocabularyExercise> createState() => _VocabularyExerciseState();
}

class _VocabularyExerciseState extends State<VocabularyExercise> {
  Logger logger = Logger();
  String title = '';
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _userAnswers = [];
  List<dynamic> answers = [];
  List<dynamic> shuffledAnswers = [];
  List<dynamic> words = [];
  int wrongSubmissions = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    title = widget.data['title'];
    answers = widget.data['answers'];
    words = widget.data['words'];
    _userAnswers = List.filled(words.length, null);
    _shuffleAnswers();
  }

  void _shuffleAnswers() {
    shuffledAnswers = List.from(answers);
    shuffledAnswers.shuffle(Random());
  }

  Future<void> _submitAnswers(BuildContext context, UserProvider userProvider) async {
    // Heart check method from ProgressService
    if (!await userProvider.progressService.checkHeartsAndProceed(context)) {
      return; // Exit if the user doesn't have enough hearts
    }

    // Proceed with the answer submission logic if the user has enough hearts
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      bool allCorrect = true;

      for (int i = 0; i < answers.length; i++) {
        if (answers[i] != _userAnswers[i]) {
          allCorrect = false;
          break;
        }
      }

      if (allCorrect) {
        score = wrongSubmissions == 0 ? 3 : (wrongSubmissions == 1 ? 2 : 1);
        if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
          await userProvider.updateStars(score); // Update stars with the current chapter ID
          await userProvider.updateScore(5); // Update score by 5 points for the exercise completion
        }
        widget.onExerciseAttempted(true); // Notify success
        _showResultDialog(context, true);
      } else {
        wrongSubmissions++;
        userProvider.updateHearts(-1);
        widget.onExerciseAttempted(false); // Notify failure
        _showResultDialog(context, false);
      }
    }
  }

  void _showResultDialog(BuildContext context, bool correct) {
    showDialog(
      context: context,
      builder: (context) {
        return correct
            ? ScoreMessage(title: title, score: score)
            : const AlertMessage(
                message: 'Some answers are incorrect. Please try again.',
                title: 'Incorrect',
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: _buildCombinedList(),
                ),
              ),
              const SizedBox(height: 16),
              _buildDraggableAnswers(shuffledAnswers),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () => _submitAnswers(context, userProvider),
                child: const Text('Submit', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildCombinedList() {
    return Card(
      elevation: 4,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: words.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    words[index],
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: _userAnswers[index] != null ? Colors.blue.shade50 : Colors.grey.shade100,
                        ),
                        child: Center(
                          child: _userAnswers[index] != null
                              ? Text(
                                  _userAnswers[index]!,
                                  style: const TextStyle(fontSize: 18),
                                )
                              : const Text(
                                  'Drop answer here',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                        ),
                      );
                    },
                    onAcceptWithDetails: (data) {
                      setState(() {
                        _userAnswers[index] = data.data;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraggableAnswers(List<dynamic> shuffledAnswers) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: shuffledAnswers.map((answer) {
        return Draggable<String>(
          data: answer,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                answer,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          childWhenDragging: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: Text(
              answer,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }).toList(),
    );
  }
}