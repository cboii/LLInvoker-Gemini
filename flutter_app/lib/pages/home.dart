// File: pages/mainPage.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/pages/chapter.dart';
import 'package:flutter_app/pages/coursesOverview.dart';
import 'package:flutter_app/pages/chat.dart';
import 'package:flutter_app/pages/friends.dart';
import 'package:flutter_app/pages/generatedChapters.dart';
import 'package:flutter_app/pages/overview.dart';
import 'package:flutter_app/pages/refresh.dart';
import 'package:flutter_app/pages/vocabulary.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:flutter_app/services/authService.dart';
import 'profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signIn.dart';
import 'leaderboard.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/navigationProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final AuthService _auth = AuthService();
  final String _disclaimerShownKey = 'disclaimer_shown';
  bool _isDisclaimerShown = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkDisclaimerShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDisclaimerShown = prefs.getBool(_disclaimerShownKey) ?? false;

    if (!_isDisclaimerShown) {
      _showDisclaimerDialog();
    }
  }

  Future<void> _showDisclaimerDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disclaimer'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This app contains content that may not be suitable for all users.'),
                Text('By continuing, you agree to the terms of use.'),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Agree'),
              onPressed: () {
                _setDisclaimerShown();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _setDisclaimerShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerShownKey, true);
    setState(() {
      _isDisclaimerShown = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        List<Widget> pages = <Widget>[
          const Overview(),
          const Chapter(),
          const ChatScreen(),
          const ProfilePage(),
          const VocabularyPage(),
          const LeaderboardPage(),
          const CoursesOverview(),
          const FriendsPage(),
          const VocabularyRefreshPage(),
          Library(),
        ];

        final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

        return StreamBuilder<User?>(
          stream: _auth.user,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              User? user = snapshot.data;
              _checkDisclaimerShown();
              if (user == null) {
                return SignInPage(authService: _auth);
              } else {
                userProvider.updateUser(user);
                return pages.elementAt(navigationProvider.selectedIndex);
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }
}