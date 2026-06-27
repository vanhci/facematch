import 'dart:io';
import 'dart:math' as math;
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

  @override
  Widget build(BuildContext context) {
    final hasBefore = widget.beforeImage != null;
    final hasAfter = widget.afterImage != null;

    if (!hasBefore && !hasAfter) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            '暂无对比图',
            style: TextStyle(color: AppColors.neutral400),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.2; // 5:6 aspect ratio

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                    errorBuilder: (_, __, ___) => Container(
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
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.neutral200,
                          ),
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
                            child: Container(
                              width: 2,
                              color: Colors.white,
                            ),
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
        borderRadius: BorderRadius.circular(8),
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
