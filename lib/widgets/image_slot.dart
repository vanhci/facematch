import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ImageSlot extends StatelessWidget {
  final String label;
  final String iconLabel;
  final File? image;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final double size;
  final bool isLoading;

  const ImageSlot({
    super.key,
    required this.label,
    required this.iconLabel,
    this.image,
    required this.onTap,
    this.onClear,
    this.size = 160,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoading();
    }
    if (image != null) {
      return _buildImage();
    }
    return _buildEmpty();
  }

  Widget _buildLoading() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary300,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              image!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.neutral200,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.neutral400,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        if (onClear != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.neutral300,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary500,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              iconLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
