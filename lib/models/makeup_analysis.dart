class MakeupAnalysis {
  final String base;
  final String eyes;
  final String eyebrows;
  final String blush;
  final String lips;
  final String contour;
  final String hairstyle;
  final String accessories;

  MakeupAnalysis({
    required this.base,
    required this.eyes,
    required this.eyebrows,
    required this.blush,
    required this.lips,
    required this.contour,
    required this.hairstyle,
    required this.accessories,
  });

  factory MakeupAnalysis.fromJson(Map<String, dynamic> json) {
    String val(dynamic v) => (v is String)
        ? v
        : (v is Map)
        ? v.values.join('、')
        : '${v ?? ''}';
    return MakeupAnalysis(
      base: val(json['底妆'] ?? json['base']),
      eyes: val(json['眼妆'] ?? json['eyes']),
      eyebrows: val(json['眉妆'] ?? json['eyebrows']),
      blush: val(json['腮红'] ?? json['blush']),
      lips: val(json['唇妆'] ?? json['lips']),
      contour: val(json['修容'] ?? json['contour']),
      hairstyle: val(json['发型'] ?? json['hairstyle']),
      accessories: val(json['配饰'] ?? json['accessories']),
    );
  }

  Map<String, String> toCategoryMap() {
    return {
      '底妆': base,
      '眼妆': eyes,
      '眉妆': eyebrows,
      '腮红': blush,
      '唇妆': lips,
      '修容': contour,
      '发型': hairstyle,
      '配饰': accessories,
    };
  }

  Map<String, dynamic> toJson() {
    return toCategoryMap();
  }

  static final sample = MakeupAnalysis(
    base: '光泽型底妆，暖色深褐色肤色，均匀自然',
    eyes: '裸色打底，自然融合，突出眼睛神采',
    eyebrows: '自然弧形，深棕色，浓密有型',
    blush: '颧骨上方，淡暖色调珊瑚色',
    lips: '裸色/深粉色，光泽质地，水润饱满',
    contour: '高光明显于额头、鼻梁、颧骨，修容轻微',
    hairstyle: '微卷长发，深棕色，自然垂落',
    accessories: '金色耳环，简约设计',
  );
}

class MatchResult {
  final String id;
  final DateTime createdAt;
  final String? referenceImagePath;
  final String? selfieImagePath;
  final String? resultImagePath;
  final String? resultImageUrl;
  final String? referenceImageUrl;
  final MakeupAnalysis? analysis;
  final Status status;

  MatchResult({
    required this.id,
    required this.createdAt,
    this.referenceImagePath,
    this.selfieImagePath,
    this.resultImagePath,
    this.resultImageUrl,
    this.referenceImageUrl,
    this.analysis,
    this.status = Status.processing,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    String raw = json['created_at'] as String;
    if (!raw.endsWith('Z') && raw.indexOf('+') < 0 && raw.lastIndexOf('-') <= 10) {
      raw = '${raw}Z';
    }
    return MatchResult(
      id: json['id'] as String,
      createdAt: DateTime.parse(raw).toLocal(),
      referenceImagePath: json['reference_image'] as String?,
      selfieImagePath: json['selfie_image'] as String?,
      resultImagePath: json['result_image'] as String?,
      resultImageUrl: json['result_image_url'] as String?,
      referenceImageUrl: json['reference_image_url'] as String?,
      analysis: json['analysis'] != null
          ? MakeupAnalysis.fromJson(json['analysis'] as Map<String, dynamic>)
          : null,
      status: Status.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => Status.processing,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'reference_image': referenceImagePath,
      'selfie_image': selfieImagePath,
      'result_image': resultImagePath,
      'result_image_url': resultImageUrl,
      'reference_image_url': referenceImageUrl,
      'analysis': analysis?.toJson(),
      'status': status.name,
    };
  }

  static final sample = MatchResult(
    id: 'sample',
    createdAt: DateTime.now(),
    analysis: MakeupAnalysis.sample,
    status: Status.completed,
  );
}

enum Status { pending, processing, completed, failed }
