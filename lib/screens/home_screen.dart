import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _runMatch(BuildContext context, MatchProvider provider) async {
    await provider.analyzeOnly();
    if (provider.error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImagePicker(BuildContext context, bool isReference) {
    final provider = context.read<MatchProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(AppRadius.label),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '选择图片',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral800,
                ),
              ),
              const SizedBox(height: 24),
              _PickerOption(
                icon: Icons.camera_alt_outlined,
                label: '拍照',
                onTap: () {
                  Navigator.pop(ctx);
                  if (isReference) {
                    provider.pickReferenceImage(ImageSource.camera);
                  } else {
                    provider.pickSelfieImage(ImageSource.camera);
                  }
                },
              ),
              const SizedBox(height: 12),
              _PickerOption(
                icon: Icons.photo_library_outlined,
                label: '从相册选择',
                onTap: () {
                  Navigator.pop(ctx);
                  if (isReference) {
                    provider.pickReferenceImage(ImageSource.gallery);
                  } else {
                    provider.pickSelfieImage(ImageSource.gallery);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        final hasRef = provider.referenceImage != null;
        final hasSelfie = provider.selfieImage != null;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildAppIcon(),
              const SizedBox(height: 12),
              const Text(
                '颜摹',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownText,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '看见你的妆 · 复制你的美',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.brownLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 28),
              _buildSectionLabel('参考妆容'),
              const SizedBox(height: 12),
              _buildPhotoCard(
                context: context,
                isReference: true,
                hasImage: hasRef,
                image: provider.referenceImage,
                imageUrl: '',
                label: '参考妆容',
                onClear: () => provider.clearReference(),
                onPick: () => _showImagePicker(context, true),
              ),
              const SizedBox(height: 20),
              _buildDividerIcon(),
              const SizedBox(height: 20),
              _buildSectionLabel('我的自拍'),
              const SizedBox(height: 12),
              _buildPhotoCard(
                context: context,
                isReference: false,
                hasImage: hasSelfie,
                image: provider.selfieImage,
                imageUrl: '',
                label: '我的素颜',
                onClear: () => provider.clearSelfie(),
                onPick: () => _showImagePicker(context, false),
              ),
              const SizedBox(height: 28),
              if (provider.canMatch)
                SizedBox(
                  width: 320,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: provider.isAnalyzing || provider.isGenerating
                        ? null
                        : () => _runMatch(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isAnalyzing || provider.isGenerating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('分析中...', style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text('妆容分析',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.gradientRose,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowPink.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.face_retouching_natural, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_florist, color: AppColors.iconPetal, size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.brownDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.favorite, color: AppColors.iconRose, size: 46),
        Positioned(
          left: 24,
          top: 6,
          child: Transform.rotate(
            angle: -0.5,
            child: const Icon(Icons.brush, color: AppColors.iconDark, size: 22),
          ),
        ),
        const Positioned(
          right: 8,
          top: 2,
          child: Icon(Icons.auto_awesome, color: AppColors.iconSparkle, size: 14),
        ),
        const Positioned(
          left: 6,
          bottom: 2,
          child: Icon(Icons.auto_awesome, color: AppColors.iconSparkle, size: 10),
        ),
      ],
    );
  }

  Widget _buildPhotoCard({
    required BuildContext context,
    required bool isReference,
    required bool hasImage,
    required File? image,
    required String imageUrl,
    required String label,
    required VoidCallback onClear,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: hasImage ? null : onPick,
      child: Container(
        width: 320,
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage && image != null)
                Image.file(image, fit: BoxFit.cover)
              else
                Container(
                  color: Colors.white.withValues(alpha: 0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 48, color: AppColors.neutral400),
                        const SizedBox(height: 8),
                        Text(
                          '点击选择${isReference ? '参考妆容' : '素颜自拍'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasImage)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.black54),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.white.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.brownDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (isReference && hasImage)
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: onPick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, size: 14, color: Colors.black54),
                          SizedBox(width: 4),
                          Text('换一张', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.iconBg),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
