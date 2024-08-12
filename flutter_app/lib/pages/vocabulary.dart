import 'package:flutter/material.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _selectedWord;
  final FlutterTts flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final UserProvider userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Vocabulary',
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
      body: Row(
        children: [
          // Left side: Vocabulary List
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Vocabulary',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: currentUser == null
                      ? const Center(child: Text('Please log in to view your vocabulary.'))
                      : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users/${currentUser.uid}/vocabulary/${userProvider.activeLanguage}/vocabulary')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<QueryDocumentSnapshot> snapshotData = snapshot.data?.docs ?? [];
                      final words = snapshotData
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();

                      final filteredWords = words.where((word) {
                        final entry = word['entry'].toLowerCase();
                        final translation = word['translation'].toLowerCase();
                        return entry.contains(_searchQuery) || translation.contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        itemCount: filteredWords.length,
                        itemBuilder: (context, index) {
                          final word = filteredWords[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Center(
                                child: Text(
                                  word['entry']!,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedWord = word;
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right side: Selected Word Card
          Expanded(
            flex: 1,
            child: _selectedWord == null
                ? const Center(child: Text('Select a word to view details'))
                : _buildWordCard(context, _selectedWord!, userProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, Map<String, dynamic> word, UserProvider userProvider) {
    String? origin;
    String? target;

    switch (userProvider.activeLanguage) {
      case 'eng_de':
        origin = 'English';
        target = 'German';
        break;
      case 'eng_fr':
        origin = 'English';
        target = 'French';
        break;
      case 'fr_de':
        origin = 'Français';
        target = 'Allemand';
        break;
      default:
        origin = 'English';
        target = 'German';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$target:',
              style: TextStyle(fontSize: 18, color: Colors.blue[700]),
            ),
            const SizedBox(height: 8),
            Text(
              word['entry']!,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              '$origin:',
              style: TextStyle(fontSize: 18, color: Colors.blue[700]),
            ),
            const SizedBox(height: 8),
            Text(
              word['translation']!,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _speak(word['entry']!, userProvider.activeLanguage!.split('_')[1]),
              icon: const Icon(Icons.volume_up, color: Colors.white),
              label: const Text('Pronounce', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speak(String text, String language) async {
    switch (language) {
      case 'fr':
        await flutterTts.setLanguage('fr-FR');
        break;
      case 'de':
        await flutterTts.setLanguage('de-DE');
        break;
      case 'en':
        await flutterTts.setLanguage('en-US');
        break;
      default:
        await flutterTts.setLanguage('de-DE');
    }
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}