// frontend/lib/features/challenge/screens/challenge_result_screen.dart
import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';

class ChallengeResultScreen extends StatelessWidget {
  final ChallengeSubmitResponse result;

  const ChallengeResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isPass = result.correctCount >= result.totalCount * 0.6;
    final int correctRatePercent = (result.accuracy * 100).toInt();

    return Scaffold(
      backgroundColor: isPass ? Colors.green.shade50 : Colors.orange.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // 结果头部
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: isPass ? Colors.green : Colors.orange,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPass
                            ? Icons.emoji_events
                            : Icons.sentiment_dissatisfied,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPass ? '闯关成功！' : '再接再厉！',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPass ? '恭喜你完成挑战' : '差一点就成功了，再试一次吧',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 成绩卡片
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 得分卡片
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildScoreItem(
                            '得分',
                            '${result.score}',
                            const Color(0xFF4F7CFF),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200,
                          ),
                          _buildScoreItem(
                            '正确率',
                            '$correctRatePercent%',
                            Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200,
                          ),
                          _buildScoreItem(
                            '正确/总数',
                            '${result.correctCount}/${result.totalCount}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 获得的积分
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F43).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFF9F43),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '获得积分',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+${result.addedScore}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9F43),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 累计总积分
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Color(0xFF4F7CFF),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '累计总积分',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${result.totalScore}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // 按钮组
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.popUntil(
                                context,
                                (route) => route.settings.name == '/challenge',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF4F7CFF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '返回',
                              style: TextStyle(color: Color(0xFF4F7CFF)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.popUntil(
                                context,
                                (route) => route.settings.name == '/challenge',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F7CFF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('再玩一次'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
