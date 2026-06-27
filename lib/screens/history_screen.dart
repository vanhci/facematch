import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../screens/result_screen.dart';
import '../theme/app_theme.dart';
import '../models/makeup_analysis.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          '历史记录',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.bgColor,
        elevation: 0,
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Icon(
                      Icons.history_outlined,
                      size: 40,
                      color: AppColors.neutral300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有仿妆记录',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '完成一次仿妆后，结果会出现在这里',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral300,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final result = provider.history[index];
              return _HistoryCard(result: result);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MatchResult result;
  const _HistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${result.createdAt.month}/${result.createdAt.day} ${result.createdAt.hour}:${result.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Result thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.iconBg),
                color: AppColors.neutral100,
              ),
              child: result.status == Status.completed
                  ? const Icon(
                      Icons.image_outlined,
                      color: AppColors.neutral300,
                    )
                  : const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary300,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.status == Status.completed ? '仿妆完成' : '处理中...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            ),
            if (result.status == Status.completed)
              GestureDetector(
                onTap: () {
                  final provider = context.read<MatchProvider>();
                  if (result.resultImagePath != null) {
                    provider.loadHistoryResult(result);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ResultScreen()),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(AppRadius.label),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.neutral500,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
