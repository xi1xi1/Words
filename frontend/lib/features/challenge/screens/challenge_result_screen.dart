// frontend/lib/features/challenge/screens/challenge_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/challenge_model.dart';
import '../../../services/challenge_service.dart';
import '../../../core/network/api_exception.dart';

class ChallengeResultScreen extends StatefulWidget {
  final ChallengeSubmitResponse result;
  final int levelType;
  final String levelName;
  final Color accentColor;

  const ChallengeResultScreen({
    super.key,
    required this.result,
    required this.levelType,
    required this.levelName,
    required this.accentColor,
  });

  @override
  State<ChallengeResultScreen> createState() => _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends State<ChallengeResultScreen> {
  final ChallengeService _challengeService = ChallengeService();

  static const _bg = Color(0xFFF7F8FC);
  static const _navy = Color(0xFF102A56);
  static const _muted = Color(0xFF7D8797);
  static const _primary = Color(0xFF5677F3);
  static const _orange = Color(0xFFFF9A3D);
  static const _green = Color(0xFF61D17A);
  static const _cardBorder = Color(0xFFE6EAF2);
  static const _softCard = Color(0xFFF3F5F9);

  bool _isRestarting = false;

  Future<void> _restartChallenge() async {
    if (_isRestarting) return;
    setState(() => _isRestarting = true);

    try {
      final response = await _challengeService.startChallenge(widget.levelType);
      if (!mounted) return;

      context.go(
        '/challenge-game',
        extra: {
          'challengeId': response.challengeId,
          'questions': response.questions,
          'timeLimit': response.timeLimit,
          'levelType': widget.levelType,
          'levelName': widget.levelName,
          'accentColor': widget.accentColor,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRestarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctRatePercent = (widget.result.accuracy * 100).round();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 18),
              _buildMainCard(correctRatePercent),
              const SizedBox(height: 28),
              _buildPrimaryButton(
                text: '再来一局',
                onTap: _restartChallenge,
                isLoading: _isRestarting,
              ),
              const SizedBox(height: 14),
              _buildSecondaryButton(
                text: '返回闯关',
                onTap: () => context.go('/challenge'),
              ),
              const SizedBox(height: 22),
              TextButton(
                onPressed: () => context.go('/'),
                style: TextButton.styleFrom(
                  foregroundColor: _navy,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('回到首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 106,
          height: 106,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1E3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_outlined,
            color: _orange,
            size: 54,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '挑战完成!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _navy,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.levelName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(int correctRatePercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Text(
            '${widget.result.score}',
            style: const TextStyle(
              fontSize: 74,
              height: 1,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '总得分',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
          ),
          const SizedBox(height: 34),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.gps_fixed_rounded,
                  iconColor: _primary,
                  value: '$correctRatePercent%',
                  label: '正确率',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bolt_rounded,
                  iconColor: _green,
                  value: '${widget.result.correctCount}',
                  label: '答对题数',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: _orange,
                  value: '${widget.result.totalCount}',
                  label: '总题数',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: _softCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(text),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: _cardBorder),
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
