import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:flutter_app/utils/exercise_utils.dart';

class Chapter extends StatefulWidget {
  const Chapter({super.key});

  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  Map<String, dynamic>? nextChapter;
  String? currentChapterId;
  bool isDialogShowing = false;

  // Used to determine if the user has attempted the exercise
  bool isExerciseAttempted = false;
  bool isExerciseCorrect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadNextChapter();
    });
  }

  Future<void> _preloadNextChapter() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result = await _getNextChapterRef(userProvider.currentChapterRef!);
    if (mounted) {
      setState(() {
        nextChapter = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                userProvider.currentChapterTitle ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
              Container(
                height: 2,
                width: 200,
                color: Colors.blue,
                margin: const EdgeInsets.only(top: 4),
              ),
            ],
          ),
            actions: [
              Row(
                children: [
                  const Icon(Icons.leaderboard),
                  Text(userProvider.level.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Icon(Icons.favorite, color: Colors.red),
                  Text(userProvider.hearts.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Icon(Icons.star, color: Colors.yellow),
                  Text(userProvider.stars.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                ],
              )
            ],
          ),
          body: _buildBody(context, userProvider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserProvider userProvider) {
    return FutureBuilder<DocumentSnapshot>(
      future: userProvider.currentChapterRef!.get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>;
        final newChapterId = snapshot.data!.reference.id;
        
        currentChapterId = newChapterId;

        final page = getExercisePageWidget(
          type: data['type'],
          data: data,
          onExerciseAttempted: _onExerciseAttempted,
        );

        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.arrow_forward,
                  size: 50,
                  color: isExerciseCorrect ? Colors.blue : Colors.grey, // Change color based on state
                ),
                onPressed: isExerciseCorrect
                    ? () => _loadNextPage(context) // Enable navigation if exercise is correct
                    : null, // Disable the button if exercise isn't completed
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: page),
            ],
          ),
        );
      },
    );
  }

  void _onExerciseAttempted(bool isCorrect) {
    setState(() {
      isExerciseAttempted = true;
      isExerciseCorrect = isCorrect;
    });
  }


  Future<void> _loadNextPage(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final progressService = userProvider.progressService;

    try {
      // Pass the isExerciseAttempted and isExerciseCorrect flags to checkAndEnableNextChapter
      if (await progressService.checkAndEnableNextChapter(userProvider.currentChapterRef!, isExerciseAttempted, isExerciseCorrect)) {
        // Update score if necessary
        if (!userProvider.progress.contains(userProvider.currentChapterRef!)) {
          await progressService.updateScore(5);
        }
        // Update progress
        await progressService.updateProgress(userProvider.currentChapterRef!);

        if (nextChapter == null) {
          _showEndOfSectionDialog(context, userProvider.currentChapterTitle!);
          return;
        }

        if (nextChapter!['type'] == 'nextSection' && !isDialogShowing) {
          isDialogShowing = true;
          final currentSectionTitle = userProvider.currentChapterTitle!;
          final nextSectionTitle = nextChapter!['title'];
          await _showNextSectionDialog(context, currentSectionTitle, nextSectionTitle, userProvider, nextChapter!['reference'].path);
          isDialogShowing = false;
          return;
        }

        await userProvider.updateCurrentChapter(nextChapter!['reference']);
        _preloadNextChapter(); // Preload the next chapter after moving to a new one
        
        // Reset states for the next chapter
        setState(() {
          isExerciseAttempted = false;
          isExerciseCorrect = false;
        });

      } else {
        _showSnackBar(context, 'Please complete the exercise before moving to the next chapter.');
      }
    } catch (e) {
      _showSnackBar(context, 'Error loading next page: $e');
    }
  }


  Future<void> _showNextSectionDialog(BuildContext context, String currentSectionTitle, String nextSectionTitle, UserProvider userProvider, String nextSectionPath) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You have completed "$currentSectionTitle". Do you want to continue with "$nextSectionTitle"?'),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                final firstChapterRef = FirebaseFirestore.instance.collection('$nextSectionPath/chapters').doc('0');
                final firstChapterSnapshot = await firstChapterRef.get();
                if (firstChapterSnapshot.exists) {
                  await userProvider.updateCurrentChapter(firstChapterRef);
                  setState(() {
                    // Reset nextChapter to trigger preloading of the new section's first chapter
                    nextChapter = null;
                  });
                  _preloadNextChapter();
                  setState(() {
                    // Reset nextChapter to trigger preloading of the new section's first chapter
                    nextChapter = null;
                  });
                  _preloadNextChapter();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEndOfSectionDialog(BuildContext context, String sectionTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You have finished "$sectionTitle".'),
          actions: <Widget>[
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


  Future<Map<String, dynamic>?> _getNextChapterRef(DocumentReference currentDocumentRef) async {
    final currentChapterSnapshot = await currentDocumentRef.get();

    if (!currentChapterSnapshot.exists) return null;

    final parts = currentDocumentRef.path.split('/');
    final chapterId = int.parse(parts.last);
    final sectionPath = parts.sublist(0, parts.length - 2).join('/');
    final sectionId = int.parse(parts[parts.length - 3].replaceAll('section', ''));

    // Try next chapter in the same section
    final nextChapterRef = FirebaseFirestore.instance.doc('$sectionPath/chapters/${chapterId + 1}');
    if ((await nextChapterRef.get()).exists) {
      return {'type': 'chapter', 'reference': nextChapterRef};
    }

    // Try first chapter of the next section
    final nextSectionRef = FirebaseFirestore.instance.doc('${parts.sublist(0, parts.length - 3).join('/')}/section${sectionId + 1}');
    final nextSectionSnapshot = await nextSectionRef.get();
    if (nextSectionSnapshot.exists) {
      final nextSectionTitle = nextSectionSnapshot.get('title') as String;
      return {'type': 'nextSection', 'reference': nextSectionRef, 'title': nextSectionTitle};
    }

    return null;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
