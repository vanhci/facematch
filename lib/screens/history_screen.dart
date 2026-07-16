import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/match_provider.dart';
import '../screens/result_screen.dart';
import '../theme/app_theme.dart';
import '../models/makeup_analysis.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          '历史记录',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.bgColor,
        elevation: 0,
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          if (!provider.isHistoryLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Icon(
                      Icons.history_outlined,
                      size: 40,
                      color: AppColors.neutral300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有仿妆记录',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '完成一次仿妆后，结果会出现在这里',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral300,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<MatchProvider>().refreshHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final result = provider.history[index];
                return _HistoryCard(result: result);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MatchResult result;
  const _HistoryCard({required this.result});

  void _openResult(BuildContext context) async {
    final provider = context.read<MatchProvider>();
    provider.loadHistoryResult(result);
    final baseUrl = 'https://facematch.vanhci.top';

    // Download images in background after navigation
    _downloadImages(context, provider, baseUrl);

    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ResultScreen()));
    }
  }

  Future<void> _downloadImages(
    BuildContext context,
    MatchProvider provider,
    String baseUrl,
  ) async {
    try {
      if (result.resultImageUrl != null && result.resultImagePath == null) {
        final resp = await Dio().get(
          result.resultImageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        final imgPath =
            '${Directory.systemTemp.path}/history_result_${result.id}.png';
        await File(imgPath).writeAsBytes(resp.data as List<int>);
        provider.setResultImage(File(imgPath));
      }
    } catch (_) {}
    provider.clearHistoryLoading();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${result.createdAt.month}/${result.createdAt.day} ${result.createdAt.hour.toString().padLeft(2, '0')}:${result.createdAt.minute.toString().padLeft(2, '0')}';
    final baseUrl = 'https://facematch.vanhci.top';

    return GestureDetector(
      onTap: () => _openResult(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppColors.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Side-by-side thumbnails: ref + result
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.iconBg),
                child: Container(
                  width: 72,
                  height: 48,
                  color: AppColors.neutral100,
                  child: Row(
                    children: [
                      // Reference image
                      SizedBox(
                        width: 36,
                        height: 48,
                        child: _thumbnail(
                          localPath: result.referenceImagePath,
                          url:
                              result.referenceImageUrl != null &&
                                  result.referenceImageUrl!.isNotEmpty
                              ? '$baseUrl${result.referenceImageUrl}'
                              : null,
                        ),
                      ),
                      // Divider line
                      Container(width: 1, color: AppColors.neutral200),
                      // Result image
                      SizedBox(
                        width: 35,
                        height: 48,
                        child: _thumbnail(
                          localPath: result.resultImagePath,
                          url: result.resultImageUrl,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.status == Status.completed ? '仿妆完成' : '处理中...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.status == Status.completed)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail({String? localPath, String? url}) {
    if (localPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.iconBg),
        child: Image.file(
          File(localPath),
          width: 36,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: 100,
          errorBuilder: (_, _, _) => const Icon(
            Icons.image_outlined,
            size: 16,
            color: AppColors.neutral300,
          ),
        ),
      );
    }
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.iconBg),
        child: Image.network(
          url,
          width: 36,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.image_outlined,
            size: 16,
            color: AppColors.neutral300,
          ),
        ),
      );
    }
    return const Icon(
      Icons.image_outlined,
      size: 16,
      color: AppColors.neutral300,
    );
  }
}
