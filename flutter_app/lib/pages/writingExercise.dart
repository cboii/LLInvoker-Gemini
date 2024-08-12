import 'package:flutter/material.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

class WritingExercise extends StatefulWidget {
  final Map<String,dynamic> data;
  final Function(bool) onExerciseAttempted;

  const WritingExercise({super.key, required this.data, required this.onExerciseAttempted});

  @override
  State<WritingExercise> createState() => _WritingExerciseState();
}

class _WritingExerciseState extends State<WritingExercise> {
  final functions = FirebaseFunctions.instance;
  final TextEditingController _controller = TextEditingController();
  int _wordCount = 0;
  bool _isSubmitting = false;
  String? _feedback;
  bool _result = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = 0;
      List<String> lines =_controller.text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        _wordCount += lines[i].split(' ').where((word) => word.isNotEmpty).toList().length;
      }
    });
  }

  Future<void> _submitEssay() async {
    final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check if the user has enough hearts to proceed
    if (!(await userProvider.progressService.checkHeartsAndProceed(context))) {
      return; // Stop if the user doesn't have enough hearts
    }

    if (_wordCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedback = null;
    });

    try {
      final response = await functions.httpsCallable('writingExercise')({
          'topic': widget.data['topic'],
          'text': _controller.text,
          'language': userProvider.activeLanguage,
        });
      
      if (response.data != null) {
        final result = response.data;
        setState(() {
          _result = result['result'];
          _feedback = result['feedback'];
        });

        // Notify success or failure
        widget.onExerciseAttempted(_result);

        // Update stars and score if successful and first time completing
        if (_result && !userProvider.progress.contains(userProvider.currentChapterRef)) {
          userProvider.updateStars(3); // Assuming full stars for successful submission
          userProvider.updateScore(5); // Update score by 5 points for the exercise completion
        }
      } else {
        throw Exception('Failed to submit essay');
      }
    } catch (e) {
      setState(() {
        _feedback = 'An error occurred while submitting your essay. Please try again.';
      });
      widget.onExerciseAttempted(false); // Notify failure
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topic:',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data['topic'],
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              Text(
                _feedback!,
                style: TextStyle(
                  color: _result ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Start writing your essay here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Word count: $_wordCount / 250',
              style: TextStyle(
                color: _wordCount > 250 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isSubmitting ? null : _submitEssay,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Essay'),
              
            ),
            
          ],
        ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
