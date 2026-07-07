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

  Future<void> _share(BuildContext context, MatchProvider provider) async {
    final resultImage = provider.resultImage;
    if (resultImage == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final resBytes = await resultImage.readAsBytes();
      final resCodec = await ui.instantiateImageCodec(resBytes);
      final resFrame = await resCodec.getNextFrame();
      final resImg = resFrame.image;

      final refImage = provider.referenceImage;
      ui.Image? refImg;
      if (refImage != null) {
        final refCodec = await ui.instantiateImageCodec(await refImage.readAsBytes());
        final refFrame = await refCodec.getNextFrame();
        refImg = refFrame.image;
      }

      String path = resultImage.path;
      if (refImg != null) {
        const targetH = 600.0;
        const gap = 8.0;
        final refW = (refImg.width * targetH / refImg.height).toInt();
        final resW = (resImg.width * targetH / resImg.height).toInt();
        final totalW = (refW + gap + resW).toDouble();

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalW, targetH));
        canvas.drawRect(Rect.fromLTWH(0, 0, totalW, targetH), Paint()..color = Colors.white);

        canvas.drawImageRect(refImg, Rect.fromLTWH(0, 0, refImg.width.toDouble(), refImg.height.toDouble()),
            Rect.fromLTWH(0, 0, refW.toDouble(), targetH), Paint());
        canvas.drawImageRect(resImg, Rect.fromLTWH(0, 0, resImg.width.toDouble(), resImg.height.toDouble()),
            Rect.fromLTWH(refW + gap, 0, resW.toDouble(), targetH), Paint());

        final picture = recorder.endRecording();
        final composite = await picture.toImage(totalW.toInt(), targetH.toInt());
        final byteData = await composite.toByteData(format: ui.ImageByteFormat.png);
        refImg.dispose(); resImg.dispose(); composite.dispose();
        path = '${dir.path}/share_$ts.png';
        await File(path).writeAsBytes(byteData!.buffer.asUint8List());
      } else {
        resImg.dispose();
      }
      refImg?.dispose();
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
                Stack(
                  children: [
                    ComparisonSlider(
                      beforeImage: provider.historyRefImage ?? provider.historySelfieImage ?? provider.selfieImage ?? provider.referenceImage,
                      beforeLabel: provider.historySelfieImage != null ? '原图' : provider.selfieImage != null ? '原图' : '参考妆',
                      afterLabel: '仿妆',
                    ),
                    if (provider.isHistoryLoading || provider.isGenerating)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _ActionCard(
                      icon: Icons.save_outlined, label: '保存', color: AppColors.primary,
                      onTap: () async {
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
                      onTap: () => _share(context, provider),
                    )),
                  ],
                ),
                const SizedBox(height: 32),
                if (provider.analysis != null) ...[
                  if (provider.referenceImage != null)
                    _ReferenceCard(referenceImage: provider.referenceImage!),
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

class _ReferenceCard extends StatelessWidget {
  final File referenceImage;
  const _ReferenceCard({required this.referenceImage});

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(referenceImage, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _showFullImage(context),
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
                child: Image.file(referenceImage, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('分析基于此参考妆容', style: TextStyle(fontSize: 13, color: AppColors.neutral500)),
              ),
              Icon(Icons.zoom_in_rounded, size: 18, color: AppColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
