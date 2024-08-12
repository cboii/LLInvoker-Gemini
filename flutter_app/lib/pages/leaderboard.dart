import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  int? _currentUserScore;
  String _uid = '';
  late List<DocumentSnapshot> _friendsLeaderboardUsers = [];
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchUserScore();
    _initializeLeaderboardStreams();
  }

  Future<void> _fetchUserScore() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _currentUserScore = userProvider.score;
    });
  }

  Future<void> _initializeLeaderboardStreams() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);


    var friends = await userProvider.userRef!.collection('friends').get();
    
      List<DocumentSnapshot> friendDocs = [];
      for (var doc in friends.docs) {
        String friendPath = doc['userRef'] as String;
        DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance.doc(friendPath).get();
        friendDocs.add(friendSnapshot);
      }
      friendDocs.add(await userProvider.userRef!.get());
      friendDocs.sort((a, b) => (b.get('score').compareTo((a.get('score')))));
      setState(() {
        _friendsLeaderboardUsers = friendDocs;
      });

    _updateCurrentUserPosition(userProvider, _friendsLeaderboardUsers);
  }


  void _updateCurrentUserPosition(UserProvider userProvider, List<DocumentSnapshot> users) {
    
    final currentUserIndex = users.indexWhere((doc) => doc.id == _uid);
    if (currentUserIndex != -1) {
      userProvider.updatePosition(currentUserIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, UserProvider userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Leaderboard',
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
          body: Row(
            children: [
              // Left side: Leaderboard List
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn('Your Position', '${userProvider.position}'),
                          _buildInfoColumn('Your Score', '$_currentUserScore'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: 
                          _buildLeaderboardList(_friendsLeaderboardUsers),
                    ),
                  ],
                ),
              ),
              // Right side: Selected User Profile
              Expanded(
                flex: 1,
                child: _selectedUser == null
                    ? const Center(child: Text('Select a user to view their profile'))
                    : _buildProfileCard(_selectedUser!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(List<DocumentSnapshot> leaderboardUsers) {

        return ListView.builder(
          itemCount: leaderboardUsers.length,
          itemBuilder: (context, index) {
            final user = leaderboardUsers[index];
            final isCurrentUser = leaderboardUsers[index].id == _uid;
            return _buildUserListTile(user.data() as Map<String,dynamic>, index + 1, isCurrentUser);
          },
        );
  }

  Widget _buildUserListTile(Map<String, dynamic> user, int position, bool isCurrentUser) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('$position', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(user['givenName'] ?? user['email'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Score: ${user['score']}'),
        trailing: isCurrentUser ? const Icon(Icons.person, color: Colors.blue) : null,
        onTap: () {
          setState(() {
            _selectedUser = user;
          });
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['givenName'] ?? user['email'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProfileInfo('Score', '${user['score']}', Icons.stars),
            _buildProfileInfo('Level', '${user['level'] ?? 1}', Icons.trending_up),
            _buildProfileInfo('Hearts', '${user['hearts'] ?? 5}', Icons.favorite),
            const SizedBox(height: 24),
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (user['achievements'] as List<dynamic>? ?? [])
                  .map((achievement) => Chip(
                        label: Text(achievement),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}