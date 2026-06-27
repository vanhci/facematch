import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MakeupBreakdown extends StatelessWidget {
  final Map<String, String> analysis;

  const MakeupBreakdown({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final categories = analysis.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '妆容分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryCard(title: entry.key, description: entry.value),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final String description;

  const _CategoryCard({required this.title, required this.description});

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF0708D).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconBg(widget.title),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _icon(widget.title),
                      size: 20,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      gradient: LinearGradient(
                        colors: [Colors.white, const Color(0xFFF5F5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
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
