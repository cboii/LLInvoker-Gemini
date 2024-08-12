import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String givenName;
  String lastName;
  String email;
  String uid;
  int score;
  int level;
  int hearts;


  UserModel({
    required this.givenName,
    required this.lastName,
    required this.email,
    required this.uid,
    required this.score,
    required this.level,
    required this.hearts,
  });

  factory UserModel.fromUID(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        return UserModel(
          givenName: snapshot.data()!['givenName'],
          lastName: snapshot.data()!['lastName'],
          email: snapshot.data()!['email'],
          uid: snapshot.data()!['uid'],
          score: snapshot.data()!['score'],
          level: snapshot.data()!['level'],
          hearts: snapshot.data()!['hearts'],);
      } else {
        throw Exception('User not found');
      }
    });
    throw Exception('User not found');
  }
}