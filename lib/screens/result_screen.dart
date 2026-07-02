import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comparison_slider.dart';
import '../widgets/makeup_breakdown.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Future<void> _shareComposite(BuildContext context, MatchProvider provider) async {
    final resultImage = provider.resultImage;
    final refImage = provider.referenceImage;
    if (resultImage == null || refImage == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Decode both images
      final refCodec = await ui.instantiateImageCodec(await refImage.readAsBytes());
      final resCodec = await ui.instantiateImageCodec(await resultImage.readAsBytes());
      final refFrame = await refCodec.getNextFrame();
      final resFrame = await resCodec.getNextFrame();
      final refImg = refFrame.image;
      final resImg = resFrame.image;

      // Scale both to same dimensions (fit within target rect, centered)
      const imgW = 300.0;  // fixed width per image
      const targetH = 600.0;
      const gap = 8.0;
      final totalW = (imgW * 2 + gap).toInt();

      // Helper to draw image centered in target rect
      void drawImageCentered(ui.Canvas c, ui.Image img, double x) {
        final scale = (imgW / img.width) < (targetH / img.height) 
            ? imgW / img.width : targetH / img.height;
        final sw = img.width * scale;
        final sh = img.height * scale;
        final ox = x + (imgW - sw) / 2;
        final oy = (targetH - sh) / 2;
        c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            Rect.fromLTWH(ox, oy, sw, sh), Paint());
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalW.toDouble(), targetH));
      canvas.drawRect(Rect.fromLTWH(0, 0, totalW.toDouble(), targetH), Paint()..color = Colors.white);
      
      drawImageCentered(canvas, refImg, 0);
      drawImageCentered(canvas, resImg, imgW + gap);

      final picture = recorder.endRecording();
      final compositeImg = await picture.toImage(totalW, targetH.toInt());
      final byteData = await compositeImg.toByteData(format: ui.ImageByteFormat.png);

      refImg.dispose();
      resImg.dispose();
      compositeImg.dispose();

      final path = '${dir.path}/composite_$ts.png';
      await File(path).writeAsBytes(byteData!.buffer.asUint8List());

      final box = context.findRenderObject() as RenderBox?;
      final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      await Share.shareXFiles([XFile(path)], text: '颜摹仿妆', sharePositionOrigin: rect);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text('仿妆效果', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.neutral800)),
        centerTitle: true,
        backgroundColor: AppColors.bgColor,
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
                ComparisonSlider(
                  beforeImage: provider.selfieImage,
                  afterImage: provider.resultImage,
                  beforeLabel: '原图',
                  afterLabel: '仿妆',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _ActionCard(
                      icon: Icons.save_outlined, label: '保存', color: AppColors.primary,
                      onTap: () async {
                        final provider = context.read<MatchProvider>();
                        if (provider.resultImage != null) {
                          try {
                            await ImageGallerySaver.saveFile(provider.resultImage!.path);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已保存到相册'), behavior: SnackBarBehavior.floating),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating),
                              );
                            }
                          }
                        }
                      },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionCard(
                      icon: Icons.ios_share_outlined, label: '分享', color: AppColors.primary,
                      onTap: () => _shareComposite(context, provider),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionCard(
                      icon: Icons.refresh_outlined, label: '重新选图', color: AppColors.neutral500,
                      onTap: () {
                        provider.reset();
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 32),
                if (provider.analysis != null) ...[
                  if (provider.referenceImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.iconBg),
                              child: Image.file(provider.referenceImage!, width: 48, height: 48, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('分析基于此参考妆容', style: TextStyle(fontSize: 13, color: AppColors.neutral500))),
                          ],
                        ),
                      ),
                    ),
                  MakeupBreakdown(analysis: provider.analysis!.toCategoryMap()),
                ],
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

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.iconBg),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
