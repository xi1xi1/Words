import 'package:flutter/material.dart';

import '../../models/wordbook_model.dart';
import '../../services/wordbook_service.dart';
import '../network/api_exception.dart';

class WordbookProvider extends ChangeNotifier {
  final WordbookService _service = WordbookService();

  bool _loading = false;
  bool _initialized = false;
  List<WordbookWord> _words = [];

  bool get loading => _loading;
  bool get initialized => _initialized;
  List<WordbookWord> get words => _words;
  int get count => _words.length;

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_initialized && !force) return;
    _loading = true;
    notifyListeners();
    try {
      _words = await _service.getWordbookList();
    } on ApiException {
      _words = [];
    } finally {
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  bool containsWord(int wordId) {
    return _words.any((e) => e.wordId == wordId);
  }

  Future<void> addWord(int wordId) async {
    if (wordId <= 0 || containsWord(wordId)) return;
    await _service.addToWordbook(wordId);
    await load(force: true);
  }

  Future<void> removeWord(int wordId) async {
    await _service.removeFromWordbook(wordId);
    _words = _words.where((e) => e.wordId != wordId).toList();
    notifyListeners();
  }

  void clear() {
    _words = [];
    _loading = false;
    _initialized = false;
    notifyListeners();
  }
}
