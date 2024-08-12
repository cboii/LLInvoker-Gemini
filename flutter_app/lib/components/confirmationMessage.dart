import 'package:flutter/material.dart';

class ConfirmationMessage extends StatelessWidget {
  final String message;



  const ConfirmationMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Confirm Choice', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          ElevatedButton(
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
  }

}
