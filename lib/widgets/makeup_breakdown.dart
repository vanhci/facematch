import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MakeupBreakdown extends StatelessWidget {
  final Map<String, String> analysis;
  final Set<String>? selectedCategories;
  final void Function(String)? onToggle;

  const MakeupBreakdown({
    super.key,
    required this.analysis,
    this.selectedCategories,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final categories = analysis.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...categories.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryCard(
              title: entry.key,
              description: entry.value,
              selected: selectedCategories?.contains(entry.key) ?? true,
              onToggle: onToggle != null ? () => onToggle!(entry.key) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onToggle;

  const _CategoryCard({
    required this.title,
    required this.description,
    this.selected = true,
    this.onToggle,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _copyDescription() async {
    final text = '${widget.title}: ${widget.description}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制分析内容'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  IconData _icon(String title) {
    switch (title) {
      case '底妆':
        return Icons.face_outlined;
      case '眼妆':
        return Icons.visibility_outlined;
      case '眉妆':
        return Icons.brush_outlined;
      case '腮红':
        return Icons.favorite_outline;
      case '唇妆':
        return Icons.water_drop_outlined;
      case '修容':
        return Icons.tune_outlined;
      case '发型':
        return Icons.auto_fix_high_outlined;
      case '配饰':
        return Icons.diamond_outlined;
      default:
        return Icons.colorize_outlined;
    }
  }

  Color _iconBg(String title) {
    switch (title) {
      case '底妆':
        return const Color(0xFFFFE8EC);
      case '眼妆':
        return const Color(0xFFFFF3D6);
      case '眉妆':
        return const Color(0xFFE8F5E9);
      case '腮红':
        return const Color(0xFFFFE8F0);
      case '唇妆':
        return const Color(0xFFE3F2FD);
      case '修容':
        return const Color(0xFFF3E5F5);
      case '发型':
        return const Color(0xFFFCE4EC);
      case '配饰':
        return const Color(0xFFFFF8E1);
      default:
        return AppColors.neutral100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      onLongPress: _copyDescription,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.9),
              const Color(0xFFFFF5F5).withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (widget.onToggle != null)
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: widget.selected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Icon(
                          widget.selected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: widget.selected
                              ? AppColors.primary
                              : AppColors.neutral400,
                        ),
                      ),
                    ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconBg(widget.title),
                      borderRadius: BorderRadius.circular(AppRadius.iconBg),
                    ),
                    child: Icon(
                      _icon(widget.title),
                      size: 20,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _heightAnimation,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  widget.description.isEmpty ? '暂无详细分析' : widget.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.neutral500,
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
