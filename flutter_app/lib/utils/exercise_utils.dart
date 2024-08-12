import 'package:flutter/material.dart';
import 'package:flutter_app/pages/theory.dart';
import 'package:flutter_app/pages/fillInTheBlank.dart';
import 'package:flutter_app/pages/conjugationExercise.dart';
import 'package:flutter_app/pages/fillInTheBlankMutlipleChoice.dart';
import 'package:flutter_app/pages/vocabularyExercise.dart';
import 'package:flutter_app/pages/readingExercise.dart';
import 'package:flutter_app/pages/questionAnswerExercise.dart';
import 'package:flutter_app/pages/vocabularyChapter.dart';
import 'package:flutter_app/pages/verbConjugation.dart';
import 'package:flutter_app/pages/writingExercise.dart';

Widget getExercisePageWidget({
  required int type,
  required Map<String, dynamic> data,
  required Function(bool) onExerciseAttempted,
}) {
  final key = ValueKey('${data['id']}-$type'); // Ensure a unique key for each type

  switch (type) {
    case 0:
      return TheorySection(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 1:
      return FillInTheBlank(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 2:
      return ConjugationPage(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 3:
      return FillInTheBlankMultipleChoice(key: key, data: data,  onExerciseAttempted: onExerciseAttempted);
    case 4:
      return VocabularyExercise(key: key, data: data, onExerciseAttempted: onExerciseAttempted) ;
    case 5:
      return ReadingExercise(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 6:
      return QuestionAnswerExercise(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 7:
      return VocabularyChapter(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 8:
      return VerbConjugationPage(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    case 9:
      return WritingExercise(key: key, data: data, onExerciseAttempted: onExerciseAttempted);
    default:
      return Center(child: Text('Unknown exercise type: $type'));
  }
}
