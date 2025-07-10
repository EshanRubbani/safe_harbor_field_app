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
  Map<String, dynamic>? summary;
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
        id: json['id'] as String,
        userId: json['userId'] as String,
        status: _statusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        questionnaireResponses: json['questionnaireResponses'] != null 
            ? Map<String, dynamic>.from(json['questionnaireResponses'] as Map)
            : <String, dynamic>{},
        images: json['images'] != null 
            ? (json['images'] as Map<String, dynamic>).map((k, v) => MapEntry(k, List<String>.from(v)))
            : <String, List<String>>{},
        syncedToCloud: json['syncedToCloud'] as bool? ?? false,
        summary: json['summary'] != null ? Map<String, dynamic>.from(json['summary']) : null,
        version: json['version'] as String? ?? '1.0',
      );
    } catch (e) {
      print('[Model] Error deserializing InspectionReportModel: ' + e.toString());
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    // Validation: Ensure formData and images are not both empty
    assert(questionnaireResponses.isNotEmpty || (images.values.any((l) => l.isNotEmpty)),
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

  // For local storage as string
  String toRawJson() => json.encode(toJson());
  factory InspectionReportModel.fromRawJson(String str) => InspectionReportModel.fromJson(json.decode(str));

  /// Check if the report has at least one primary risk photo
  bool get hasPrimaryRiskPhoto {
    final primaryRiskPhotos = images['primary_risk'] ?? [];
    return primaryRiskPhotos.isNotEmpty;
  }

  /// Check if all questionnaire responses are recorded
  /// This method will check against the actual number of questions loaded
  bool hasAllQuestionnaireResponses({int? totalQuestions}) {
    final requiredQuestions = totalQuestions ?? 94; // Default to 94 if not provided
    final answeredQuestions = questionnaireResponses.entries
        .where((entry) => entry.value != null && entry.value.toString().trim().isNotEmpty)
        .length;
    return answeredQuestions >= requiredQuestions;
  }

  /// Check if the report is considered "completed" (ready for upload)
  /// A report is completed when it has:
  /// 1. At least 1 primary risk photo
  /// 2. All questionnaire responses
  bool isCompleted({int? totalQuestions}) {
    return hasPrimaryRiskPhoto && hasAllQuestionnaireResponses(totalQuestions: totalQuestions);
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
        .where((entry) => entry.value != null && entry.value.toString().trim().isNotEmpty)
        .length;
    final totalImages = images.values.fold(0, (sum, photos) => sum + photos.length);
    final primaryRiskPhotos = images['primary_risk']?.length ?? 0;
    
    return {
      'answered_questions': answeredQuestions,
      'total_questions': requiredQuestions,
      'completion_percentage': requiredQuestions > 0 ? ((answeredQuestions / requiredQuestions) * 100).round() : 0,
      'primary_risk_photos': primaryRiskPhotos,
      'total_images': totalImages,
      'is_completed': isCompleted(totalQuestions: totalQuestions),
      'completion_tag': completionTag(totalQuestions: totalQuestions),
    };
  }
}
