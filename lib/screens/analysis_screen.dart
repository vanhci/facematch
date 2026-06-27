import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/makeup_breakdown.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F0), Color(0xFFF0FFF0)],
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
                      const Text(
                        '还没有妆容分析数据',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '先进行一次仿妆看看吧',
                        style: TextStyle(
                          fontSize: 14,
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
                    const Text(
                      '妆容分析',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF0708D,
                            ).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8EC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.face_retouching_natural,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI 妆容识别',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '精确AI分析参考妆容',
                                style: TextStyle(
                                  fontSize: 12,
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
