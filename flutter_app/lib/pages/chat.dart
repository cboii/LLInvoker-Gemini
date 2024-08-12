import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/userProvider.dart';
import 'package:flutter_app/pages/theory.dart';
import 'package:flutter_app/pages/fillInTheBlank.dart';
import 'package:flutter_app/pages/conjugationExercise.dart';
import 'package:flutter_app/pages/fillInTheBlankMutlipleChoice.dart';
import 'package:flutter_app/pages/vocabularyExercise.dart';
import 'package:flutter_app/pages/readingExercise.dart';
import 'package:flutter_app/pages/questionAnswerExercise.dart';
import 'package:flutter_app/pages/vocabularyChapter.dart';
import 'package:flutter_app/utils/exercise_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:flutter_app/pages/verbConjugation.dart';
import 'package:flutter_app/pages/writingExercise.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math' as math;
import 'package:cloud_functions/cloud_functions.dart';

class JumpingDotsLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final double spacing;

  const JumpingDotsLoadingIndicator({
    Key? key,
    this.color = Colors.black,
    this.size = 7.0,
    this.spacing = 1.5,
  }) : super(key: key);

  @override
  _JumpingDotsLoadingIndicatorState createState() => _JumpingDotsLoadingIndicatorState();
}

class _JumpingDotsLoadingIndicatorState
    extends State<JumpingDotsLoadingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1600),
        vsync: this,
      ),
    );

    _animations = _animationControllers
        .map((controller) =>
            Tween<double>(begin: 0, end: math.pi * 2).animate(controller))
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _animationControllers[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return 
    Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
      Container(
        margin: const EdgeInsets.only(left: 85),
        width: 45,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: widget.color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Container(
                  padding: EdgeInsets.all(widget.spacing),
                  child: Transform.translate(
                    offset: Offset(0, math.sin(_animations[index].value) * 6),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        )
      )
    ]);
  }
}

class ExercisePageWrapper extends StatelessWidget {
  final Widget child;

