import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/makeup_analysis.dart';
import '../services/api_service.dart';

class MatchProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // Images
  File? _referenceImage;
  File? _selfieImage;
  File? _resultImage;

  // Analysis
  MakeupAnalysis? _analysis;
  bool _isAnalyzing = false;
  bool _isGenerating = false;
  String? _error;

  // History
  final List<MatchResult> _history = [];

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

  /// Pick reference makeup image
  Future<void> pickReferenceImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      _referenceImage = File(picked.path);
      _error = null;
      notifyListeners();
    }
  }

  /// Pick selfie image
  Future<void> pickSelfieImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      _selfieImage = File(picked.path);
      _error = null;
      notifyListeners();
    }
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

    _isAnalyzing = true;
    _isGenerating = false;
    _resultImage = null;
    _analysis = null;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Analyze reference image
      _analysis = await _api.analyzeMakeup(_referenceImage!);
      _isAnalyzing = false;
      _isGenerating = true;
      notifyListeners();

      // Step 2: Generate makeup transfer
      final resultPath = await _api.transferMakeup(
        targetImage: _selfieImage!,
        analysis: jsonEncode(_analysis!.toCategoryMap()),
      );

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
    } catch (e) {
      _error = e.toString();
      _isAnalyzing = false;
      _isGenerating = false;
      notifyListeners();
    }
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
