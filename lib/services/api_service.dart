import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/makeup_analysis.dart';

class MakeupTransferResult {
  final String filePath;
  final String? resultUrl;
  MakeupTransferResult({required this.filePath, this.resultUrl});
}

abstract class MakeupApi {
  Future<MakeupAnalysis> analyzeMakeup(
    File referenceImage, [
    String userId = '',
  ]);
  Future<MakeupTransferResult> transferMakeup({
    required File targetImage,
    required String analysis,
    String userId = '',
  });
}

class ApiService implements MakeupApi {
  static const _baseUrl = 'https://facematch.vanhci.top';

  final Dio _dio;
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  Dio get dio => _dio;

  ApiService._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );

  @override
  Future<MakeupAnalysis> analyzeMakeup(
    File referenceImage, [
    String userId = '',
  ]) async {
    try {
      final formData = FormData.fromMap({
        'reference_image': await MultipartFile.fromFile(
          referenceImage.path,
          filename: 'reference.jpg',
        ),
        if (userId.isNotEmpty) 'user_id': userId,
      });
      final resp = await _dio.post('/api/v1/analyze', data: formData);
      final json = resp.data as Map<String, dynamic>;
      final analysisRaw = json['analysis'];
      final analysisStr = (analysisRaw is String)
          ? analysisRaw
          : (analysisRaw is Map)
          ? jsonEncode(analysisRaw)
          : analysisRaw.toString();
      final jsonStart = analysisStr.indexOf('{');
      final jsonEnd = analysisStr.lastIndexOf('}') + 1;
      if (jsonStart < 0 || jsonEnd <= jsonStart) {
        throw const FormatException('AI 返回的数据格式异常，请重试');
      }
      final jsonBody = analysisStr.substring(jsonStart, jsonEnd);
      return MakeupAnalysis.fromJson(
        jsonDecode(jsonBody) as Map<String, dynamic>,
      );
    } on FormatException {
      debugPrint('analyzeMakeup: AI returned malformed JSON');
      rethrow;
    } catch (e) {
      debugPrint('analyzeMakeup error: $e');
      rethrow;
    }
  }

  @override
  Future<MakeupTransferResult> transferMakeup({
    required File targetImage,
    required String analysis,
    String userId = '',
  }) async {
    try {
      final formData = FormData.fromMap({
        'selfie_image': await MultipartFile.fromFile(
          targetImage.path,
          filename: 'selfie.jpg',
        ),
        'analysis': analysis,
        if (userId.isNotEmpty) 'user_id': userId,
      });
      final resp = await _dio.post('/api/v1/transfer', data: formData);
      final json = resp.data as Map<String, dynamic>;

      final resultUrl = json['result_url'] as String?;

      // Prefer base64 image data from backend
      final base64Data = json['result_image_base64'] as String?;
      if (base64Data != null && base64Data.isNotEmpty) {
        final tempDir = Directory.systemTemp;
        final outputPath =
            '${tempDir.path}/facematch_result_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(outputPath).writeAsBytes(base64Decode(base64Data));
        return MakeupTransferResult(filePath: outputPath, resultUrl: resultUrl);
      }

      // Fallback: download from URL
      if (resultUrl == null) throw Exception('No result URL from backend');
      final downloadUrl = resultUrl.startsWith('/') ? '$_baseUrl$resultUrl' : resultUrl;
      final imgResp = await Dio().get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final tempDir = Directory.systemTemp;
      final outputPath =
          '${tempDir.path}/facematch_result_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outputPath).writeAsBytes(imgResp.data as List<int>);
      return MakeupTransferResult(filePath: outputPath, resultUrl: resultUrl);
    } catch (e) {
      debugPrint('transferMakeup error: $e');
      rethrow;
    }
  }
}