  const ExercisePageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          iconSize: 40,
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: child,
    );
  }
}

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  Logger logger = Logger();
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final functions = FirebaseFunctions.instance;
  int _receivedMessages = 0;
  bool _chatDisabled = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  void _handleOptionSelected(UserProvider userProvider, String option) {
    
    if (option == "Generate a new exercise") {
      _showExerciseDialog(userProvider);
    } else if (option == "Upload an image") {
      _uploadImage(userProvider);
    } else {
      _handleSubmitted(option);
    }
  }

  Future<void> _submitImage(UserProvider userProvider, String imageName, String type, String level) async {
    final req = {
      'type': int.parse(type),
      'level': userProvider.activeLevel,
      'language': userProvider.activeLanguage,
      'gcsFileName': "userFiles/${FirebaseAuth.instance.currentUser!.uid}/$imageName",
    };

    setState(() {
      _chatDisabled = true;
      _isProcessing = true;
    });

    try {
      var response = await functions.httpsCallable('transform').call(req);

      if (response.data['error'] != null) {
        ChatMessage errorMessage = ChatMessage(
          text: response.data['error'],
          isUserMessage: false,
        );

        setState(() {
          _messages.insert(0, errorMessage);
          _isProcessing = false;
          _chatDisabled = false;
        });
        return;
      }

      if (response.data != null) {
        final responseBody = response.data;
        String path = responseBody['path'];

        DocumentSnapshot exercise = await FirebaseFirestore.instance.doc(path).get();
        Map<String,dynamic> exerciseData = exercise.data() as Map<String, dynamic>;

        // Create an exercise message
        ChatMessage exerciseMessage = ChatMessage(
          text: "Exercise: ${responseBody['data']['title']}",
          isUserMessage: false,
          exerciseData: exerciseData,
        );

        setState(() {
          _isProcessing = false;
          _messages.insert(0, exerciseMessage);
          _receivedMessages++;
          if (_receivedMessages >= 4) {
            _chatDisabled = true;
          }
          else {
            _chatDisabled = false;
          }
        });
      }
    } catch (e) {
      logger.e(e);
      setState(() {
        _isProcessing = false;
        _chatDisabled = false;
        _messages.insert(0, const ChatMessage(
          text: 'Error: Could not retrieve response',
          isUserMessage: false,
        ));
      });
    }
  }

  Future<void> _uploadImage(UserProvider userProvider) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    final String level = userProvider.activeLevel ?? '';

    

    if (image != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child("userFiles/${FirebaseAuth.instance.currentUser!.uid}/$fileName");
      int selectedType = 0; // Default to the first option

      final List<String> exerciseTypes = [
        'Informational',
        'Fill-in-the-blank',
        'Conjugation',
        'Fill-in-the-blank MC',
        'Vocabulary Matching',
        'Reading',
        'Question Answering',
        'Vocabulary',
        'Conjugation Exercise',
        'Writing',
      ];

      if (mounted) {
      showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Enter Exercise Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<int>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: exerciseTypes.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  Padding(padding: const EdgeInsets.only(top: 15),
                  child:
                    Text(
                      'Level: $level',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  ],
                ),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Submit'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _submitImage(
                        userProvider,
                        fileName,
                        selectedType.toString(), // Pass the selected type as a string
                        level
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      try {
        late String downloadURL;
        late Uint8List imageData;

        if (kIsWeb) {
          // For web
          imageData = await image.readAsBytes();
          await ref.putData(imageData, SettableMetadata(contentType: 'image/png'));
        } else {
          // For mobile
          await ref.putFile(File(image.path));
        }

        // Get download URL
        downloadURL = await ref.getDownloadURL();

        // Encode image to base64
        String base64Image = base64Encode(imageData);

        // Create a message with the download URL and base64 string
        ChatMessage message = ChatMessage(
          text: "Image uploaded successfully\nURL: $downloadURL\nBase64: ${base64Image.substring(0, 50)}...", // Truncated for brevity
          isUserMessage: true,
          isImage: true,
        );

        setState(() {
          _messages.insert(0, message);
        });

        // You can send this information to your chat endpoint if needed
        // _handleSubmitted("Image uploaded: $downloadURL");
      } catch (e) {
        logger.e("Error uploading image: $e");
        ChatMessage errorMessage = ChatMessage(
          text: 'Error uploading image: $e',
          isUserMessage: false,
        );
        setState(() {
          _messages.insert(0, errorMessage);
        });
      }
    }
  }



  void _showExerciseDialog(UserProvider userProvider) {
  final TextEditingController descriptionController = TextEditingController();
  final String level = userProvider.activeLevel ?? '';
  int selectedType = 0; // Default to the first option

  final List<String> exerciseTypes = [
    'Informational',
    'Fill-in-the-blank',
    'Conjugation',
    'Fill-in-the-blank MC',
    'Vocabulary Matching',
    'Reading',
    'Question Answering',
    'Vocabulary',
    'Conjugation Exercise',
    'Writing',
  ];

  if (mounted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Exercise Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButtonFormField<int>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: exerciseTypes.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  Padding(padding: const EdgeInsets.only(top: 15),
                  child: 
                    Text(
                      'Level: $level',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    )
                  ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _submitExercise(
                      userProvider,
                      descriptionController.text,
                      selectedType.toString(), // Pass the selected type as a string
                      level,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}


  void _submitExercise(UserProvider userProvider, String description, String type, String level) async {
    setState(() {
      _chatDisabled = true;
    });
    final req = {
      'type': int.parse(type),
      'description': description,
      'level': userProvider.activeLevel,
      'language': userProvider.activeLanguage,
    };

    ChatMessage message = ChatMessage(
      text: description,
      isUserMessage: true,
    );
    setState(() {
      _messages.insert(0, message);
      _isProcessing = true;
    });

    try {

      var response = await functions.httpsCallable('generateChapter').call(req);

      print(response.data['path']);
      if (response.data['error'] != null) {
        ChatMessage errorMessage = ChatMessage(
          text: response.data['error'],
          isUserMessage: false,
        );

        setState(() {
          _messages.insert(0, errorMessage);
          _isProcessing = false;
          _chatDisabled = false;
        });
        return;
      }

      if (response.data != null) {
        final responseBody = response.data;
        Map<String,dynamic> exerciseData = responseBody['data'];

        // Create an exercise message
        ChatMessage exerciseMessage = ChatMessage(
          text: "Exercise: $description",
          isUserMessage: false,
          exerciseData: exerciseData,
        );

        setState(() {
          _messages.insert(0, exerciseMessage);
          _isProcessing = false;
          _receivedMessages++;
          if (_receivedMessages >= 4) {
            _chatDisabled = true;
          }
        });
      }
    } catch (e) {
      logger.e(e.toString());

      setState(() {
        _messages.insert(0, const ChatMessage(
          text: 'Error: Could not retrieve response',
          isUserMessage: false,
        ));
        _isProcessing = false;
        _chatDisabled = false;
      });
    }
    setState(() {
      _isProcessing = false;
      _chatDisabled = false;
    });
  }

  void _navigateToExercise(Map<String, dynamic> data) async {
    Widget exercisePage = getExercisePageWidget(
      type: data['type'],
      data: data,
      onExerciseAttempted: (bool success) {
        // Handle the boolean parameter `success` as needed
        return false;
      },
    );

    Navigator.push(
      context,
      CustomPageRoute(child: ExercisePageWrapper(child: exercisePage)),
    );
  }

  void _handleSubmitted(String text) async {
    if (_chatDisabled) return;

    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUserMessage: true,
    );
    setState(() {
      _messages.insert(0, message);
      _chatDisabled = true;
      _isProcessing = true;
    });

    try {

    var response = await functions.httpsCallable('chat').call({
      'messages': _messages.map((m) => {'text': m.text, 'role': m.isUserMessage ? 'user' : 'model'}).toList(),
    });


    if (response.data['error'] != null) {
      ChatMessage errorMessage = ChatMessage(
        text: response.data['error'],
        isUserMessage: false,
      );

      setState(() {
        _isProcessing = false;
        _chatDisabled = false;
        _messages.insert(0, errorMessage);
      });
      return;
    }

    if (response.data != null) {
      final responseBody = response.data;
      String replyText = responseBody['text'];

      ChatMessage replyMessage = ChatMessage(
        text: replyText,
        isUserMessage: false,
      );

      setState(() {
        _messages.insert(0, replyMessage);
        _isProcessing = false;
        _receivedMessages++;
        if (_receivedMessages >= 4) {
          _chatDisabled = true;
        }
        else {
          _chatDisabled = false;
        }
      });
    } 
  } catch (e) {
      logger.e(e.toString());
      setState(() {
        _isProcessing = false;
        _chatDisabled = false;
        _messages.insert(0, const ChatMessage(
          text: 'Error: Could not retrieve response',
          isUserMessage: false,
        ));
      });
    }
  }

  void _refreshChat() {
    setState(() {
      _messages.clear();
      _receivedMessages = 0;
      _chatDisabled = false;
      _isProcessing = false;
    });
  }

  @override
Widget build(BuildContext context) {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      String? origin;
            String? target;

            switch (userProvider.activeLanguage) {
              case 'eng_de':
                origin = 'English';
                target = 'German';
                break;
              case 'eng_fr':
                origin = 'English';
                target = 'French';
                break;
              case 'fr_de':
                origin = 'French';
                target = 'German';
                break;
            }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Chat',
                style: const TextStyle(
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
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, int index) => _messages[index],
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 8),
              const JumpingDotsLoadingIndicator(color: Colors.blueGrey),
              const SizedBox(height: 8),
            ],
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(userProvider, target),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildTextComposer(UserProvider userProvider, String? target) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20.0),
      color: Colors.grey[200],
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.photo_camera),
          onPressed: _chatDisabled ? null : () {
            _handleOptionSelected(userProvider, "Upload an image");
          },
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 16.0),
            child: TextField(
              controller: _textController,
              onSubmitted: _chatDisabled ? null : _handleSubmitted,
              decoration: const InputDecoration.collapsed(hintText: "Send a message"),
              enabled: !_chatDisabled,
            ),
          ),
        ),
        PopupMenuButton<String>(
          enabled: !_chatDisabled,
          icon: const Icon(Icons.more_vert),
          onSelected: (String choice) {


            // Handle the selected option
            switch (choice) {
              case 'Generate':
                _handleOptionSelected(userProvider, "Generate a new exercise");
                break;
              case 'Language':
                _handleOptionSelected(userProvider, "Let's chat in $target");
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Generate',
              child: Text('Generate a new exercise'),
            ),
            PopupMenuItem<String>(
              value: 'Language',
              child: Text("Let's chat in $target"),
            ),
          ],
        ),
        IconButton(
          icon: Icon(_chatDisabled ? Icons.refresh : Icons.send),
          onPressed: _chatDisabled ? _refreshChat : () => _handleSubmitted(_textController.text),
        ),
      ],
    ),
  );
}
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final Map<String, dynamic>? exerciseData;
  final bool isImage;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUserMessage,
    this.exerciseData,
    this.isImage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: exerciseData != null
            ? () async => (context as Element)
                .findAncestorStateOfType<ChatScreenState>()!
                ._navigateToExercise(exerciseData!)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16.0, left: 16.0),
              padding: const EdgeInsets.all(5.0),
              child: CircleAvatar(child: Text(isUserMessage ? 'User' : 'Bob')),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isUserMessage ? 'User' : 'Assistant'),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: exerciseData != null
                          ? Colors.lightBlue[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: isImage
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Image uploaded successfully'),
                              const SizedBox(height: 8),
                              Text(
                                text,
                                style: TextStyle(fontSize: 12),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : MarkdownBody(
                            data: text,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontWeight: exerciseData != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}