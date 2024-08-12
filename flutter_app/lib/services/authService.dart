import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  Logger logger = Logger();
  GoogleAuthProvider googleProvider = GoogleAuthProvider();

  final FirebaseAuth _auth = FirebaseAuth.instance;

    // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      return result.user;
    } catch (e) {
      logger.e(e.toString());
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    // googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
    // googleProvider.setCustomParameters({
    //   'login_hint': 'user@example.com'
    // });

    try {
      // Once signed in, return the UserCredential
      UserCredential credentials = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      return credentials.user;
    } catch (e) {
      logger.e(e.toString());
      return null;
    }

  }


  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      logger.e(e.toString());
    }
  }

  // Auth change user stream
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}
