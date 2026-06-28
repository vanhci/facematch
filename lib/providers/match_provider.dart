import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/makeup_analysis.dart';
import '../services/api_service.dart';

class MatchProvider extends ChangeNotifier {
  final MakeupApi _api;

  MatchProvider({MakeupApi? api}) : _api = api ?? ApiService();

  // Images
  File? _referenceImage;
  File? _selfieImage;
  File? _resultImage;

  // Analysis
  MakeupAnalysis? _analysis;
  bool _isAnalyzing = false;
  bool _isGenerating = false;
  String? _error;
  bool _isCancelled = false;

  // History
  final List<MatchResult> _history = [];
  File? _historyFile;

  // Getters
  File? get referenceImage => _referenceImage;
  File? get selfieImage => _selfieImage;
  File? get resultImage => _resultImage;
  MakeupAnalysis? get analysis => _analysis;
  bool get isAnalyzing => _isAnalyzing;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  List<MatchResult> get history => List.unmodifiable(_history);
  bool get canMatch => _referenceImage != null && _selfieImage != null;

  Future<void> init() async {
    final docDir = await getApplicationDocumentsDirectory();
    _historyFile = File('${docDir.path}/facematch_history.json');
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final file = _historyFile;
    if (file == null || !await file.exists()) return;

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _history
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(MatchResult.fromJson)
              .toList(),
        );
      notifyListeners();
    } catch (e) {
      debugPrint('load history error: $e');
    }
  }

  Future<void> _saveHistory() async {
    final file = _historyFile;
    if (file == null) return;

    try {
      await file.writeAsString(
        jsonEncode(_history.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('save history error: $e');
    }
  }

  /// Pick reference makeup image
  Future<void> pickReferenceImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      final image = File(picked.path);
      _referenceImage = image;
      _error = await _validateImage(image);
      notifyListeners();
    }
  }

  /// Pick selfie image
  Future<void> pickSelfieImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      final image = File(picked.path);
      _selfieImage = image;
      _error = await _validateImage(image, isSelfie: true);
      notifyListeners();
    }
  }

  Future<String?> _validateImage(File image, {bool isSelfie = false}) async {
    if (await image.length() < 10 * 1024) {
      return '图片太小，请选择更清晰的照片';
    }

    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      frame.image.dispose();
      if (width < 200) {
        return isSelfie ? '图片太小，建议使用正面清晰自拍' : '图片太小，建议使用清晰的人像照片';
      }
    } catch (e) {
      debugPrint('validate image error: $e');
    }

    return null;
  }

  /// Remove reference image
  void clearReference() {
    _referenceImage = null;
    _error = null;
    notifyListeners();
  }

  /// Remove selfie image
  void clearSelfie() {
    _selfieImage = null;
    _error = null;
    notifyListeners();
  }

  /// Start the match process: analyze + transfer
  Future<void> startMatch() async {
    if (!canMatch) return;

    _isCancelled = false;
    _isAnalyzing = true;
    _isGenerating = false;
    _resultImage = null;
    _analysis = null;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Analyze reference image
      debugPrint(
        '>>> startMatch: analyzing reference image at ${_referenceImage?.path}',
      );
      debugPrint('>>> startMatch: selfie image at ${_selfieImage?.path}');
      _analysis = await _api.analyzeMakeup(_referenceImage!);
      if (_isCancelled) {
        _finishCancelled();
        return;
      }
      _isAnalyzing = false;
      _isGenerating = true;
      notifyListeners();

      // Step 2: Generate makeup transfer
      final resultPath = await _api.transferMakeup(
        targetImage: _selfieImage!,
        analysis: jsonEncode(_analysis!.toCategoryMap()),
      );
      if (_isCancelled) {
        _finishCancelled();
        return;
      }

      if (resultPath.isNotEmpty) {
        _resultImage = File(resultPath);
      }

      _isGenerating = false;
      notifyListeners();

      // Add to history
      _history.insert(
        0,
        MatchResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          referenceImagePath: _referenceImage?.path,
          selfieImagePath: _selfieImage?.path,
          resultImagePath: _resultImage?.path,
          analysis: _analysis,
          status: Status.completed,
        ),
      );
      await _saveHistory();
      notifyListeners();
    } on FormatException {
      _error = '妆容分析数据异常，请换一张参考图重试';
      _isAnalyzing = false;
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = _isNetworkError(e) ? '网络连接异常，请检查网络后重试' : '分析失败，请重试';
      _isAnalyzing = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('dioexception') ||
        message.contains('socketexception') ||
        message.contains('connection') ||
        message.contains('timeout');
  }

  void _finishCancelled() {
    _isCancelled = false;
    _isAnalyzing = false;
    _isGenerating = false;
    _error = '已取消生成';
    notifyListeners();
  }

  void cancelGeneration() {
    if (!_isAnalyzing && !_isGenerating) return;

    _isCancelled = true;
    _isAnalyzing = false;
    _isGenerating = false;
    _error = '已取消生成';
    notifyListeners();
  }

  void resetError() {
    _error = null;
    notifyListeners();
  }

  @visibleForTesting
  void setImagesForTest({
    required File referenceImage,
    required File selfieImage,
  }) {
    _referenceImage = referenceImage;
    _selfieImage = selfieImage;
    _error = null;
    notifyListeners();
  }

  /// Reset all selections
  void reset() {
    _referenceImage = null;
    _selfieImage = null;
    _resultImage = null;
    _analysis = null;
    _isAnalyzing = false;
    _isGenerating = false;
    _error = null;
    notifyListeners();
  }

  /// Load a history result for viewing
  void loadHistoryResult(MatchResult result) {
    _resultImage = result.resultImagePath != null
        ? File(result.resultImagePath!)
        : null;
    _analysis = result.analysis;
    _referenceImage = result.referenceImagePath != null
        ? File(result.referenceImagePath!)
        : null;
    _selfieImage = result.selfieImagePath != null
        ? File(result.selfieImagePath!)
        : null;
    _isAnalyzing = false;
    _isGenerating = false;
    _error = null;
    notifyListeners();
  }
}
