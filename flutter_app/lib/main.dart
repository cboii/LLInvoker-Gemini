import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app/providers/navigationProvider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_app/pages/home.dart';
import 'providers/userProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  var logger = Logger();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) { // Only for debug mode.
    try {
      const  emulatorHost = '127.0.0.1';
      FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
    } catch (e) {
      // ignore: avoid_print
      logger.e(e);
    }
  }
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, child) {
          return MaterialApp(
            title: 'LLInvoker',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              iconButtonTheme: IconButtonThemeData(
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            home: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Small screen: Use BottomNavigationBar
                  return Scaffold(
                    body: const MainPage(),
                    bottomNavigationBar: BottomNavigationBar(
                      currentIndex: navigationProvider.selectedIndex,
                      onTap: (index) => navigationProvider.setIndex(index),
                      items: const <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.home),
                              label: 'Overview',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.book),
                              label: 'Learn',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.chat),
                              label: 'Chat',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.person),
                              label: 'Profile',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.menu_book_rounded),
                              label: 'Vocabulary',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.leaderboard),
                              label: 'Leaderboard',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.book_outlined),
                              label: 'Courses',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.person_add),
                              label: 'Friends',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.refresh),
                              label: 'Refresh',
                            ),
                            BottomNavigationBarItem(
                              backgroundColor: Colors.blue,
                              icon: Icon(Icons.library_books),
                              label: 'My Library',
                            ),
                            // BottomNavigationBarItem(
                            //   backgroundColor: Colors.blue,
                            //   icon: Icon(Icons.shop),
                            //   label: 'Shop',
                            // ),
                        // Add other navigation items here
                      ],
                    ),
                  );
                } else {
                  // Large screen: Use Drawer
                  return Scaffold(
                    body: Row(
                      children: [
                        NavigationDrawer(
                          selectedIndex: navigationProvider.selectedIndex,
                          onItemTapped: (index) => navigationProvider.setIndex(index),
                        ),
                        const Expanded(
                          child: MainPage(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const NavigationDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return Container(
        width: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            if (userProvider.user != null && userProvider.profilePictureURL.isNotEmpty) ...[
            Container(
              width: 200,
              height: 100,
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(userProvider.profilePictureURL) as ImageProvider<Object>?
                ),
            ),
            Padding(padding: const EdgeInsets.all(10),
            child:
              Text(
                '${userProvider.givenName} ${userProvider.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ],
            Container(
              height: 500,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerItem(icon: Icons.home, label: 'Overview', index: 0, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.book, label: 'Learn', index: 1, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.chat, label: 'Chat', index: 2, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.person, label: 'Profile', index: 3, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.menu_book_rounded, label: 'Vocabulary', index: 4, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.leaderboard, label: 'Leaderboard', index: 5, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.book_outlined, label: 'Courses', index: 6, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.person_add, label: 'Friends', index: 7, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.refresh, label: 'Refresh', index: 8, selectedIndex: selectedIndex, onTap: onItemTapped),
                  DrawerItem(icon: Icons.library_books, label: 'My Library', index: 9, selectedIndex: selectedIndex, onTap: onItemTapped),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const DrawerItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}