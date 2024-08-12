import 'package:flutter/material.dart';
import 'package:flutter_app/components/alertMessage.dart';
import 'package:flutter_app/components/scoreMessage.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class ConjugationPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted; // used to pass the result back to Chapter

  const ConjugationPage({required this.data, required this.onExerciseAttempted, super.key});

  @override
  ConjugationPageState createState() => ConjugationPageState();
}

class ConjugationPageState extends State<ConjugationPage> {
  Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _answers = <String>[];
  List<dynamic> pronouns = ['', '', '', '', '', ''];
  String title = 'Loading...';
  List<dynamic> answers = ['', '', '', '', '', ''];
  int wrongSubmissions = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    title = widget.data['title'];
    pronouns = widget.data['content'];
    answers = widget.data['answers'];
  }

  Future<void> _submitAnswers(UserProvider userProvider) async {
    final progressService = userProvider.progressService;

    // Check if the user has enough hearts to proceed
    if (!(await progressService.checkHeartsAndProceed(context))) {
      return; // Stop the submission if the user doesn't have enough hearts
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      bool allCorrect = true;
      for (int i = 0; i < answers.length; i++) {
        // Validate using ProgressService
        bool isCorrect = await progressService.validateExercise(_answers[i], answers[i]);
        if (!isCorrect) {
          allCorrect = false;
          break;
        }
      }

      if (allCorrect) {
        score = wrongSubmissions == 0 ? 3 : (wrongSubmissions == 1 ? 2 : 1);
        if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
          await userProvider.updateStars(score); // Update stars for the current chapter
          await userProvider.updateScore(5); // Update score for exercise completion
        }

        widget.onExerciseAttempted(true); // Notify Chapter of success
        _showResultDialog(true);
      } else {
        wrongSubmissions++;
        await userProvider.updateHearts(-1); // Deduct a heart for incorrect submission
        widget.onExerciseAttempted(false); // Notify Chapter of failure
        _showResultDialog(false);
      }
    }
  }

  void _showResultDialog(bool correct) {
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
    // Get the user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 25),
              _buildConjugationField(pronouns[0], 0),
              _buildConjugationField(pronouns[1], 1),
              _buildConjugationField(pronouns[2], 2),
              _buildConjugationField(pronouns[3], 3),
              _buildConjugationField(pronouns[4], 4),
              _buildConjugationField(pronouns[5], 5),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () => _submitAnswers(userProvider),
                    child: const Text('Submit', style: TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConjugationField(String label, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        width: 350,
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onSaved: (value) {
            if (_answers.length > index) {
              _answers[index] = value!;
            } else {
              _answers.add(value!);
            }
          },
          validator: (value) => value!.isEmpty ? 'Please enter a word' : null,
        ),
      ),
    );
  }
}
