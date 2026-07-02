import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import 'analysis_screen.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFFFFF0F5), Color(0xFFFCF5F5), Color(0xFFF5E9ED)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientRose,
                        borderRadius: BorderRadius.circular(AppRadius.iconBg),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '颜摹',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral700,
                          ),
                        ),
                        Text(
                          '看见你的妆 · 复制你的美',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Sign out
                    GestureDetector(
                      onTap: () => context.read<MatchProvider>().signOut(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Icon(
                          Icons.logout,
                          size: 18,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards
              Expanded(
                child: Consumer<MatchProvider>(
                  builder: (context, provider, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // Reference card
                          Expanded(
                            child: _ImageCard(
                              title: '参考妆容',
                              image: provider.referenceImage,
                              label: '选妆容图',
                              onTap: () => _showImagePicker(context, true),
                              onClear: provider.referenceImage != null
                                  ? () => provider.clearReference()
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Selfie card
                          Expanded(
                            child: _ImageCard(
                              title: '我的自拍',
                              image: provider.selfieImage,
                              label: '选自拍/拍照',
                              onTap: () => _showImagePicker(context, false),
                              onClear: provider.selfieImage != null
                                  ? () => provider.clearSelfie()
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Button
                          _buildMatchButton(context, provider),
                          if (provider.error != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _buildError(context, provider),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchButton(BuildContext context, MatchProvider provider) {
    if (provider.isAnalyzing || provider.isGenerating) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: AppColors.gradientRose,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI 正在努力分析...',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Positioned(
                right: 8,
                child: TextButton(
                  onPressed: provider.cancelGeneration,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.canMatch
            ? () => _runMatch(context, provider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.canMatch
              ? AppColors.primary
              : AppColors.neutral300,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.neutral200,
          disabledForegroundColor: AppColors.neutral400,
          elevation: provider.canMatch ? 4 : 0,
          shadowColor: provider.canMatch
              ? AppColors.primary
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: const Text(
          '妆容分析',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, MatchProvider provider) {
    final canRetry =
        provider.canMatch &&
        !provider.isAnalyzing &&
        !provider.isGenerating &&
        provider.error != '已取消生成';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.iconBg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          if (canRetry) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _runMatch(context, provider),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(44, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('重试'),
            ),
          ],
          IconButton(
            onPressed: provider.resetError,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title;
  final File? image;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _ImageCard({
    required this.title,
    required this.image,
    required this.label,
    required this.onTap,
    this.onClear,
  });

  void _showFullImage(BuildContext context, File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Image area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.iconBg),
                  boxShadow: AppColors.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.iconBg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      image != null
                          ? GestureDetector(
                              onTap: () => _showFullImage(context, image!),
                              child: Image.file(image!, fit: BoxFit.cover),
                            )
                          : Container(
                              color: AppColors.neutral50,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: AppColors.neutral300,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.neutral400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      // Image close button (only when image selected)
                      if (image != null && onClear != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: onClear,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      // Solid white overlay label
                      if (image != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(AppRadius.label),
                                topRight: Radius.circular(AppRadius.label),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                image != null ? title : '',
                                style: const TextStyle(
                                  color: AppColors.warmBrown,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
