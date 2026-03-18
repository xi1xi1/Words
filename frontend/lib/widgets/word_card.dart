import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

class WordCard extends StatelessWidget {
  final String word;
  final String phonetic;
  final String meaning;
  final String? example;

  const WordCard({
    super.key,
    required this.word,
    required this.phonetic,
    required this.meaning,
    this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                word,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+ 生词本',
                  style: TextStyle(color: AppColors.primaryLight, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            phonetic,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meaning,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (example != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                example!,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () {}, child: const Text('查看详情 >')),
          ),
        ],
      ),
    );
  }
}
