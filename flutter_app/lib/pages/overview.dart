import 'package:flutter/material.dart';
import 'package:flutter_app/pages/sectionOverview.dart';
import 'package:flutter_app/providers/navigationProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/providers/userProvider.dart';


class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {

  @override
  void initState() {
    super.initState();
  }
  

  Widget _buildCard(Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
Widget build(BuildContext context) {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      final availableCourses = userProvider.availableCourses;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Overview',
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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.blue,
              onPressed: () => {
                FirebaseAuth.instance.signOut(),
                userProvider.updateUser(null),
              }
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Course Overview'),
                    const SizedBox(height: 16),
                    _buildModuleList(userProvider),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Continue Learning'),
                    const SizedBox(height: 16),
                    _buildContinueLearningCard(context, userProvider),
                    const SizedBox(height: 24),
                    _buildSectionTitle('My Courses'),
                    const SizedBox(height: 16),
                    _buildMyCoursesList(availableCourses, userProvider, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
  }

  Widget _buildModuleList(UserProvider userProvider) {
  return userProvider.activeCourse == null ? const Center(child: CircularProgressIndicator()) : FutureBuilder<QuerySnapshot>(
    future: userProvider.activeCourse!.collection('modules').get(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final documents = snapshot.data?.docs ?? [];
        
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.3,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final module = documents[index];
            final moduleTitle = module.get('title') as String;
            
            return FutureBuilder<double>(
              future: userProvider.calculateModuleProgress(module.reference),
              builder: (context, progressSnapshot) {
                double progress = progressSnapshot.data ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 200,
                    child: _buildCard(
                      SingleChildScrollView(
                        child:
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.book, size: 40),
                            const SizedBox(height: 16),
                            Text(
                              moduleTitle,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              child: ProgressBarWithPercentage(progress: progress),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SectionOverview(documentRef: module.reference))),
                              child: const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}

  Widget _buildContinueLearningCard(BuildContext context, UserProvider userProvider) {
    return SizedBox(
      height: 250, // Adjust as needed
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 200, // Adjust as needed
          child: _buildCard(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          userProvider.currentChapterTitle ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setIndex(1),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyCoursesList(List<DocumentSnapshot> availableCourses, UserProvider userProvider, BuildContext context) {
    return SizedBox(
      height: 250, // Adjust as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableCourses.length,
        itemBuilder: (context, index) {
          final course = availableCourses[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildCard(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Course: ${course.get('language')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Level: ${course.get('level')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () => _switchCourse(userProvider, course, context),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  void _switchCourse(UserProvider userProvider, DocumentSnapshot course, BuildContext context) {
    userProvider.setActiveLanguage(course.get('languagePair'));
    userProvider.setActiveLevel(course.get('level'));
    userProvider.setActiveCourse(course.reference);
    Provider.of<NavigationProvider>(context, listen: false).setIndex(1);
  }
}

class ProgressBarWithPercentage extends StatelessWidget {
  final double progress;

  const ProgressBarWithPercentage({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        LinearProgressIndicator(
          value: progress,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 20,
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}