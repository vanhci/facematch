import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/makeup_breakdown.dart';
import 'result_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('妆容分析'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral700,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          if (provider.analysis == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    '正在分析妆容...',
                    style: TextStyle(color: AppColors.neutral500),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('妆容分析', style: textTheme.headlineLarge),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8EC),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.iconBg,
                                ),
                              ),
                              child: const Icon(
                                Icons.face_retouching_natural,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI 妆容识别',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutral800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '点击项目可选择是否生成',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      MakeupBreakdown(
                        analysis: provider.analysis!.toCategoryMap(),
                        selectedCategories: provider.selectedCategories,
                        onToggle: (cat) => provider.toggleCategory(cat),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        provider.selectedCategories.isNotEmpty &&
                            !provider.isGenerating
                        ? () async {
                            await provider.generateTransfer();
                            if (context.mounted &&
                                provider.resultImage != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResultScreen(),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.neutral300,
                      disabledForegroundColor: AppColors.neutral400,
                      elevation: 4,
                      shadowColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                    child: provider.isGenerating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            '生成仿妆 (${provider.selectedCategories.length}项)',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(MatchProvider provider, String category) {
    final selected = provider.selectedCategories.contains(category);
    return GestureDetector(
      onTap: () => provider.toggleCategory(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary100.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.iconBg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral300,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.neutral400,
            ),
            const SizedBox(width: 10),
            Text(
              category,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.neutral800 : AppColors.neutral500,
              ),
            ),
            const Spacer(),
            Text(
              '已${selected ? "选" : "选"}',
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
