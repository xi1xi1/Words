// frontend/lib/features/challenge/screens/challenge_game_screen.dart
import 'package:flutter/material.dart';
import '../../../services/challenge_service.dart';
import '../../../models/challenge_model.dart';
import '../../../core/network/api_exception.dart';
import 'challenge_result_screen.dart';

class ChallengeGameScreen extends StatefulWidget {
  final String challengeId;
  final List<ChallengeQuestion> questions;
  final int timeLimit;

  const ChallengeGameScreen({
    super.key,
    required this.challengeId,
    required this.questions,
    required this.timeLimit,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  final ChallengeService _challengeService = ChallengeService();

  int _currentIndex = 0;
  List<ChallengeAnswer> _answers = [];
  int _remainingSeconds = 0;
  bool _isLoading = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeLimit;
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _remainingSeconds > 0 && !_isLoading) {
        setState(() {
          _remainingSeconds--;
        });
        return true;
      }
      if (_remainingSeconds == 0 && mounted) {
        _submitAnswers();
        return false;
      }
      return false;
    });
  }

  void _selectAnswer(int selectedIndex) {
    setState(() {
      _selectedIndex = selectedIndex;
    });

    // 自动进入下一题
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _nextQuestion(selectedIndex);
      }
    });
  }

  void _nextQuestion(int selectedIndex) {
    final currentQuestion = widget.questions[_currentIndex];

    _answers.add(
      ChallengeAnswer(
        questionId: currentQuestion.id,
        selectedIndex: selectedIndex,
        timeSpent: widget.timeLimit - _remainingSeconds,
      ),
    );

    if (_currentIndex + 1 < widget.questions.length) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
    } else {
      _submitAnswers();
    }
  }

  Future<void> _submitAnswers() async {
    setState(() => _isLoading = true);

    try {
      final result = await _challengeService.submitChallenge(
        challengeId: widget.challengeId,
        answers: _answers,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeResultScreen(result: result),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('闯关答题'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4F7CFF)),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 计时器
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds < 10
                          ? Colors.red.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _remainingSeconds < 10
                              ? Colors.red
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '剩余时间: $_remainingSeconds秒',
                          style: TextStyle(
                            color: _remainingSeconds < 10
                                ? Colors.red
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 题目
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '以下哪个是正确的中文释义？',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          currentQuestion.word,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 选项
                  ...List.generate(
                    currentQuestion.options.length,
                    (index) => _buildOption(
                      index,
                      currentQuestion.options[index],
                      _selectedIndex,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOption(int index, String text, int? selectedIndex) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: selectedIndex == null && !_isLoading
          ? () => _selectAnswer(index)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F7CFF).withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F7CFF) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF4F7CFF)
                    : Colors.grey.shade200,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? const Color(0xFF4F7CFF) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
