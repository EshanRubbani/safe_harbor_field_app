import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Dynamic Question Model based on Firestore structure
class DynamicQuestion {
  final String id;
  final String label;
  final String type;
  final List<String>? options;
  final bool? hasOther;

  DynamicQuestion({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.hasOther,
  });

  factory DynamicQuestion.fromJson(Map<String, dynamic> json) {
    return DynamicQuestion(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      hasOther: json['hasOther'] as bool?,
    );
  }

  factory DynamicQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DynamicQuestion.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'options': options,
      'hasOther': hasOther,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'type': type,
      'options': options,
      'hasOther': hasOther,
    };
  }

  /// Check if question has "Other" option for radio buttons
  bool get hasOtherOption => hasOther == true;

  /// All questions are required in the current questionnaire structure
  bool get isRequired => true;

  /// Get the question type enum
  DynamicQuestionType get questionType {
    switch (type.toLowerCase()) {
      case 'text':
        return DynamicQuestionType.text;
      case 'radio':
        return DynamicQuestionType.radio;
      case 'yesno':
        return DynamicQuestionType.yesNo;
      case 'yesnounknown':
        return DynamicQuestionType.yesNoUnknown;
      case 'dropdown':
        return DynamicQuestionType.dropdown;
      case 'checkbox':
        return DynamicQuestionType.checkbox;
      case 'date':
        return DynamicQuestionType.date;
      case 'number':
        return DynamicQuestionType.number;
      case 'longtext':
        return DynamicQuestionType.longText;
      default:
        return DynamicQuestionType.text;
    }
  }

  /// Get default options for specific question types
  List<String> get effectiveOptions {
    switch (questionType) {
      case DynamicQuestionType.yesNo:
        return ['Yes', 'No'];
      case DynamicQuestionType.yesNoUnknown:
        return ['Yes', 'No', 'Unknown'];
      case DynamicQuestionType.radio:
      case DynamicQuestionType.dropdown:
      case DynamicQuestionType.checkbox:
        return options ?? [];
      default:
        return [];
    }
  }

  DynamicQuestion copyWith({
    String? id,
    String? label,
    String? type,
    List<String>? options,
    bool? hasOther,
  }) {
    return DynamicQuestion(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      options: options ?? this.options,
      hasOther: hasOther ?? this.hasOther,
    );
  }
}

/// Dynamic Question Section Model
class DynamicQuestionSection {
  final String title;
  final List<String> questions;
  final String? description;
  final IconData? icon;
  final int order;
  final bool isRequired;
  final String? helpText;

  DynamicQuestionSection({
    required this.title,
    required this.questions,
    this.description,
    this.icon,
    this.order = 0,
    this.isRequired = false,
    this.helpText,
  });

  factory DynamicQuestionSection.fromJson(Map<String, dynamic> json) {
    return DynamicQuestionSection(
      title: json['title'] as String,
      questions: List<String>.from(json['questions']),
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      isRequired: json['isRequired'] as bool? ?? false,
      helpText: json['helpText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'questions': questions,
      'description': description,
      'order': order,
      'isRequired': isRequired,
      'helpText': helpText,
    };
  }

  /// Generate section ID from title
  String get id {
    return title
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('/', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Get icon based on section title
  IconData get sectionIcon {
    switch (title.toLowerCase()) {
      case 'inspector information':
        return Icons.person_rounded;
      case 'insured information':
        return Icons.home_rounded;
      case 'location information':
        return Icons.location_on_rounded;
      case 'overall elevation condition':
        return Icons.foundation_rounded;
      case 'overall roof condition':
        return Icons.roofing_rounded;
      case 'garage/outbuilding':
        return Icons.garage_rounded;
      case 'dwelling hazard and possible hazards':
        return Icons.warning_rounded;
      default:
        return Icons.quiz_outlined;
    }
  }
}

/// Dynamic Questionnaire Structure Model
class DynamicQuestionnaireStructure {
  final String version;
  final DateTime lastUpdated;
  final List<DynamicQuestion> questions;
  final List<DynamicQuestionSection> sections;

  DynamicQuestionnaireStructure({
    required this.version,
    required this.lastUpdated,
    required this.questions,
    required this.sections,
  });

  factory DynamicQuestionnaireStructure.fromJson(Map<String, dynamic> json) {
    return DynamicQuestionnaireStructure(
      version: json['version'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      questions: (json['questions'] as List<dynamic>)
          .map((q) => DynamicQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>)
          .map((s) => DynamicQuestionSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  /// Get organized sections with their questions
  List<DynamicQuestionSectionWithQuestions> get organizedSections {
    final Map<String, DynamicQuestion> questionMap = {
      for (var question in questions) question.id: question
    };

    return sections.map((section) {
      final sectionQuestions = section.questions
          .map((questionId) => questionMap[questionId])
          .where((question) => question != null)
          .cast<DynamicQuestion>()
          .toList();

      return DynamicQuestionSectionWithQuestions(
        section: section,
        questions: sectionQuestions,
      );
    }).toList();
  }

  /// Get question by ID
  DynamicQuestion? getQuestionById(String id) {
    return questions.firstWhere((q) => q.id == id);
  }

  /// Get section by title
  DynamicQuestionSection? getSectionByTitle(String title) {
    return sections.firstWhere((s) => s.title == title);
  }
}

/// Section with its questions
class DynamicQuestionSectionWithQuestions {
  final DynamicQuestionSection section;
  final List<DynamicQuestion> questions;

  DynamicQuestionSectionWithQuestions({
    required this.section,
    required this.questions,
  });

  String get id => section.id;
  String get title => section.title;
  String? get description => section.description;
  IconData get icon => section.sectionIcon;
  int get order => section.order;
  bool get isRequired => section.isRequired;
  String? get helpText => section.helpText;
}

/// Question types enum
enum DynamicQuestionType {
  text,
  radio,
  yesNo,
  yesNoUnknown,
  dropdown,
  checkbox,
  date,
  number,
  longText,
}

/// Question form data model
class DynamicQuestionFormData {
  final String questionId;
  final String label;
  final String type;
  final dynamic value;
  final String? otherValue;
  final DateTime timestamp;

  DynamicQuestionFormData({
    required this.questionId,
    required this.label,
    required this.type,
    required this.value,
    this.otherValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory DynamicQuestionFormData.fromJson(Map<String, dynamic> json) {
    return DynamicQuestionFormData(
      questionId: json['questionId'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      value: json['value'],
      otherValue: json['otherValue'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'label': label,
      'type': type,
      'value': value,
      'otherValue': otherValue,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get the effective value (includes other value if applicable)
  dynamic get effectiveValue {
    if (value == 'Other' && otherValue != null && otherValue!.isNotEmpty) {
      return otherValue;
    }
    return value;
  }

  /// Check if this is an "Other" response
  bool get isOtherResponse => value == 'Other' && otherValue != null;
}
