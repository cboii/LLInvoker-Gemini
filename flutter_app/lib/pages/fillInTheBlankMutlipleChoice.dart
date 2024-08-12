import 'package:flutter/material.dart';
import 'package:flutter_app/providers/userProvider.dart';
import '../components/alertMessage.dart';
import '../components/errorMessage.dart';
import 'package:provider/provider.dart';
import '../components/scoreMessage.dart';

class FillInTheBlankMultipleChoice extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted;

  const FillInTheBlankMultipleChoice({required this.data, required this.onExerciseAttempted, super.key});

  @override
  State<FillInTheBlankMultipleChoice> createState() => _FillInTheBlankMultipleChoiceState();
}

class _FillInTheBlankMultipleChoiceState extends State<FillInTheBlankMultipleChoice> {
  String title = "";
  List<Map<String, dynamic>> exercises = [];
  Map<String, String?> userAnswers = {};
  int currentExerciseIndex = 0;
  int wrongSubmissions = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    title = widget.data['title'];
    exercises = List<Map<String, dynamic>>.from(widget.data['content']);
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

  // Check if the answers are correct
  Future<void> checkAnswers(UserProvider userProvider) async {
    final progressService = userProvider.progressService;

    // Check if the user has enough hearts to proceed
    if (!(await progressService.checkHeartsAndProceed(context))) {
      return; // Stop the submission if the user doesn't have enough hearts
    }

    bool allCorrect = true;
    for (int i = 0; i < exercises.length; i++) {
      for (int j = 0; j < exercises[i]['answers'].length; j++) {
        String key = '$i-$j';
        if (userAnswers[key] != exercises[i]['answers'][j]) {
          allCorrect = false;
          break;
        }
      }
      if (!allCorrect) break;
    }

    if (allCorrect) {
      score = wrongSubmissions == 0 ? 3 : (wrongSubmissions == 1 ? 2 : 1);
      if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
        await userProvider.updateStars(score); // Update stars with the current chapter ID
        await userProvider.updateScore(5); // Update score for exercise completion
      }
      widget.onExerciseAttempted(true); // Notify success
      _showResultDialog(true);
    } else {
      wrongSubmissions++;  // Increment wrong submissions
      await userProvider.updateHearts(-1); // Deduct a heart for incorrect submission
      widget.onExerciseAttempted(false); // Notify failure
      _showResultDialog(false);
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return ErrorMessage(message: message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return exercises.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: _buildExerciseWidget(currentExerciseIndex),
                  ),
                ),
                const SizedBox(height: 20),
                if (currentExerciseIndex == exercises.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () => checkAnswers(userProvider),
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
          );
  }

  // Used to allow two underscores in the json file
  String replaceTwoUnderscores(String input) {
    return input.replaceAllMapped(RegExp(r'(?<!_)__(?!_)'), (match) => '___');
  }

  Widget _buildExerciseWidget(int exerciseIndex) {
    var exercise = exercises[exerciseIndex];
    List<Widget> widgets = [];
    int dropdownIndex = 0;

    for (String word in exercise['sentence'].split(' ')) {
      word = replaceTwoUnderscores(word);
      if (word.startsWith('___')) {
        String key = '$exerciseIndex-$dropdownIndex';
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: 250,
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<dynamic>(
                  value: userAnswers[key],
                  onChanged: (dynamic newValue) {
                    setState(() {
                      userAnswers[key] = newValue;
                    });
                  },
                  items: exercise['options'][dropdownIndex]['choices'].map<DropdownMenuItem<dynamic>>((dynamic value) {
                    return DropdownMenuItem<dynamic>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  ),
                ),
              ),
            ),
          ),
        );
        dropdownIndex++;
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Text(word, style: const TextStyle(fontSize: 20)),
          ),
        );
      }
    }

    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: widgets,
      ),
    );
  }
}
