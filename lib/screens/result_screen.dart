import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comparison_slider.dart';
import '../widgets/makeup_breakdown.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text(
          '仿妆效果',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.neutral700,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comparison slider
                ComparisonSlider(
                  beforeImage: provider.selfieImage,
                  afterImage: provider.resultImage,
                  beforeLabel: '原图',
                  afterLabel: '仿妆',
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.save_outlined,
                        label: '保存',
                        color: AppColors.primary500,
                        onTap: () async {
                          final provider = context.read<MatchProvider>();
                          if (provider.resultImage != null) {
                            try {
                              await ImageGallerySaver.saveFile(
                                provider.resultImage!.path,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已保存到相册'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('保存失败: $e'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.ios_share_outlined,
                        label: '分享',
                        color: AppColors.primary500,
                        onTap: () async {
                          final resultImage = provider.resultImage;
                          if (resultImage == null) return;

                          try {
                            await Share.shareXFiles([
                              XFile(resultImage.path),
                            ], text: '我的颜摹仿妆结果');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('分享失败: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.refresh_outlined,
                        label: '重新选图',
                        color: AppColors.neutral500,
                        onTap: () {
                          provider.reset();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Makeup analysis
                if (provider.analysis != null)
                  MakeupBreakdown(analysis: provider.analysis!.toCategoryMap()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
