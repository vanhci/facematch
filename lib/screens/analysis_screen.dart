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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face_retouching_natural_outlined, size: 64, color: AppColors.neutral300),
                  const SizedBox(height: 16),
                  const Text('还没有妆容分析数据', style: TextStyle(fontSize: 16, color: AppColors.neutral400)),
                  const SizedBox(height: 8),
                  const Text('在仿妆页上传照片进行分析', style: TextStyle(fontSize: 13, color: AppColors.neutral300)),
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8EC),
                                borderRadius: BorderRadius.circular(AppRadius.iconBg),
                              ),
                              child: const Icon(Icons.face_retouching_natural, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI 妆容识别', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.neutral800)),
                                const SizedBox(height: 2),
                                Text('点击项目可选择是否生成', style: TextStyle(fontSize: 13, color: AppColors.neutral500)),
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
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: provider.selectedCategories.isNotEmpty && !provider.isGenerating
                              ? () async {
                                  await provider.generateTransfer();
                                  if (context.mounted && provider.resultImage != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()));
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.isGenerating ? AppColors.primary300 : AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.neutral300,
                            disabledForegroundColor: AppColors.neutral400,
                            elevation: provider.isGenerating ? 0 : 4,
                            shadowColor: provider.isGenerating ? Colors.transparent : AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                          ),
                          child: provider.isGenerating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                                    SizedBox(width: 10),
                                    Text('生成中...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : Text(
                                  '生成仿妆 (${provider.selectedCategories.length}项)',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                    if (provider.isGenerating) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => provider.cancelGeneration(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.neutral600,
                            elevation: 0,
                            side: BorderSide(color: AppColors.neutral300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                          ),
                          child: const Text('取消', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
