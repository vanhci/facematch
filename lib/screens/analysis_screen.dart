import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/makeup_breakdown.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F0), Color(0xFFFCF5F5)], // 粉白渐变延续
          ),
        ),
        child: SafeArea(
          child: Consumer<MatchProvider>(
            builder: (context, provider, _) {
              if (provider.analysis == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.face_retouching_natural_outlined,
                        size: 64,
                        color: AppColors.neutral300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '还没有妆容分析数据',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '先进行一次仿妆看看吧',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutral300,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                                '精确AI分析参考妆容',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MakeupBreakdown(
                      analysis: provider.analysis!.toCategoryMap(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
