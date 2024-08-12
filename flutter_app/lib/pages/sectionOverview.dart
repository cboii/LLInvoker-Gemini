import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/pages/chapterOverview.dart';
import 'package:flutter_app/components/errorMessage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';


class SectionOverview extends StatefulWidget {
  final DocumentReference documentRef;
  const SectionOverview({required this.documentRef, super.key});

  @override
  @override
  State<SectionOverview> createState() => _SectionOverviewState();

}

class _SectionOverviewState extends State<SectionOverview> {

  List<DocumentSnapshot> documents = [];
  late DocumentSnapshot? userDocument;
  late String? currentChapterTitle;
  late DocumentReference? currentChapterRef;
  late final UserProvider _userProvider;


  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _userProvider.userRef!.get().then((doc) async {
      setState(() {
        currentChapterRef = _userProvider.currentChapterRef;
        currentChapterTitle = _userProvider.currentChapterTitle;
        userDocument = doc;
      });
    }).catchError((onError) {
      _showErrorDialog('Error: $onError');
    });
    _fetchSectionData();
  }


  Future<void> _fetchSectionData() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await widget.documentRef.collection('sections').get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          documents = snapshot.docs;
        });
      } else {
        _showErrorDialog('Data not found');
      }
    } catch (e) {
      _showErrorDialog('Error fetching data: $e');
    }
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Section Overview', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          var section = documents[index];
          String docpath = section.reference.path;

          return Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.book, size: 40),
                    title: Center(
                      child: Text(
                        section['title'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                      Padding(padding: const EdgeInsets.all(5),
                        child:
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChapterOverview(documentPath: docpath),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('Section Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}