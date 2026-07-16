import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import '../models/makeup_analysis.dart';
import '../services/api_service.dart';
import '../services/background_task.dart';

class MatchProvider extends ChangeNotifier {
  final MakeupApi _api;

  MatchProvider({MakeupApi? api}) : _api = api ?? ApiService() {
    // Listen to auth changes to reload data on login/logout
    // 防御：测试环境下 Supabase 可能未初始化，跳过监听避免崩溃
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.session != null) {
          _loadUsage();
          _loadHistory();
        } else {
          _history.clear();
          notifyListeners();
        }
      });
    } catch (_) {
      // Supabase 未初始化（如纯单元测试环境），忽略监听
    }
  }

  // User
  String? get userId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

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
  bool _isHistoryLoaded = false;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isHistoryLoaded => _isHistoryLoaded;
  File? _historyRefImage;
  File? _historySelfieImage;
  String? _lastResultUrl;

  // Getters
  File? get referenceImage => _referenceImage;
  File? get selfieImage => _selfieImage;
  File? get resultImage => _resultImage;
  File? get historyRefImage => _historyRefImage;
  File? get historySelfieImage => _historySelfieImage;
  MakeupAnalysis? get analysis => _analysis;
  bool get isAnalyzing => _isAnalyzing;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  List<MatchResult> get history => List.unmodifiable(_history);
  bool get canMatch => _referenceImage != null && _selfieImage != null;

  /// 对比图（仿妆前）必须是用户自拍原图；只有历史记录无自拍时才退回参考妆
  File? get comparisonBeforeImage =>
      (_selfieImage ?? _historySelfieImage) ??
      _historyRefImage ??
      _referenceImage;

  /// 对比图标签：有自拍标“原图”，否则标“参考妆”
  String get comparisonBeforeLabel =>
      (_selfieImage ?? _historySelfieImage) != null ? '原图' : '参考妆';
  int get remaining {
    final daily = max(0, _dailyLimit - _dailyUsage);
    return daily + _bonusCredits;
  }

  // ─── Init ───────────────────────────────

  Future<void> init() async {
    // Load cached usage immediately from local storage (no network)
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyUsage = prefs.getInt('daily_usage') ?? 0;
      _dailyLimit = prefs.getInt('daily_limit') ?? 3;
      _bonusCredits = prefs.getInt('bonus_credits') ?? 0;
      notifyListeners();
    } catch (_) {}
    // Fire network refreshes asynchronously — don't block app startup
    unawaited(_loadUsage());
    unawaited(_loadHistory());
    // Pre-clean stale cache entries older than 7 days
    _cleanOldCache();
  }

  Future<String> _cacheDir() async {
    final dir = Directory(
      '${(await getApplicationCacheDirectory()).path}/facematch_history',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String?> _cacheImage(String url, String id, String type) async {
    if (url.isEmpty) return null;
    try {
      final cacheDir = await _cacheDir();
      final path = '$cacheDir/${id}_$type.png';
      if (await File(path).exists()) return path;
      final resp = await ApiService().dio.get(
        url,
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );
      await File(path).writeAsBytes(resp.data as List<int>);
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cleanOldCache() async {
    try {
      final dir = Directory(await _cacheDir());
      if (!await dir.exists()) return;
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      await for (final f in dir.list()) {
        if (f is File &&
            await f.lastModified().then((t) => t.isBefore(cutoff))) {
          await f.delete();
        }
      }
    } catch (_) {}
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
      // Cache to local storage for instant startup next time
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('daily_usage', _dailyUsage);
        await prefs.setInt('daily_limit', _dailyLimit);
        await prefs.setInt('bonus_credits', _bonusCredits);
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      debugPrint('load usage error: $e');
    }
  }

  Future<void> _loadHistory() async {
    _isHistoryLoaded = false;
    notifyListeners();
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
                if (!raw.endsWith('Z') &&
                    raw.indexOf('+') < 0 &&
                    raw.lastIndexOf('-') <= 10) {
                  return DateTime.parse('${raw}Z').toLocal();
                }
                return DateTime.parse(raw).toLocal();
              }(),
              referenceImagePath: null,
              selfieImagePath: null,
              resultImagePath: null,
              resultImageUrl: j['result_image_url'] as String?,
              referenceImageUrl: j['reference_image_url'] as String?,
              selfieImageUrl: j['selfie_image_url'] as String?,
              analysis: analysis,
              status: Status.completed,
            );
          }).toList(),
        );
      // Cache images async
      _cacheHistoryImages();
      _isHistoryLoaded = true;
      notifyListeners();
    } catch (e) {
      _isHistoryLoaded = true;
      debugPrint('load history error: $e');
    }
  }

  Future<void> refreshHistory() async {
    _history.clear();
    await _loadHistory();
  }

  Future<void> _cacheHistoryImages() async {
    for (int i = 0; i < _history.length; i++) {
      final item = _history[i];
      String? refPath, resPath, selfiePath;
      if (item.referenceImageUrl != null &&
          item.referenceImageUrl!.isNotEmpty) {
        refPath = await _cacheImage(item.referenceImageUrl!, item.id, 'ref');
      }
      if (item.selfieImageUrl != null && item.selfieImageUrl!.isNotEmpty) {
        selfiePath = await _cacheImage(item.selfieImageUrl!, item.id, 'selfie');
      }
      if (item.resultImageUrl != null && item.resultImageUrl!.isNotEmpty) {
        resPath = await _cacheImage(item.resultImageUrl!, item.id, 'res');
      }
      if (refPath != null || resPath != null || selfiePath != null) {
        _history[i] = MatchResult(
          id: item.id,
          createdAt: item.createdAt,
          referenceImagePath: refPath ?? item.referenceImagePath,
          selfieImagePath: selfiePath ?? item.selfieImagePath,
          resultImagePath: resPath ?? item.resultImagePath,
          resultImageUrl: item.resultImageUrl,
          referenceImageUrl: item.referenceImageUrl,
          selfieImageUrl: item.selfieImageUrl,
          analysis: item.analysis,
          status: item.status,
        );
        notifyListeners();
      }
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
    // 清空历史残留图，避免用历史记录的参考妆/自拍污染本次对比
    _historyRefImage = null;
    _historySelfieImage = null;
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
      String? selfieUrl;

      // Upload reference image to backend
      if (_referenceImage != null) {
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(
            _referenceImage!.path,
            filename: 'reference.jpg',
          ),
        });
        final uploadResp = await ApiService().dio.post(
          '/api/v2/upload',
          data: formData,
        );
        final uploadData = uploadResp.data as Map<String, dynamic>;
        refUrl = uploadData['url'] as String?;
      }

      // Upload selfie (原图) so history comparison shows the real before image
      if (_selfieImage != null) {
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(
            _selfieImage!.path,
            filename: 'selfie.jpg',
          ),
        });
        final uploadResp = await ApiService().dio.post(
          '/api/v2/upload',
          data: formData,
        );
        final uploadData = uploadResp.data as Map<String, dynamic>;
        selfieUrl = uploadData['url'] as String?;
      }

      await ApiService().dio.post(
        '/api/v2/history',
        data: {
          'user_id': uid,
          'reference_image_url': refUrl ?? '',
          'selfie_image_url': selfieUrl ?? '',
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
    _historyRefImage = result.referenceImagePath != null
        ? File(result.referenceImagePath!)
        : null;
    _historySelfieImage = result.selfieImagePath != null
        ? File(result.selfieImagePath!)
        : null;
    _resultImage = result.resultImagePath != null
        ? File(result.resultImagePath!)
        : null;
    _analysis = result.analysis;
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

  // ─── 测试辅助 ───────────────────────────
  @visibleForTesting
  void setImagesForTest({File? referenceImage, File? selfieImage}) {
    if (referenceImage != null) _referenceImage = referenceImage;
    if (selfieImage != null) _selfieImage = selfieImage;
    notifyListeners();
  }

  /// 包装“分析→生成”的完整流程，供测试与 UI 调用
  Future<void> startMatch() async {
    await analyzeOnly();
    if (_isCancelled) return;
    await generateTransfer();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    reset();
    _history.clear();
    notifyListeners();
  }
}
