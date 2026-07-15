import 'dart:async';
import 'dart:io';

import 'package:facematch/models/makeup_analysis.dart';
import 'package:facematch/providers/match_provider.dart';
import 'package:facematch/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi implements MakeupApi {
  final Completer<MakeupAnalysis> analysisCompleter =
      Completer<MakeupAnalysis>();
  final Completer<MakeupTransferResult> transferCompleter =
      Completer<MakeupTransferResult>();

  @override
  Future<MakeupAnalysis> analyzeMakeup(File referenceImage,
      [String userId = '']) {
    return analysisCompleter.future;
  }

  @override
  Future<MakeupTransferResult> transferMakeup({
    required File targetImage,
    required String analysis,
    String userId = '',
  }) {
    return transferCompleter.future;
  }
}

Future<File> _createTempImage(String name) async {
  final dir = await Directory.systemTemp.createTemp('facematch_test_');
  final file = File('${dir.path}/$name.jpg');
  return file.writeAsBytes(List<int>.filled(12 * 1024, 1));
}

void main() {
  test('MatchProvider initial state', () {
    final provider = MatchProvider(api: _FakeApi());

    expect(provider.referenceImage, isNull);
    expect(provider.selfieImage, isNull);
    expect(provider.resultImage, isNull);
    expect(provider.analysis, isNull);
    expect(provider.isAnalyzing, isFalse);
    expect(provider.isGenerating, isFalse);
    expect(provider.error, isNull);
    expect(provider.history, isEmpty);
    expect(provider.canMatch, isFalse);
  });

  test('canMatch is true after both images are selected', () async {
    final provider = MatchProvider(api: _FakeApi());
    final reference = await _createTempImage('reference');
    final selfie = await _createTempImage('selfie');

    provider.setImagesForTest(referenceImage: reference, selfieImage: selfie);

    expect(provider.canMatch, isTrue);
  });

  test('startMatch moves through analyzing and generating states', () async {
    final api = _FakeApi();
    final provider = MatchProvider(api: api);
    final reference = await _createTempImage('reference');
    final selfie = await _createTempImage('selfie');
    final result = await _createTempImage('result');
    final states = <String>[];

    provider.setImagesForTest(referenceImage: reference, selfieImage: selfie);
    provider.addListener(() {
      states.add('${provider.isAnalyzing}:${provider.isGenerating}');
    });

    final matchFuture = provider.startMatch();
    await Future<void>.delayed(Duration.zero);

    expect(provider.isAnalyzing, isTrue);
    expect(provider.isGenerating, isFalse);

    api.analysisCompleter.complete(MakeupAnalysis.sample);
    await Future<void>.delayed(Duration.zero);

    expect(provider.isAnalyzing, isFalse);
    expect(provider.isGenerating, isTrue);

    api.transferCompleter.complete(MakeupTransferResult(filePath: result.path));
    await matchFuture;

    expect(provider.isAnalyzing, isFalse);
    expect(provider.isGenerating, isFalse);
    expect(provider.resultImage?.path, result.path);
    expect(states, contains('true:false'));
    expect(states, contains('false:true'));
    expect(states, contains('false:false'));
  });

  test('startMatch 生成完成并设置结果图', () async {
    final api = _FakeApi();
    final provider = MatchProvider(api: api);
    final reference = await _createTempImage('reference');
    final selfie = await _createTempImage('selfie');
    final result = await _createTempImage('result');

    provider.setImagesForTest(referenceImage: reference, selfieImage: selfie);

    final matchFuture = provider.startMatch();
    await Future<void>.delayed(Duration.zero);
    api.analysisCompleter.complete(MakeupAnalysis.sample);
    await Future<void>.delayed(Duration.zero);
    api.transferCompleter.complete(MakeupTransferResult(filePath: result.path));
    await matchFuture;

    expect(provider.isAnalyzing, isFalse);
    expect(provider.isGenerating, isFalse);
    expect(provider.resultImage?.path, result.path);
    expect(provider.comparisonBeforeImage?.path, selfie.path);
    expect(provider.comparisonBeforeLabel, '原图');
  });

  test('对比图优先用自拍原图，不被历史参考妆覆盖（回归）', () async {
    final provider = MatchProvider(api: _FakeApi());
    final reference = await _createTempImage('reference');
    final selfie = await _createTempImage('selfie');
    final historyRef = await _createTempImage('history_ref');

    provider.setImagesForTest(referenceImage: reference, selfieImage: selfie);

    // 模拟看过一条历史记录（参考妆被载入）
    provider.loadHistoryResult(MatchResult(
      id: 'h1',
      createdAt: DateTime.now(),
      referenceImagePath: historyRef.path,
      analysis: MakeupAnalysis.sample,
      status: Status.completed,
    ));

    // 关键断言：原图必须是用户自拍，不能是历史参考妆
    expect(provider.comparisonBeforeImage?.path, selfie.path);
    expect(provider.comparisonBeforeLabel, '原图');
  });

  test('无自拍时对比图退回参考妆并正确标注', () async {
    final provider = MatchProvider(api: _FakeApi());
    final reference = await _createTempImage('reference');
    final historyRef = await _createTempImage('history_ref');

    provider.setImagesForTest(referenceImage: reference);

    provider.loadHistoryResult(MatchResult(
      id: 'h2',
      createdAt: DateTime.now(),
      referenceImagePath: historyRef.path,
      analysis: MakeupAnalysis.sample,
      status: Status.completed,
    ));

    expect(provider.comparisonBeforeImage?.path, historyRef.path);
    expect(provider.comparisonBeforeLabel, '参考妆');
  });
}
