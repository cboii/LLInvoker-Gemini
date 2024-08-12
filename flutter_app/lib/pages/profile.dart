import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:flutter_app/pages/subscription.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  var _checkoutSessionId = '';
  final List<String> _languages = ['English', 'German', 'Spanish', 'French'];
  String? _selectedLanguage = 'English';
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _givenNameController;
  late TextEditingController _lastNameController;
  XFile? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _givenNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _lastNameController.dispose();
    _image = null;
    super.dispose();
  }

  Future getImage(UserProvider userProvider) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
      }
    });
    if (_image != null && user != null) {
          String imageUrl = await uploadImageToFirebase(_image!, user.uid);
          userProvider.setProfilePictureURL(imageUrl);
        }
  }

  Future<String> uploadImageToFirebase(XFile imageFile, String uid) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('userFiles/$uid/profilePicture.png');
    Uint8List imageData = await imageFile.readAsBytes();
    UploadTask uploadTask = ref.putData(imageData, SettableMetadata(contentType: 'image/png'));
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.userRef == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_isEditing) {
          _givenNameController.text = userProvider.givenName;
          _lastNameController.text = userProvider.lastName;
        }

        return Scaffold(
          appBar: AppBar(
                actions: [
                  IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    onPressed: () {
                      setState(() {
                        if (_isEditing) {
                          // Save logic here
                          _saveProfile(userProvider);
                        }
                        _isEditing = !_isEditing;
                      });
                    },
                  ),
                ],
              ),
          body: SingleChildScrollView(
            child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: 
                            CircleAvatar(
                                radius: 60,
                                backgroundImage: (userProvider.profilePictureURL.isNotEmpty
                                        ? NetworkImage(userProvider.profilePictureURL)
                                        : null) as ImageProvider<Object>?,
                              ),
                          ),
                        _buildInfoCards(userProvider),
                        const SizedBox(height: 24),
                        _buildProfileForm(userProvider),
                        const SizedBox(height: 24),
                        _buildActionButtons(userProvider),
                      ],
                    ),
                  ),
                ),
            
          ),
        );
      },
    );
  }

  Widget _buildInfoCards(UserProvider userProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(Icons.star, '${userProvider.stars}', 'Stars', Colors.orange),
            _buildInfoItem(Icons.favorite, '${userProvider.hearts}', 'Hearts', Colors.red),
            _buildInfoItem(Icons.leaderboard, '${userProvider.level}', 'Level', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfileForm(UserProvider userProvider) {
    return Column(
      children: [
        if (_isEditing) ...[
          ElevatedButton(
            onPressed: () => getImage(userProvider),
            child: const Text('Change Profile Picture'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _givenNameController,
            decoration: InputDecoration(
              labelText: 'Given Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your given name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your last name' : null,
          ),
        ] else ...[
          ListTile(
            title: const Text('Name'),
            subtitle: Text('${userProvider.givenName} ${userProvider.lastName}'),
            leading: const Icon(Icons.person),
          ),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(userProvider.email),
            leading: const Icon(Icons.email),
          ),
        ],
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _isEditing ? _selectedLanguage : userProvider.preferredLanguage,
          decoration: InputDecoration(
            labelText: 'Preferred Language',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          items: _languages.map((String language) {
            return DropdownMenuItem<String>(value: language, child: Text(language));
          }).toList(),
          onChanged: _isEditing ? (String? newValue) {
            setState(() {
              _selectedLanguage = newValue;
            });
          } : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserProvider userProvider) {
    bool isPremium = userProvider.isPremium;
    if (isPremium) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.star),
        label: const Text('Premium'),
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.star),
          label: const Text('Upgrade to Premium'),
          onPressed: () async {
                          // Fetch the Premium Subscription product
                          final productQuery = await FirebaseFirestore.instance
                              .collection('products')
                              .where('name', isEqualTo: 'Premium Subscription')  
                              .where('active', isEqualTo: true)
                              .limit(1)
                              .get();
                            Logger().i('ID: ${productQuery.docs.first.id}');
                          
                          if (productQuery.docs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Premium Subscription not available')),
                            );
                            return;
                          }

                          final productId = productQuery.docs.first.id;
                          
                          // Fetch the price for the Premium Subscription
                          final priceQuery = await FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .collection('prices')
                              .where('active', isEqualTo: true)
                              .limit(1)
                              .get();

                          if (priceQuery.docs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Price not available for Premium Subscription')),
                            );
                            return;
                          }

                          final priceId = priceQuery.docs.first.id;

                          // Create a checkout session
                          final docRef = await FirebaseFirestore.instance
                              .collection('customers')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection("checkout_sessions")
                              .add({
                            "client": "web",
                            "mode": "subscription",
                            "price": priceId,
                            "success_url": html.window.location.origin,
                            "cancel_url": html.window.location.origin,
                          });

                          setState(() => _checkoutSessionId = docRef.id);
                        },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_checkoutSessionId.isNotEmpty)
            const SizedBox(height: 12),
        if (_checkoutSessionId.isNotEmpty)
            Subscription(
              checkoutSessionId: _checkoutSessionId,
            ),
        
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Logout'),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            userProvider.updateUser(null);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _saveProfile(UserProvider userProvider) async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userProvider.setPreferredLanguage(_selectedLanguage!);
        userProvider.setGivenName(_givenNameController.text);
        userProvider.setLastName(_lastNameController.text);
      }
    }
  }
}