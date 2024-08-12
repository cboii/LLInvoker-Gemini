import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'levelOverview.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoursesOverview extends StatelessWidget {
  const CoursesOverview({super.key});

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
                'Courses Overview',
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
      body:
      FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('courses').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No sections found'));
          }

          List<DocumentSnapshot> courses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var course = courses[index];
              String docpath = course.reference.path;
              String language = course.get('language');

              return 
              Padding(padding: const EdgeInsets.all(5.0),
              child:
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => 
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelOverview(documentPath: docpath),
                        ),
                      ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.book_rounded,
                              size: 40,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              language,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                            ),
                          ],
                        ),
                      ),
                    ),
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
