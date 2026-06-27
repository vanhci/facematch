import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ComparisonSlider extends StatefulWidget {
  final File? beforeImage;
  final File? afterImage;
  final String? beforeLabel;
  final String? afterLabel;

  const ComparisonSlider({
    super.key,
    this.beforeImage,
    this.afterImage,
    this.beforeLabel = '原图',
    this.afterLabel = '仿妆',
  });

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  double _position = 0.5;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showHint = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasBefore = widget.beforeImage != null;
    final hasAfter = widget.afterImage != null;

    if (!hasBefore && !hasAfter) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Center(
          child: Text('暂无对比图', style: TextStyle(color: AppColors.neutral400)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.2; // 5:6 aspect ratio

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // After image (bottom layer)
                if (hasAfter)
                  Image.file(
                    widget.afterImage!,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.neutral200,
                      child: const Center(
                        child: Icon(Icons.image, color: AppColors.neutral400),
                      ),
                    ),
                  ),

                // Before image (clipped top layer)
                if (hasBefore)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _position,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: Image.file(
                          widget.beforeImage!,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: AppColors.neutral200),
                        ),
                      ),
                    ),
                  ),

                // Slider handle
                Positioned.fill(
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _position = (_position + details.delta.dx / width)
                            .clamp(0.05, 0.95);
                        _showHint = false;
                      });
                    },
                    child: Stack(
                      children: [
                        // Slider line
                        if (hasBefore && hasAfter)
                          Positioned(
                            left: width * _position - 1,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 2, color: Colors.white),
                          ),

                        // Handle circle
                        if (hasBefore && hasAfter)
                          Positioned(
                            left: width * _position - 18,
                            top: height / 2 - 18,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: AppColors.neutral700,
                                size: 18,
                              ),
                            ),
                          ),

                        // Labels
                        if (hasBefore)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _buildLabel(widget.beforeLabel!),
                          ),
                        if (hasAfter)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _buildLabel(widget.afterLabel!),
                          ),
                        if (hasBefore && hasAfter && _showHint)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 18,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _showHint ? 1 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '左右滑动对比',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppRadius.label),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
