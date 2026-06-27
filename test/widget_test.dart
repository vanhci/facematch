import 'dart:async';
import 'dart:io';

import 'package:facematch/models/makeup_analysis.dart';
import 'package:facematch/providers/match_provider.dart';
import 'package:facematch/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi implements MakeupApi {
  final Completer<MakeupAnalysis> analysisCompleter =
      Completer<MakeupAnalysis>();
  final Completer<String> transferCompleter = Completer<String>();

  @override
  Future<MakeupAnalysis> analyzeMakeup(File referenceImage) {
    return analysisCompleter.future;
  }

  @override
  Future<String> transferMakeup({
    required File targetImage,
    required String analysis,
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

    api.transferCompleter.complete(result.path);
    await matchFuture;

    expect(provider.isAnalyzing, isFalse);
    expect(provider.isGenerating, isFalse);
    expect(provider.resultImage?.path, result.path);
    expect(states, contains('true:false'));
    expect(states, contains('false:true'));
    expect(states, contains('false:false'));
  });

  test('startMatch inserts completed result into history', () async {
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
    api.transferCompleter.complete(result.path);
    await matchFuture;

    expect(provider.history, hasLength(1));
    expect(provider.history.first.status, Status.completed);
    expect(provider.history.first.referenceImagePath, reference.path);
    expect(provider.history.first.selfieImagePath, selfie.path);
    expect(provider.history.first.resultImagePath, result.path);
    expect(provider.history.first.analysis?.base, MakeupAnalysis.sample.base);
  });
}
