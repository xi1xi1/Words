// frontend/lib/features/wordbook/screens/wordbook_screen.dart
import 'package:flutter/material.dart';

class WordbookScreen extends StatelessWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生词本')),
      body: const Center(child: Text('生词本页面')),
    );
  }
}
