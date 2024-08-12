import 'package:flutter/material.dart';

class ScoreMessage extends StatelessWidget {
  final String title;
  final int score;
  final int maxScore;

  const ScoreMessage({
    required this.title,
    required this.score,
    this.maxScore = 3,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          _buildStarRating(),
          const SizedBox(height: 10),
        ],
      ),
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

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxScore, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildStar(index < score),
        );
      }),
    );
  }

  Widget _buildStar(bool filled) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Icon(
        Icons.star,
        color: filled ? Colors.amber : Colors.transparent,
        size: 30,
      ),
    );
  }
}