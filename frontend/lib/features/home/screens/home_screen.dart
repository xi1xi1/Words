import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../widgets/word_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            // 跳转到个人设置
          },
        ),
        title: const Text('早上好'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学习卡片
            _buildStudyCard(),
            const SizedBox(height: 16),

            // 复习卡片
            _buildReviewCard(),
            const SizedBox(height: 24),

            // 今日推荐
            const Text('今日推荐', style: AppTextStyles.title2),
            const SizedBox(height: 12),
            const WordCard(
              word: 'serendipity',
              phonetic: '/ˌserənˈdɪpəti/',
              meaning: '意外发现珍奇事物的能力；机缘巧合',
              example: 'The discovery of penicillin was a case of serendipity.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日学习',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '50',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('开始学习 >'),
              ),
            ],
          ),
          const Icon(Icons.menu_book, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '待复习',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '128',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('立即复习 >'),
              ),
            ],
          ),
          const Icon(Icons.autorenew, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}
