// frontend/lib/features/challenge/screens/challenge_game_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/challenge_service.dart';
import '../../../models/challenge_model.dart';
import '../../../core/network/api_exception.dart';
class ChallengeGameScreen extends StatefulWidget {
  final String challengeId;
  final List<ChallengeQuestion> questions;
  final int timeLimit;
  final String levelName;
  final Color accentColor;

  const ChallengeGameScreen({
    super.key,
    required this.challengeId,
    required this.questions,
    required this.timeLimit,
    this.levelName = '闯关',
    this.accentColor = const Color(0xFF4D7CFF),
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  final ChallengeService _challengeService = ChallengeService();

  int _currentIndex = 0;
  final List<ChallengeAnswer> _answers = [];
  late int _remainingSeconds;
  bool _isLoading = false;
  int? _selectedIndex;
  Timer? _timer;
  int _combo = 0;
  int _score = 0;
  bool _submitted = false;

  static const _headerBlue = Color(0xFF5B86F8);
  static const _bg = Color(0xFFF7F8FA);

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isLoading) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        if (mounted) setState(() => _remainingSeconds = 0);
        _submitAnswers();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int selectedIndex) {
    setState(() => _selectedIndex = selectedIndex);

    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _nextQuestion(selectedIndex);
    });
  }

  void _nextQuestion(int selectedIndex) {
    final currentQuestion = widget.questions[_currentIndex];
    final correct = selectedIndex == currentQuestion.correctIndex;
    if (correct) {
      _combo += 1;
      _score += 10 + _combo * 2;
    } else {
      _combo = 0;
    }

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
    if (_submitted) return;
    _submitted = true;
    _timer?.cancel();
    if (mounted) setState(() => _isLoading = true);

    try {
      final result = await _challengeService.submitChallenge(
        challengeId: widget.challengeId,
        answers: _answers,
      );

      if (mounted) context.go('/challenge-result', extra: result);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('暂无题目')));
    }

    final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;
    final qLabel = _currentIndex + 1;
    final total = widget.questions.length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _topHeader(progress),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      children: [
                        _questionCard(currentQuestion, qLabel),
                        const SizedBox(height: 20),
                        Text(
                          '$qLabel / $total 题',
                          style: const TextStyle(color: Color(0xFF636E72), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader(double progress) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 16),
      decoration: const BoxDecoration(
        color: _headerBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _timer?.cancel();
                  context.pop();
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  widget.levelName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E5BFF)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.orange.shade300, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '连击 $_combo',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '得分: $_score',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _questionCard(ChallengeQuestion q, int qLabel) {
    final hint = q.question.isNotEmpty ? q.question : '选择正确的中文释义';
    final useGrid = q.options.length == 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '第 $qLabel 题',
            style: const TextStyle(color: Color(0xFF636E72), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Text(
            q.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF636E72), fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (useGrid)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: List.generate(
                q.options.length,
                (i) => _optionTile(q.options[i], i),
              ),
            )
          else
            ...List.generate(
              q.options.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _optionTileFullWidth(q.options[i], i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionTile(String text, int index) {
    final sel = _selectedIndex == index;
    return GestureDetector(
      onTap: _selectedIndex == null && !_isLoading ? () => _selectAnswer(index) : null,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? widget.accentColor : const Color(0xFFE0E0E0),
            width: sel ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: sel ? widget.accentColor : const Color(0xFF636E72),
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _optionTileFullWidth(String text, int index) {
    final sel = _selectedIndex == index;
    return GestureDetector(
      onTap: _selectedIndex == null && !_isLoading ? () => _selectAnswer(index) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? widget.accentColor : const Color(0xFFE0E0E0),
            width: sel ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: sel ? widget.accentColor : const Color(0xFF333333),
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
