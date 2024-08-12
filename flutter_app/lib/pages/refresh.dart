import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/components/alertMessage.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:provider/provider.dart';

class VocabularyRefreshPage extends StatefulWidget {
  const VocabularyRefreshPage({super.key});

  @override
  State<VocabularyRefreshPage> createState() => _VocabularyRefreshPageState();
}

class _VocabularyRefreshPageState extends State<VocabularyRefreshPage> {
  List<Map<String, String>> words = [];
  List<TextEditingController> controllers = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchWords();
  }

  void _showResultDialog(bool correct, int score) {

    showDialog(
      context: context,
      builder: (context) {
        return correct 
          ? const AlertMessage(
              message: 'Well done!', 
              title: 'Correct'
          )
          : const AlertMessage(
              message: 'The answer is incorrect. Please try again.', 
              title: 'Incorrect'
            );
      },
    );
  }

  Future<void> _fetchWords() async {
    final UserProvider userProvider = Provider.of(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users/$uid/vocabulary/${userProvider.activeLanguage}/vocabulary')
        .orderBy(FieldPath.documentId)
        .limit(15)
        .get();

    setState(() {
      words = snapshot.docs
          .map((doc) => {
                'entry': doc['entry'] as String,
                'translation': doc['translation'] as String,
              })
          .toList();
      words.shuffle();
      controllers = List.generate(words.length, (_) => TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Refresh',
                style: TextStyle(
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
      ),
      body: Container(
        child: words.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: words.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(50.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Card(
                                elevation: 4,
                                color: Colors.blue[100],
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    words[index]['entry']!,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(width: 350, padding: const EdgeInsets.all(20), child:
                                TextField(
                                  controller: controllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Your answer',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0),),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),),
                                onPressed: () {
                                  _showResultDialog(controllers[index].text.toLowerCase() ==
                                                words[index]['translation']!
                                                    .toLowerCase(), 3);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('${currentIndex + 1} / ${words.length}'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}