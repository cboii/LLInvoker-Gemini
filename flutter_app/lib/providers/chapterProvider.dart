import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';


class ChapterProvider extends ChangeNotifier {
  DocumentReference? _currentChapterRef;
  Map<String, dynamic> _currentChapterData = {};
  DocumentReference? get currentChapterRef => _currentChapterRef;
  Map<String, dynamic> get currentChapterData => _currentChapterData;


  ChapterProvider() {
    _initChapterListener();
  }

  void _initChapterListener() {
    // Add code here
  }

  void updateChapter(DocumentReference chapterRef) async {
    _currentChapterRef = chapterRef;
    Map<String, dynamic> data = await chapterRef.get() as Map<String, dynamic>;
    _currentChapterData = data;
    notifyListeners();
  }

  void updateChapterData(Map<String, dynamic> data) {
    _currentChapterData = data;
    notifyListeners();
  }
}