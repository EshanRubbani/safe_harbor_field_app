import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Top-Level CompleteReport Model
class CompleteReport {
  final String createdAt;
  final Images images;
  final String inspectorId;
  final QuestionnaireResponse questionnaireResponse;
  final String reportId;
  final String status;
  final String updatedAt;
  final String version;

  CompleteReport({
    required this.createdAt,
    required this.images,
    required this.inspectorId,
    required this.questionnaireResponse,
    required this.reportId,
    required this.status,
    required this.updatedAt,
    required this.version,
  });

  factory CompleteReport.fromJson(Map<String, dynamic> json) {
    return CompleteReport(
      createdAt: _convertTimestampToString(json['created_at']),
      images: Images.fromJson(json['images']),
      inspectorId: json['inspector_id'],
      questionnaireResponse:
          QuestionnaireResponse.fromJson(json['questionnaire_responses']),
      reportId: json['report_id'],
      status: json['status'],
      updatedAt: _convertTimestampToString(json['updated_at']),
      version: json['version'],
    );
  }

  /// Helper method to convert Timestamp to String in MM-DD-YYYY hh:mm:ss format
  static String _convertTimestampToString(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }
    
    // Format as MM-DD-YYYY hh:mm:ss
    final DateFormat formatter = DateFormat('MM-dd-yyyy HH:mm:ss');
    return formatter.format(dateTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt,
      'images': images.toJson(),
      'inspector_id': inspectorId,
      'questionnaire_responses': questionnaireResponse.toJson(),
      'report_id': reportId,
      'status': status,
      'updated_at': updatedAt,
      'version': version,
    };
  }
}

// Images Model
class Images {
  final List<String> additional;
  final List<String> frontElevation;
  final List<String> primaryRisk;
  final List<String> rearElevation;
  final List<String> rightElevation;
  final List<String> roof;

  Images({
    required this.additional,
    required this.frontElevation,
    required this.primaryRisk,
    required this.rearElevation,
    required this.rightElevation,
    required this.roof,
  });

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      additional: List<String>.from(json['additional'] ?? []),
      frontElevation: List<String>.from(json['front_elevation'] ?? []),
      primaryRisk: List<String>.from(json['primary_risk'] ?? []),
      rearElevation: List<String>.from(json['rear_elevation'] ?? []),
      rightElevation: List<String>.from(json['right_elevation'] ?? []),
      roof: List<String>.from(json['roof'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'additional': additional,
      'front_elevation': frontElevation,
      'primary_risk': primaryRisk,
      'rear_elevation': rearElevation,
      'right_elevation': rightElevation,
      'roof': roof,
    };
  }
}

// Questionnaire Response Model
class QuestionnaireResponse {
  final Map<String, Question> responses;

  QuestionnaireResponse({required this.responses});

  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    Map<String, Question> responsesMap = {};
    json.forEach((key, value) {
      responsesMap[key] = Question.fromJson(value);
    });
    return QuestionnaireResponse(responses: responsesMap);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    responses.forEach((key, value) {
      map[key] = value.toJson();
    });
    return map;
  }
}

// Individual Question Model
class Question {
  final String questionId;
  final String questionText;
  final String questionType;
  final String section;
  final dynamic value;

  Question({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.section,
    required this.value,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['question_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      section: json['section'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'question_type': questionType,
      'section': section,
      'value': value,
    };
  }
}