import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter_app/services/progressService.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:logger/logger.dart';


class UserProvider extends ChangeNotifier {

  Logger logger = Logger();
  late ProgressService progressService;

  User? _user = FirebaseAuth.instance.currentUser;
  DocumentReference? _currentChapterRef;
  String? _currentChapterTitle = '';
  DocumentReference? _userRef;
  String? _activeLanguage = '';
  String? _activeLevel = '';
  Map<String, dynamic> _myCourses = {};
  List<DocumentSnapshot> _availableCourses = [];
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  List<dynamic> _progress = [];
  String? _givenName = '';
  String? _lastName = '';
  String? _email = '';
  int _hearts = 0;
  int _score = 0;
  int _level = 0;
  List<dynamic> _achievements = [];
  String? _preferredLanguage = 'eng';
  DocumentReference? _activeCourse; // document reference en->de for example
  int _stars = 0;
  int? _position;
  String _profilePictureURL = '';
  bool _isPremium = false;
  Map<String, int> _starsMap = {};

  User? get user => _user;
  DocumentReference? get userRef => _userRef;
  DocumentReference? get currentChapterRef => _currentChapterRef;
  String? get currentChapterTitle => _currentChapterTitle;
  String? get activeLanguage => _activeLanguage;
  String? get activeLevel => _activeLevel;
  List<DocumentSnapshot> get availableCourses => _availableCourses;
  Map<String, dynamic> get myCourses => _myCourses;
  List<dynamic> get progress => _progress;
  String get fullName => '$_givenName $_lastName';
  String get givenName => _givenName ?? '';
  String get lastName => _lastName ?? '';
  String get email => _email ?? '';
  int get hearts => _hearts;
  int get score => _score;
  int get level => _level;
  List<dynamic> get achievements => _achievements;
  String? get preferredLanguage => _preferredLanguage;
  int get stars => _stars;
  int? get position => _position;
  DocumentReference? get activeCourse => _activeCourse;
  String get profilePictureURL => _profilePictureURL;
  bool get isPremium => _isPremium;
  Map<String, int> get starsMap => _starsMap; 

  UserProvider() {
    _initUserListener();
    progressService = ProgressService(this);
  }

  void _initUserListener() {
    if (_user != null) {
      _userRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      _userSubscription = _userRef!.snapshots().listen(_handleUserSnapshot);
    }
  }

  Future<void> _getPremiumStatus() async {
  if (_user != null) {
    _user!.getIdTokenResult().then((token) {
      if (token.claims!.containsValue('premium')) {
        _isPremium = true;
      }
      else {
        _isPremium = false;
      }
    });
    }
  }

