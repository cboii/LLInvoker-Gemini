import 'package:flutter/material.dart';

class AlertMessage extends StatelessWidget {
  final String title;
  final String message;


  const AlertMessage({required this.message, required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
  }

}
