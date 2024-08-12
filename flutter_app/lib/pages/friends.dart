import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _friendsStream;

  @override
  void initState() {
    super.initState();
    _friendsStream = _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('friends')
        .snapshots();
  }

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
                'Friends',
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
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.doc(data['userRef']).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, dynamic> friendData = snapshot.data!.data() as Map<String, dynamic>;
                      return _buildFriendCard(friendData);
                    }
                    return const Card(child: ListTile(title: Text('Loading...')));
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friendData) {
    String givenName = '';
    String lastName = '';

    if (friendData.containsKey('givenName')) {
      givenName = friendData['givenName'];
    }
    else {
      givenName = friendData['email'];
    }

    if (friendData.containsKey('lastName')) {
      lastName = friendData['lastName'];
    }
    else {
      lastName = '';
    }

    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade200,
                child: Text(
                  (givenName)[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$givenName $lastName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(Icons.leaderboard, Colors.blue, friendData['level'].toString(), 'Level'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.favorite, Colors.red, friendData['hearts'].toString(), 'Hearts'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.star_border, Colors.orange, friendData['stars'].toString(), 'Stars'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showAddFriendDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Friend', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: "Enter friend's email"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
              onPressed: () {
                _addFriend(emailController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _addFriend(String email) async {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      String friendPath = query.docs.first.reference.path;
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('friends')
          .add({
        'userRef': friendPath,
        'addedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
    }
  }
}