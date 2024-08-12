import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';

class TheorySection extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool)? onExerciseAttempted; // Optional callback

  const TheorySection({required this.data, this.onExerciseAttempted, super.key});

  @override
  State<TheorySection> createState() => _TheorySectionState();
}

class _TheorySectionState extends State<TheorySection> {
  Logger logger = Logger();
  String content = 'Loading...';
  String title = 'Loading...';

  @override
  void initState() {
    super.initState();
    title = widget.data['title'];
    content = widget.data['content'];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Automatically mark the section as completed
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final progressService = userProvider.progressService;

      // Check if the user has enough hearts to proceed
      if (await progressService.checkHeartsAndProceed(context)) {
        // Update stars and score
        if (!userProvider.progress.contains(userProvider.currentChapterRef)) {
          await userProvider.updateStars(3); // Award full stars for viewing theory
          await userProvider.updateScore(5); // Award score for viewing theory
        }
        widget.onExerciseAttempted?.call(true); // Notify completion
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.info, size: 80, color: Colors.blue),
                  onPressed: () {
                    // Add action for the info button if needed
                  },
                ),
                const SizedBox(height: 25),
                Center(
                  child: SizedBox(
                    height: 500,
                    child: Markdown(
                      styleSheet: MarkdownStyleSheet(
                        strong: const TextStyle(fontSize: 20),
                      ),
                      data: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
