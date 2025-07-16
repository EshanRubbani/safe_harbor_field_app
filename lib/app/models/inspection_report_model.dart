import 'dart:convert';

enum InspectionReportStatus { inProgress, completed, uploaded }

class InspectionReportModel {
  final String id;
  final String userId;
  InspectionReportStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> questionnaireResponses;
  Map<String, List<String>> images; // Local: file paths, Uploaded: URLs
  bool syncedToCloud;
  String? summary;
  String version;

  InspectionReportModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.questionnaireResponses,
    required this.images,
    this.syncedToCloud = false,
    this.summary,
    this.version = '1.0',
  });

  factory InspectionReportModel.fromJson(Map<String, dynamic> json) {
    print('[Model] Deserializing InspectionReportModel from JSON...');
    try {
      return InspectionReportModel(
        id: json['id'] as String ?? "",
        userId: json['userId'] as String,
        status: _statusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        questionnaireResponses:
            _parseQuestionnaireResponses(json['questionnaireResponses']),
        images: _parseImages(json['images']),
        syncedToCloud: json['syncedToCloud'] as bool? ?? false,
        summary: json['summary'] as String? ?? "",
        version: json['version'] as String? ?? '1.0',
      );
    } catch (e) {
      print(
          '[Model] Error deserializing InspectionReportModel: ' + e.toString());
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    // Validation: Ensure formData and images are not both empty
    assert(
        questionnaireResponses.isNotEmpty ||
            (images.values.any((l) => l.isNotEmpty)),
        'InspectionReportModel: Both formData and images are empty!');
    print('[Model] Serializing InspectionReportModel to JSON...');
    try {
      return {
        'id': id,
        'userId': userId,
        'status': status.toString(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'questionnaireResponses': questionnaireResponses,
        'images': images,
        'syncedToCloud': syncedToCloud,
        'summary': summary,
        'version': version,
      };
    } catch (e) {
      print('[Model] Error serializing InspectionReportModel: ' + e.toString());
      rethrow;
    }
  }

  static InspectionReportStatus _statusFromString(String status) {
    switch (status) {
      case 'inProgress':
        return InspectionReportStatus.inProgress;
      case 'completed':
        return InspectionReportStatus.completed;
      case 'uploaded':
        return InspectionReportStatus.uploaded;
      default:
        return InspectionReportStatus.inProgress;
    }
  }

  /// Deep parse questionnaire responses to ensure nested maps are properly typed
  static Map<String, dynamic> _parseQuestionnaireResponses(dynamic input) {
    print('[Model] 🔄 Parsing questionnaire responses...');
    if (input == null) {
      print('[Model] ⚠️ Questionnaire responses is null, returning empty map');
      return {};
    }

    if (input is Map) {
      final Map<String, dynamic> result = {};
      input.forEach((key, value) {
        if (value is Map) {
          // Recursively convert nested maps to Map<String, dynamic>
          result[key] = Map<String, dynamic>.from(value);
          print('[Model] 📝 Parsed question response for key: $key');
        } else {
          result[key] = value;
          print('[Model] 📝 Direct value for key: $key');
        }
      });
      print(
          '[Model] ✅ Successfully parsed ${result.length} questionnaire responses');
      return result;
    }

    print(
        '[Model] ⚠️ Questionnaire responses is not a Map, returning empty map');
    return {};
  }

  /// Parse images map to ensure proper typing
  static Map<String, List<String>> _parseImages(dynamic input) {
    print('[Model] 🖼️ Parsing images...');
    if (input == null) {
      print('[Model] ⚠️ Images is null, returning empty map');
      return {};
    }

    if (input is Map) {
      final Map<String, List<String>> result = {};
      input.forEach((key, value) {
        if (value is List) {
          result[key] = List<String>.from(value);
          print(
              '[Model] 🖼️ Parsed ${result[key]!.length} images for key: $key');
        } else {
          result[key] = [];
          print('[Model] ⚠️ Non-list value for images key: $key');
        }
      });
      print('[Model] ✅ Successfully parsed ${result.length} image categories');
      return result;
    }

    print('[Model] ⚠️ Images is not a Map, returning empty map');
    return {};
  }

  // For local storage as string
  String toRawJson() => json.encode(toJson());
  factory InspectionReportModel.fromRawJson(String str) =>
      InspectionReportModel.fromJson(json.decode(str));

  /// Check if the report has at least one primary risk photo
  bool get hasPrimaryRiskPhoto {
    final primaryRiskPhotos = images['primary_risk'] ?? [];
    return primaryRiskPhotos.isNotEmpty;
  }

  /// Check if all questionnaire responses are recorded
  /// This method will check against the actual number of questions loaded
  bool hasAllQuestionnaireResponses({int? totalQuestions}) {
    final requiredQuestions =
        totalQuestions ?? 94; // Default to 94 if not provided
    final answeredQuestions = questionnaireResponses.entries
        .where((entry) =>
            entry.value != null && entry.value.toString().trim().isNotEmpty)
        .length;
    return answeredQuestions >= requiredQuestions;
  }

  /// Check if the report is considered "completed" (ready for upload)
  /// A report is completed when it has:
  /// 1. At least 1 primary risk photo
  /// 2. All questionnaire responses
  bool isCompleted({int? totalQuestions}) {
    return hasPrimaryRiskPhoto &&
        hasAllQuestionnaireResponses(totalQuestions: totalQuestions);
  }

  /// Get the current completion status tag
  String completionTag({int? totalQuestions}) {
    if (status == InspectionReportStatus.uploaded) {
      return 'Synced';
    } else if (isCompleted(totalQuestions: totalQuestions)) {
      return 'Completed';
    } else {
      return 'In Progress';
    }
  }

  /// Get the color for the completion tag
  /// This is used in the UI to display the appropriate color
  String completionTagColor({int? totalQuestions}) {
    switch (completionTag(totalQuestions: totalQuestions)) {
      case 'Synced':
        return 'blue';
      case 'Completed':
        return 'orange';
      case 'In Progress':
      default:
        return 'red';
    }
  }

  /// Get completion statistics
  Map<String, dynamic> completionStats({int? totalQuestions}) {
    final requiredQuestions = totalQuestions ?? 94;
    final answeredQuestions = questionnaireResponses.entries
        .where((entry) =>
            entry.value != null && entry.value.toString().trim().isNotEmpty)
        .length;
    final totalImages =
        images.values.fold(0, (sum, photos) => sum + photos.length);
    final primaryRiskPhotos = images['primary_risk']?.length ?? 0;

    return {
      'answered_questions': answeredQuestions,
      'total_questions': requiredQuestions,
      'completion_percentage': requiredQuestions > 0
          ? ((answeredQuestions / requiredQuestions) * 100).round()
          : 0,
      'primary_risk_photos': primaryRiskPhotos,
      'total_images': totalImages,
      'is_completed': isCompleted(totalQuestions: totalQuestions),
      'completion_tag': completionTag(totalQuestions: totalQuestions),
    };
  }
}
