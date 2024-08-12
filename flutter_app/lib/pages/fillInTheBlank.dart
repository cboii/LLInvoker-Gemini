import 'package:flutter/material.dart';
import 'package:flutter_app/components/alertMessage.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/components/scoreMessage.dart';

class FillInTheBlank extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted; // used to pass the result back to Chapter

  const FillInTheBlank({required this.data, required this.onExerciseAttempted, super.key});

  @override
  State<FillInTheBlank> createState() => _FillInTheBlankState();
}

class _FillInTheBlankState extends State<FillInTheBlank> {
  Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  String title = "";
  List<Map<String, dynamic>> exercises = [];
  Map<String, String> userAnswers = {};
  Map<String, TextEditingController> controllers = {};
  int currentExerciseIndex = 0;
  int wrongSubmissions = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    title = widget.data['title'];
    exercises = List<Map<String, dynamic>>.from(widget.data['content']);
    for (int i = 0; i < exercises.length; i++) {
      for (int j = 0; j < exercises[i]['answers'].length; j++) {
        String key = '$i-$j';
        controllers[key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void nextExercise() {
    if (currentExerciseIndex < exercises.length - 1) {
      if (mounted) {
        setState(() {
          currentExerciseIndex++;
        });
      }
    }
  }

  void previousExercise() {
    if (currentExerciseIndex > 0) {
      if (mounted) {
        setState(() {
          currentExerciseIndex--;
        });
      }
    }
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

      for (int i = 0; i < exercises.length; i++) {
        for (int j = 0; j < exercises[i]['answers'].length; j++) {
          String key = '$i-$j';
          String userAnswer = controllers[key]!.text.toLowerCase();
          String correctAnswer = exercises[i]['answers'][j].toLowerCase();

          // Validate using ProgressService
          bool isCorrect = await progressService.validateExercise(userAnswer, correctAnswer);
          if (!isCorrect) {
            allCorrect = false;
            break;
          }
        }
        if (!allCorrect) break;
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
                title: 'Incorrect');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return exercises.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(50),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 25),
                    _buildExerciseWidget(currentExerciseIndex),
                    const SizedBox(height: 50),
                    if (currentExerciseIndex == exercises.length - 1)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () => _submitAnswers(userProvider),
                        child: const Text('Submit', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentExerciseIndex > 0)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: previousExercise,
                              child: const Text('Previous', style: TextStyle(fontSize: 20, color: Colors.white)),
                            ),
                          ),
                        if (currentExerciseIndex < exercises.length - 1)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: nextExercise,
                              child: const Text('Next', style: TextStyle(fontSize: 20, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  // Used to allow two underscores in the json file
  String replaceTwoUnderscores(String input) {
  return input.replaceAllMapped(RegExp(r'(?<!_)__(?!_)'), (match) => '___');
}

  Widget _buildExerciseWidget(int exerciseIndex) {
    var exercise = exercises[exerciseIndex];
    return Column(
      children: [
        Text(
          replaceTwoUnderscores(exercise['sentence'].replaceAllMapped(RegExp(r'__\d+__'), (match) => '______')),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < exercise['answers'].length; i++)
          _buildBlankField('Blank ${i + 1}', '$exerciseIndex-$i'),
      ],
    );
  }

  Widget _buildBlankField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 350,
        child: TextFormField(
          controller: controllers[key],
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter a word' : null,
        ),
      ),
    );
  }
}