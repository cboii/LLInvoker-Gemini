import 'package:flutter/material.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:provider/provider.dart';

class VerbConjugationPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onExerciseAttempted;

  const VerbConjugationPage({required this.data, required this.onExerciseAttempted, super.key});

  @override
  State<VerbConjugationPage> createState() => _VerbConjugationPageState();
}

class _VerbConjugationPageState extends State<VerbConjugationPage> {
  String _selectedTense = '';
  String _verb = '';
  Set<String> _viewedTenses = {}; // Track viewed tenses

  @override
  void initState() {
    super.initState();
    if (widget.data.isNotEmpty) {
      _selectedTense = widget.data['tenses'].keys.first;
      _verb = widget.data['verb'];
      _viewedTenses.add(_selectedTense); // Mark the first tense as viewed
    }
  }

  void _onTenseSelected(String tense, UserProvider userProvider) async {
    // Check if the user has enough hearts to proceed
    if (!(await userProvider.progressService.checkHeartsAndProceed(context))) {
      return; // Stop if the user doesn't have enough hearts
    }

    setState(() {
      _selectedTense = tense;
      _viewedTenses.add(tense); // Mark the tense as viewed

      // Check if all tenses have been viewed
      if (_viewedTenses.length == widget.data['tenses'].keys.length) {
        widget.onExerciseAttempted(true); // Notify completion
        
        // Update stars and score if it's the first time completing the chapter
        if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
          userProvider.updateStars(3); // Assume full stars for viewing all tenses
          userProvider.updateScore(5); // Update score by 5 points for the exercise completion
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Tense selection sidebar
              Container(
                margin: EdgeInsets.all(20),
                width: 200,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey[400]!)),
                ),
                child: Center(  // Wrap with Center widget
                  child: ListView.builder(
                    shrinkWrap: true,  // Allow the ListView to shrink to its content
                    physics: const ClampingScrollPhysics(),  // Prevents overscroll
                    itemCount: widget.data['tenses'].length,
                    itemBuilder: (context, index) {
                      String tense = widget.data['tenses'].keys.elementAt(index);
                      return ListTile(
                        title: ElevatedButton(
                          child: Text(tense),
                          onPressed: () => _onTenseSelected(tense, userProvider),
                        ),
                        selected: _selectedTense == tense,
                      );
                    },
                  ),
                ),
              ),
              // Conjugation display area
              Expanded(
                child: _selectedTense.isNotEmpty
                    ? ConjugationDisplay(
                        tense: _selectedTense,
                        conjugations: widget.data['tenses'][_selectedTense] as Map<String, dynamic>,
                        verb: _verb,
                      )
                    : const Center(child: Text('Select a tense to view conjugations')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConjugationDisplay extends StatelessWidget {
  final String tense;
  final Map<String, dynamic> conjugations;
  final String verb;

  const ConjugationDisplay({super.key, required this.tense, required this.conjugations, required this.verb});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '$verb - $tense',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: conjugations.length,
            itemBuilder: (context, index) {
              String pronoun = conjugations.keys.elementAt(index);
              String conjugation = conjugations[pronoun]!;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Text(
                    pronoun,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text(conjugation),
                  trailing: IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: () {
                      // TODO: Implement text-to-speech functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Playing audio for: $pronoun $conjugation')),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
