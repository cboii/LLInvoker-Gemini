import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/components/confirmationMessage.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:provider/provider.dart';

class LevelOverview extends StatelessWidget {
  final String documentPath;
  const LevelOverview({required this.documentPath, super.key});

  Future<bool> showConfirmationDialog(BuildContext context, String levelTitle) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return const ConfirmationMessage(message: 'Do you want to set this course as your active course?');
    },
  ) ?? false;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Choose your difficulty level!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
        ),
      
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('$documentPath/levels').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No courses found'));
          }

          List<DocumentSnapshot> levels = snapshot.data!.docs;
          UserProvider userProvider = Provider.of(context, listen: false);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              var level = levels[index];
              String docpath = level.reference.path;
              String languageLevel = level.id;

              return Padding(
                  padding: const EdgeInsets.all(5),
                  child:
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child:
                      ListTile(
                        title: Center(child: Text(languageLevel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        onTap: () async {
                          String uid = FirebaseAuth.instance.currentUser!.uid;
                          bool confirm = await showConfirmationDialog(context, languageLevel);
                          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                          if (confirm) {
                            List<DocumentReference> courseRefs = userProvider.availableCourses.map((e) => e.reference).toList();
                            if (!courseRefs.contains(level.reference)) {
                              userProvider.addCourse(level.reference, level.get('languagePair'), languageLevel);
                            }
                            userProvider.setActiveCourse(level.reference);
                            userProvider.setActiveLevel(languageLevel);
                            userProvider.setActiveLanguage(level.get('languagePair'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Active course updated')),
                            );
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => ModuleOverview(documentPath: docpath),
                          //   ),
                          // );
                        }
                        },
                      ),
                  )
              );
            },
          );
        },
      ),
    );
  }
}
