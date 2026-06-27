import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/makeup_analysis.dart';

abstract class MakeupApi {
  Future<MakeupAnalysis> analyzeMakeup(File referenceImage);

  Future<String> transferMakeup({
    required File targetImage,
    required String analysis,
  });
}

class ApiService implements MakeupApi {
  // Production API endpoint via Cloudflare Tunnel
  static const _baseUrl = 'https://facematch.vanhci.top';

  final Dio _dio;
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );

  /// Analyze reference makeup image.
  @override
  Future<MakeupAnalysis> analyzeMakeup(File referenceImage) async {
    try {
      final formData = FormData.fromMap({
        'reference_image': await MultipartFile.fromFile(
          referenceImage.path,
          filename: 'reference.jpg',
        ),
      });
      final resp = await _dio.post('/api/v1/analyze', data: formData);
      final json = resp.data as Map<String, dynamic>;
      final analysisRaw = json['analysis'];
      final analysisStr = (analysisRaw is String)
          ? analysisRaw
          : (analysisRaw is Map)
          ? jsonEncode(analysisRaw)
          : analysisRaw.toString();
      // Parse the JSON string from the API response
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
      throw const FormatException('AI 返回的数据格式异常，请重试');
    } catch (e) {
      debugPrint('analyzeMakeup error: $e');
      rethrow;
    }
  }

  /// Generate makeup transfer result.
  @override
  Future<String> transferMakeup({
    required File targetImage,
    required String analysis,
  }) async {
    try {
      final formData = FormData.fromMap({
        'selfie_image': await MultipartFile.fromFile(
          targetImage.path,
          filename: 'selfie.jpg',
        ),
        'analysis': analysis,
      });
      final resp = await _dio.post('/api/v1/transfer', data: formData);
      final json = resp.data as Map<String, dynamic>;
      // Download result image from URL
      final imgResp = await Dio().get(
        json['result_url'] as String,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final tempDir = Directory.systemTemp;
      final outputPath =
          '${tempDir.path}/facematch_result_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outputPath).writeAsBytes(imgResp.data as List<int>);
      return outputPath;
    } catch (e) {
      debugPrint('transferMakeup error: $e');
      rethrow;
    }
  }
}
