import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
          title: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
  }

}