  void _handleUserSnapshot(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      _myCourses = userData['myCourses'] ?? {};
      List<DocumentReference> courses = List<DocumentReference>.from(userData['courses'] ?? []);
      _activeLanguage = userData['activeLanguage'] ?? 'eng_de';
      _activeLevel = userData['activeLevel'] ?? 'A1';
      _level = userData['level'] ?? 0;
      _progress = _myCourses[_activeLanguage]?[_activeLevel]?['progress'] ?? [];
      _currentChapterRef = _myCourses[_activeLanguage]?[_activeLevel]?['currentChapter'];
      _givenName = userData['givenName'] ?? '';
      _lastName = userData['lastName'] ?? '';
      _email = userData['email'] ?? '';
      _hearts = userData['hearts'] ?? 0;
      _score = userData['score'] ?? 0;
      _achievements = userData['achievements'] ?? [];
      _preferredLanguage = userData['preferredLanguage'] ?? 'English';
      _stars = userData['stars'] ?? 0;
      _position = userData['position'];
      _activeCourse = userData['activeCourse'];
      _profilePictureURL = userData['profilePictureURL'] ?? '';
      _starsMap = Map<String, int>.from(userData['starsMap'] ?? {});
      _fetchAvailableCourses(courses);
      _fetchCurrentChapterTitle();
      _getPremiumStatus();

      if (_preferredLanguage != null) {
        String target = _activeLanguage!.split('_').last;
        switch (_preferredLanguage){
          case 'eng':
            _activeLanguage = 'eng_$target';
            break;
          case 'de':
            _activeLanguage = 'de_$target';
            break;
          case 'es':
            _activeLanguage = 'es_$target';
            break;
          case 'fr':
            _activeLanguage = 'fr_$target';
            break;
        }
      }
      
      notifyListeners();
    }
  }

  Future<void> _fetchAvailableCourses(List<DocumentReference> courses) async {
    _availableCourses = [];
    for (DocumentReference course in courses) {
      DocumentSnapshot doc = await course.get();
      _availableCourses.add(doc);
    }
    notifyListeners();
  }

  Future<void> _fetchCurrentChapterTitle() async {
    if (_currentChapterRef != null) {
      DocumentSnapshot currentChapter = await _currentChapterRef!.get();
      _currentChapterTitle = currentChapter.get('title') ?? '';
      notifyListeners();
    }
  }

  Future<void> updateCurrentChapter(DocumentReference chapterReference) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userRef?.update({
        'currentChapter': chapterReference,
        'myCourses.$_activeLanguage.$_activeLevel.currentChapter': chapterReference
      });
    
      // Local state will be updated by the listener
    }
  }

  void updateUser(User? user) {
    if (user == null) {
      _userSubscription?.cancel();
      _user = null;
      _userRef = null;
      _currentChapterRef = null;
      _currentChapterTitle = '';
      _activeLanguage = '';
      _activeLevel = '';
      _myCourses = {};
      _availableCourses = [];
      _progress = [];
      _givenName = '';
      _lastName = '';
      _email = '';
      _hearts = 0;
      _score = 0;
      _level = 0;
      _achievements = [];
      _preferredLanguage = 'eng';
      _activeCourse = null;
      _stars = 0;
      _position = null;
      _profilePictureURL = '';
      _isPremium = false;
      notifyListeners();
      return;
    }
    _user = user;
    _userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    _userSubscription?.cancel();
    _userSubscription = _userRef!.snapshots().listen(_handleUserSnapshot);
  }


  Future<void> updateProgress(DocumentReference chapterRef) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userRef?.update({
        'myCourses.$_activeLanguage.$_activeLevel.progress': FieldValue.arrayUnion([chapterRef])
      });
    }
  }

  Future<void> updateScore(int score) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userRef?.update({
        'score': FieldValue.increment(score)
      });
    }
  }
  
  Future<void> updateLevel(int level) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userRef?.update({
        'level': level
      });
    }
  }

  Future<void> updateHearts(int hearts) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userRef?.update({
        'hearts': FieldValue.increment(hearts)
      });
    }
  }

  Future<void> updateStars(int stars) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && currentChapterRef != null) {
        try {
            var chapterRefPath = currentChapterRef!.path;  // Use path instead of toString()
            
            var bytesChapterRef = utf8.encode(chapterRefPath);
            var digest = sha256.convert(bytesChapterRef).toString();
            
            _starsMap[digest] = stars; // Update the local starsMap
            
            _stars = _starsMap.values.fold(0, (sum, stars) => sum + stars);
            
            // Update Firestore with the new stars value for the chapter
            await _userRef?.update({
                'starsMap.$digest': _starsMap[digest],
                'stars': _stars
            });

            logger.i('Stars successfully updated. Total stars: $_stars');
        } catch (e) {
            logger.e('Error updating stars: $e');
        }
    } else {
        logger.e('Error: User or currentChapterRef is null');
    }
}

  void setActiveLanguage(String language) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'activeLanguage': language
      });
    }
  }


  void updatePosition(int position) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'position': position
      });
    }
  }


  void setActiveLevel(String level) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'activeLevel': level
      });
    }
  }

  void setPreferredLanguage(String language) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'preferredLanguage': language
      });
    }
  }

  void setGivenName(String name) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'givenName': name
      });
    }
  }

  void setLastName(String name) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'lastName': name
      });
    }
  }

  void setActiveCourse(DocumentReference course) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'activeCourse': course,
      });
    }
  }

  void addCourse(DocumentReference course, String languagePair, String lvl) {
    User? user = FirebaseAuth.instance.currentUser;
    final DocumentReference chapterRef = FirebaseFirestore.instance
      .doc(course.path).collection('modules')
      .doc('module1').collection('sections')
      .doc('section1').collection('chapters')
      .doc('0');
    if (user != null) {
      _userRef?.update({
        'myCourses.$languagePair.$lvl': {
          'progress': [],
          'currentChapter': chapterRef 
        },
        'courses': FieldValue.arrayUnion([course]),
      });
    }
  }

  void setProfilePictureURL(String url) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userRef?.update({
        'profilePictureURL': url,
      });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<int> _getChapterCountInModule(DocumentReference moduleRef) async {
      QuerySnapshot chaptersSnapshot = await moduleRef.collection('chapters').get();
      return chaptersSnapshot.docs.length;
  }

  Future<double> calculateModuleProgress(DocumentReference moduleRef) async {
    try {
        QuerySnapshot sectionsSnapshot = await moduleRef.collection('sections').get();
        int totalChapters = 0;
        int earnedStars = 0;

        // Iterate over all sections to get chapters
        for (var section in sectionsSnapshot.docs) {
            QuerySnapshot chaptersSnapshot = await section.reference.collection('chapters').get();
            int sectionChapters = chaptersSnapshot.docs.length;
            totalChapters += sectionChapters;
            
            for (var chapter in chaptersSnapshot.docs) {
                String chapterRefPath = chapter.reference.path;
                var digest = sha256.convert(utf8.encode(chapterRefPath)).toString();

                if (_starsMap.containsKey(digest)) {
                    earnedStars += _starsMap[digest] ?? 0;
                }
            }
        }

        int maxStars = totalChapters * 3;
        // logger.i('ModuleRef: $moduleRef, Earned Stars: $earnedStars, Max Stars: $maxStars');
        return maxStars > 0 ? (earnedStars / maxStars) : 0.0;
    } catch (e) {
        logger.e('Error calculating module progress: $e');
        return 0.0;
    }
}


}