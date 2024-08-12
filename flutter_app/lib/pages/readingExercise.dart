import 'package:flutter/material.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../components/alertMessage.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ReadingExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted;

  const ReadingExercise({required this.data, required this.onExerciseAttempted, super.key});

  @override
  State<ReadingExercise> createState() => _ReadingExerciseState();
}

class _ReadingExerciseState extends State<ReadingExercise> {
  Logger logger = Logger();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _selectedLanguage = 'en_US'; // Default language
  List<LocaleName> _localeNames = [];
  String title = 'Loading...';
  String content = "";
  int score = 0;
  int wrongSubmissions = 0;

  @override
  void initState() {
    final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    String language = userProvider.activeLanguage!.split('_').last;
    switch (language) {
      case 'eng':
        _selectedLanguage = 'en_US';
        break;
      case 'de':
        _selectedLanguage = 'de_DE';
        break;
      case 'es':
        _selectedLanguage = 'es_ES';
        break;
      case 'fr':
        _selectedLanguage = 'fr_FR';
        break;
    }
    super.initState();
    _initSpeech();
    content = widget.data['content'];
    title = widget.data['title'];
  }

  // Check if the answers are correct
  Future<void> _submitAnswers(UserProvider userProvider) async {
    // Check if the user has enough hearts to proceed
    if (!(await userProvider.progressService.checkHeartsAndProceed(context))) {
      return; // Stop the submission if the user doesn't have enough hearts
    }

    String filtered = content
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('?', '')
        .replaceAll('!', '')
        .toLowerCase();

    if (filtered != _lastWords.toLowerCase()) {
      wrongSubmissions++;
      await userProvider.updateHearts(-1); // Deduct a heart for incorrect submission
      widget.onExerciseAttempted(false); // Notify failure
      _showResultDialog(false);
    } else {
      score = wrongSubmissions == 0 ? 3 : (wrongSubmissions == 1 ? 2 : 1);
      if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
        await userProvider.updateStars(score); // Update stars with the current chapter ID
        await userProvider.updateScore(5); // Update score for exercise completion
      }
      widget.onExerciseAttempted(true); // Notify success
      _showResultDialog(true);
    }
  }

  void _showResultDialog(bool correct) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertMessage(
            message: correct
                ? 'All answers are correct.'
                : 'Some answers are incorrect.',
            title: correct ? 'Correct!' : 'Incorrect');
      },
    );
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    _localeNames = await _speechToText.locales();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _selectedLanguage,
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _lastWords = result.recognizedWords;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 35),
            const Center(
              child: Text(
                'Press the record button and read the following text aloud:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 35),
            Center(
              child: Text(
                content,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Recognized words:',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                textAlign: TextAlign.center,
                // If listening is active show the recognized words
                _speechToText.isListening
                    ? _lastWords
                    // If listening isn't active but could be tell the user
                    // how to start it, otherwise indicate that speech
                    // recognition is not yet ready or not supported on
                    // the target device
                    : _speechEnabled
                        ? 'Tap the microphone to start listening...'
                        : 'Speech not available',
              ),
            ),
            FloatingActionButton(
              onPressed:
                  // If not yet listening for speech start, otherwise stop
                  _speechToText.isNotListening
                      ? _startListening
                      : _stopListening,
              tooltip: 'Listen',
              child: Icon(
                  _speechToText.isNotListening ? Icons.mic_off : Icons.mic),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => _submitAnswers(userProvider),
                child: const Text('Submit',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
          ],
        ));
  }
}
