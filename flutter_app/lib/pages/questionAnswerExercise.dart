import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../components/alertMessage.dart';
import '../providers/userProvider.dart';

class QuestionAnswerExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted;

  const QuestionAnswerExercise({required this.data, required this.onExerciseAttempted, super.key});

  @override
  State<QuestionAnswerExercise> createState() => _QuestionAnswerExerciseState();
}

class _QuestionAnswerExerciseState extends State<QuestionAnswerExercise> {
  final functions = FirebaseFunctions.instance;
  Logger logger = Logger();
  final TextEditingController _answerController1 = TextEditingController();
  final TextEditingController _answerController2 = TextEditingController();
  final TextEditingController _answerController3 = TextEditingController();
  final TextEditingController _answerController4 = TextEditingController();

  String text = "";
  List<dynamic> questions = [];
  List<dynamic> references = [];
  int wrongSubmissions = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    text = widget.data['content'];
    questions = widget.data['questions'];
    references = widget.data['references'];
  }

  // Check if the answers are correct
  Future<void> _sendAnswers(UserProvider userProvider) async {
    // Check if the user has enough hearts to proceed
    if (!(await userProvider.progressService.checkHeartsAndProceed(context))) {
      return; // Stop the submission if the user doesn't have enough hearts
    }

    var qa = {
      'text': text,
      'question1': questions[0],
      'question2': questions[1],
      'question3': questions[2],
      'answer1': _answerController1.text,
      'answer2': _answerController2.text,
      'answer3': _answerController3.text,
      'reference1': references[0],
      'reference2': references[1],
      'reference3': references[2],
    };

    final response = await functions.httpsCallable('questionAnswerExercise')(qa);
    if (response.data['error'] != null) {
      // Error handling
      logger.e('Failed to send answers: ${response.data}');
      if (mounted){
        showDialog(
          context: context,
          builder: (context) => AlertMessage(message: response.data['error'], title: 'Error'),
        );
      }
    } else
    if (response.data != null) {
      // Successfully sent
      bool correct = response.data['result'];
      if (mounted) {
        if (correct) {
          score = wrongSubmissions == 0 ? 3 : (wrongSubmissions == 1 ? 2 : 1);
          if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
            await userProvider.updateStars(score);
            await userProvider.updateScore(5);
          }
          widget.onExerciseAttempted(true); // Notify success
          _showResultDialog(true, response);
        } else {
          wrongSubmissions++;
          await userProvider.updateHearts(-1); // Deduct a heart for incorrect submission
          widget.onExerciseAttempted(false); // Notify failure
          _showResultDialog(false, response);
        }
      }
    } else {
      // Error handling
      logger.e('Failed to send answers: ${response.data}');
    }
  }

  void _showResultDialog(bool correct, response) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertMessage(message: response.data['feedback'], title: correct ? 'Correct!' : 'Incorrect');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: text.isEmpty || questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 35),
                  const Center(
                    child: Text(
                      'Read the following text and answer the questions below:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  for (int i = 0; i < questions.length; i++)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questions[i],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: i == 0
                              ? _answerController1
                              : i == 1
                                  ? _answerController2
                                  : i == 2
                                      ? _answerController3
                                      : _answerController4,
                          decoration: const InputDecoration(
                            hintText: 'Enter your answer',
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () => _sendAnswers(userProvider),
                      child: const Text('Submit', style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
