import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' as dio;
import '../models/makeup_analysis.dart';
import '../services/api_service.dart';
import '../services/background_task.dart';

class MatchProvider extends ChangeNotifier {
  final MakeupApi _api;

  MatchProvider({MakeupApi? api}) : _api = api ?? ApiService() {
    // Listen to auth changes to reload data on login/logout
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _loadUsage();
        _loadHistory();
      } else {
        _history.clear();
        notifyListeners();
      }
    });
  }

  // User
  String? get userId => Supabase.instance.client.auth.currentUser?.id;

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

  // Usage
  int _dailyUsage = 0;
  int _dailyLimit = 3;
  int _bonusCredits = 0;

  // History loading
  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;
  String? _lastResultUrl;

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
  int get remaining {
    final daily = max(0, _dailyLimit - _dailyUsage);
    return daily + _bonusCredits;
  }

  // ─── Init ───────────────────────────────

  Future<void> init() async {
    await _loadUsage();
    await _loadHistory();
  }

  Future<void> _loadUsage() async {
    final uid = userId;
    if (uid == null) return;
    try {
      final resp = await ApiService().dio.get('/api/v2/user/usage/$uid');
      final data = resp.data as Map<String, dynamic>;
      _dailyUsage = data['daily_usage'] as int? ?? 0;
      _dailyLimit = data['daily_limit'] as int? ?? 3;
      _bonusCredits = data['bonus_credits'] as int? ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('load usage error: $e');
    }
  }

  Future<void> _loadHistory() async {
    final uid = userId;
    if (uid == null) return;
    try {
      final resp = await ApiService().dio.get('/api/v2/history/$uid');
      final list = resp.data as List;
      _history
        ..clear()
        ..addAll(
          list.whereType<Map<String, dynamic>>().map((j) {
            final analysis = j['analysis'] is Map
                ? MakeupAnalysis.fromJson(j['analysis'] as Map<String, dynamic>)
                : null;
            return MatchResult(
              id: j['id'] as String? ?? '',
              createdAt: () {
                final raw = j['created_at'] as String? ?? '';
                if (raw.isEmpty) return DateTime.now();
                if (!raw.endsWith('Z')) return DateTime.parse('${raw}Z').toLocal();
                return DateTime.parse(raw).toLocal();
              }(),
              referenceImagePath: null,
              selfieImagePath: null,
              resultImagePath: null,
              resultImageUrl: j['result_image_url'] as String?,
              referenceImageUrl: j['reference_image_url'] as String?,
              analysis: analysis,
              status: Status.completed,
            );
          }).toList(),
        );
      notifyListeners();
    } catch (e) {
      debugPrint('load history error: $e');
    }
  }

  // ─── Image picking ───────────────────────

  Future<void> pickReferenceImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      _referenceImage = File(picked.path);
      _error = await _validateImage(_referenceImage!);
      notifyListeners();
    }
  }

  Future<void> pickSelfieImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      _selfieImage = File(picked.path);
      _error = await _validateImage(_selfieImage!, isSelfie: true);
      notifyListeners();
    }
  }

  Future<String?> _validateImage(File image, {bool isSelfie = false}) async {
    if (await image.length() < 10 * 1024) return '图片太小，请选择更清晰的照片';
    return null;
  }

  void clearReference() {
    _referenceImage = null;
    _error = null;
    notifyListeners();
  }

  void clearSelfie() {
    _selfieImage = null;
    _error = null;
    notifyListeners();
  }

  // ─── Match process ───────────────────────

  // Selected categories for transfer (default: all)
  Set<String> _selectedCategories = {};
  int? _pendingTabSwitch;

  int? get pendingTabSwitch => _pendingTabSwitch;
  void clearPendingTabSwitch() {
    _pendingTabSwitch = null;
  }

  Set<String> get selectedCategories => _selectedCategories;

  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  void selectAllCategories() {
    _selectedCategories = {'底妆', '眼妆', '眉妆', '腮红', '唇妆', '修容', '发型', '配饰'};
    notifyListeners();
  }

  Future<void> analyzeOnly() async {
    if (!canMatch) return;
    if (remaining <= 0) {
      _error = '今日次数已用完，请明天再试或购买加油包';
      notifyListeners();
      return;
    }

    _isCancelled = false;
    _isAnalyzing = true;
    _isGenerating = false;
    _resultImage = null;
    _analysis = null;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Analyze reference image
      await BackgroundTask.start();
      _analysis = await _api.analyzeMakeup(_referenceImage!, _userId());
      await BackgroundTask.end();
      if (_isCancelled) {
        _finishCancelled();
        return;
      }
      _isAnalyzing = false;
      selectAllCategories();
      _pendingTabSwitch = 1;
      notifyListeners();
    } on FormatException {
      _error = '妆容分析数据异常，请换一张参考图重试';
      _isAnalyzing = false;
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      String errMsg = '分析失败，请重试';
      try {
        final dioErr = e as dynamic;
        if (dioErr.response?.data is Map) {
          final detail = dioErr.response!.data['detail'] as String?;
          if (detail != null && detail.isNotEmpty) errMsg = detail;
        } else if (dioErr.response?.data is String) {
          errMsg = dioErr.response!.data;
        }
      } catch (_) {}
      _error = _isNetworkError(e) ? '网络连接异常，请检查网络后重试' : errMsg;
      _isAnalyzing = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> generateTransfer() async {
    if (_analysis == null) return;
    _isGenerating = true;
    _resultImage = null;
    _error = null;
    notifyListeners();

    try {
      // Filter analysis by selected categories
      final fullMap = _analysis!.toCategoryMap();
      final filteredMap = <String, String>{};
      for (final key in _selectedCategories) {
        if (fullMap.containsKey(key)) {
          filteredMap[key] = fullMap[key]!;
        }
      }

      await BackgroundTask.start();
      final transferResult = await _api.transferMakeup(
        targetImage: _selfieImage!,
        analysis: jsonEncode(filteredMap),
        userId: _userId(),
      );
      await BackgroundTask.end();
      if (_isCancelled) {
        _finishCancelled();
        return;
      }

      _lastResultUrl = transferResult.resultUrl;
      if (transferResult.filePath.isNotEmpty) {
        _resultImage = File(transferResult.filePath);
      }

      _isGenerating = false;
      _dailyUsage++;
      notifyListeners();
      // Save & refresh history (best effort)
      try {
        await _saveHistory();
        await _loadHistory();
      } catch (e) {
        debugPrint('save/refresh history error: $e');
      }
    } catch (e) {
      String errMsg = '生成失败，请重试';
      try {
        final dioErr = e as dynamic;
        if (dioErr.response?.data is Map) {
          final detail = dioErr.response!.data['detail'] as String?;
          if (detail != null && detail.isNotEmpty) errMsg = detail;
        }
      } catch (_) {}
      _error = _isNetworkError(e) ? '网络连接异常，请检查网络后重试' : errMsg;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final uid = userId;
    if (uid == null || _analysis == null) return;
    try {
      String? refUrl;

      // Upload reference image to backend
      if (_referenceImage != null) {
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(
            _referenceImage!.path,
            filename: 'reference.jpg',
          ),
        });
        final uploadResp = await ApiService().dio.post('/api/v2/upload', data: formData);
        final uploadData = uploadResp.data as Map<String, dynamic>;
        refUrl = uploadData['url'] as String?;
      }

      await ApiService().dio.post(
        '/api/v2/history',
        data: {
          'user_id': uid,
          'reference_image_url': refUrl ?? '',
          'selfie_image_url': '',
          'result_image_url': _lastResultUrl ?? '',
          'analysis': _analysis!.toCategoryMap(),
        },
      );
    } catch (e) {
      debugPrint('save history error: $e');
    }
  }

  String _userId() => userId ?? '';

  bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('dioexception') && message.contains('connection')) {
      return true;
    }
    if (message.contains('socketexception')) return true;
    if (message.contains('connection refused')) return true;
    return false;
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

  void setResultImage(File file) {
    _resultImage = file;
    notifyListeners();
  }

  void setReferenceImage(File file) {
    _referenceImage = file;
    notifyListeners();
  }

  void loadHistoryResult(MatchResult result) {
    _isHistoryLoading = true;
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
    _lastResultUrl = result.resultImageUrl;
    _isAnalyzing = false;
    _isGenerating = false;
    _error = null;
    notifyListeners();
  }

  void clearHistoryLoading() {
    _isHistoryLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    reset();
    _history.clear();
    notifyListeners();
  }
}
