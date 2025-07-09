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
        questionnaireResponses: Map<String, dynamic>.from(json['questionnaireResponses'] as Map),
        images: (json['images'] as Map<String, dynamic>).map((k, v) => MapEntry(k, List<String>.from(v))),
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
        'questionnaire_responses': questionnaireResponses,
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
} 