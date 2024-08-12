import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/components/errorMessage.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/navigationProvider.dart';

class ChapterOverview extends StatelessWidget {
  final String documentPath;
  const ChapterOverview({required this.documentPath, super.key});

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorMessage(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            title: const Text(
              'Chapter Overview',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('$documentPath/chapters')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                _showErrorDialog(context, 'Error fetching data: ${snapshot.error}');
                return const Center(child: Text('An error occurred'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No chapters found'));
              }
              final documents = snapshot.data!.docs;

              // Sort the documents based on the numeric part of the title
              documents.sort((a, b) {
                final aTitle = a.get('title') as String;
                final bTitle = b.get('title') as String;
                final aNumber = int.tryParse(aTitle.split(':')[0]) ?? 0;
                final bNumber = int.tryParse(bTitle.split(':')[0]) ?? 0;
                return aNumber.compareTo(bNumber);
              });

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: documents.length,
                itemBuilder: (context, index) => _buildChapterCard(context, documents[index], userProvider),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChapterCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> chapter, UserProvider userProvider) {
    final chapterTitle = chapter.get('title') as String;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _navigateToChapter(context, chapter.reference),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task,
                  size: 40,
                  color: userProvider.progress.contains(chapter.reference) ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  chapterTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToChapter(BuildContext context, DocumentReference docRef) {
    Provider.of<UserProvider>(context, listen: false)
        .updateCurrentChapter(docRef);
    Provider.of<NavigationProvider>(context, listen: false).setIndex(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
