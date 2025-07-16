import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/models/dynamic_question_model.dart';
import 'package:safe_harbor_field_app/app/utils/date_input_widget.dart';
import 'package:safe_harbor_field_app/app/utils/drop_down_widget.dart';
import 'package:safe_harbor_field_app/app/utils/radio_button_widget.dart';
import 'package:safe_harbor_field_app/app/utils/text_input_widget.dart';

enum QuestionType {
  text,
  dropdown,
  date,
  multipleChoice,
  number,
  longText,
  yesNo
}

class QuestionValidation {
  final String? type;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final String? errorMessage;

  QuestionValidation({
    this.type,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.errorMessage,
  });

  factory QuestionValidation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return QuestionValidation();

    return QuestionValidation(
      type: map['type'],
      pattern: map['pattern'],
      minLength: map['minLength'],
      maxLength: map['maxLength'],
      min: map['min'],
      max: map['max'],
      errorMessage: map['errorMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'pattern': pattern,
      'minLength': minLength,
      'maxLength': maxLength,
      'min': min,
      'max': max,
      'errorMessage': errorMessage,
    };
  }
}

class QuestionLogic {
  final String? showOnValue;
  final String? hideOnValue;
  final String? dependsOnQuestionId;
  final List<String>? showOnValues;
  final List<String>? hideOnValues;

  QuestionLogic({
    this.showOnValue,
    this.hideOnValue,
    this.dependsOnQuestionId,
    this.showOnValues,
    this.hideOnValues,
  });

  factory QuestionLogic.fromMap(Map<String, dynamic>? map) {
    if (map == null) return QuestionLogic();

    return QuestionLogic(
      showOnValue: map['showOnValue'],
      hideOnValue: map['hideOnValue'],
      dependsOnQuestionId: map['dependsOnQuestionId'],
      showOnValues: map['showOnValues'] != null
          ? List<String>.from(map['showOnValues'])
          : null,
      hideOnValues: map['hideOnValues'] != null
          ? List<String>.from(map['hideOnValues'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showOnValue': showOnValue,
      'hideOnValue': hideOnValue,
      'dependsOnQuestionId': dependsOnQuestionId,
      'showOnValues': showOnValues,
      'hideOnValues': hideOnValues,
    };
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final bool isRequired;
  final String? section;
  final int order;
  final List<String>? options;
  final String? placeholder;
  final String? helpText;
  final QuestionValidation? validation;
  final QuestionLogic? logic;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    this.section,
    required this.order,
    this.options,
    this.placeholder,
    this.helpText,
    this.validation,
    this.logic,
    this.metadata,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      text: data['text'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${data['type']}',
        orElse: () => QuestionType.text,
      ),
      isRequired: data['isRequired'] ?? false,
      section: data['section'],
      order: (data['order'] as num?)?.toInt() ?? 0,
      options:
          data['options'] != null ? List<String>.from(data['options']) : null,
      placeholder: data['placeholder'],
      helpText: data['helpText'],
      validation: QuestionValidation.fromMap(data['validation']),
      logic: QuestionLogic.fromMap(data['logic']),
      metadata: data['metadata'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'type': type.toString().split('.').last,
      'isRequired': isRequired,
      'section': section,
      'order': order,
      'options': options,
      'placeholder': placeholder,
      'helpText': helpText,
      'validation': validation?.toMap(),
      'logic': logic?.toMap(),
      'metadata': metadata,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Question copyWith({
    String? id,
    String? text,
    QuestionType? type,
    bool? isRequired,
    String? section,
    int? order,
    List<String>? options,
    String? placeholder,
    String? helpText,
    QuestionValidation? validation,
    QuestionLogic? logic,
    Map<String, dynamic>? metadata,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      section: section ?? this.section,
      order: order ?? this.order,
      options: options ?? this.options,
      placeholder: placeholder ?? this.placeholder,
      helpText: helpText ?? this.helpText,
      validation: validation ?? this.validation,
      logic: logic ?? this.logic,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuestionSection {
  final String id;
  final String title;
  final String? description;
  final IconData? icon;
  final int order;
  final List<Question> questions;
  final bool isRequired;
  final String? helpText;

  QuestionSection({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    required this.order,
    required this.questions,
    this.isRequired = false,
    this.helpText,
  });
}

class QuestionnaireService extends GetxService {
  final Rxn<DynamicQuestionnaireStructure> _dynamicStructure =
      Rxn<DynamicQuestionnaireStructure>();

  DynamicQuestionnaireStructure? get dynamicStructure =>
      _dynamicStructure.value;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'questionnaire_questions';

  // Observable collections
  final RxList<Question> _questions = <Question>[].obs;
  final RxList<QuestionSection> _sections = <QuestionSection>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Getters
  List<Question> get questions => _questions.value;
  List<QuestionSection> get sections => _sections.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  // Reactive getters for Obx
  RxList<Question> get questionsObs => _questions;
  RxList<QuestionSection> get sectionsObs => _sections;
  RxBool get isLoadingObs => _isLoading;
  RxString get errorObs => _error;

  @override
  void onInit() {
    super.onInit();
    loadDynamicStructure();
  }

  @override
  void onClose() {
    _questions.clear();
    _sections.clear();
    super.onClose();
  }

  /// Load dynamic questionnaire structure from Firestore
  Future<void> loadDynamicStructure() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Load from Firestore instead of assets
      final DocumentSnapshot doc = await _firestore
          .collection('questions')
          .doc('inspection-questions')
          .get();

      if (doc.exists) {
        final dynamicMap = doc.data() as Map<String, dynamic>;
        // Parse the JSON into the dynamic questionnaire structure
        _dynamicStructure.value =
            DynamicQuestionnaireStructure.fromJson(dynamicMap);
      } else {
        throw Exception('Questionnaire structure not found in Firestore');
      }
    } catch (e) {
      _error.value = 'Failed to load dynamic structure: ${e.toString()}';
      Get.snackbar(
        'Error',
        _error.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadQuestions() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final List<Question> loadedQuestions =
          snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();

      _questions.assignAll(loadedQuestions);
      _organizeSections();
    } catch (e) {
      _error.value = 'Failed to load questions: ${e.toString()}';
      Get.snackbar(
        'Error',
        _error.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _organizeSections() {
    final Map<String, List<Question>> sectionMap = {};

    // Group questions by section
    for (final question in _questions) {
      final sectionName = question.section ?? 'General';
      if (!sectionMap.containsKey(sectionName)) {
        sectionMap[sectionName] = [];
      }
      sectionMap[sectionName]!.add(question);
    }

    // Define section configuration
    final List<Map<String, dynamic>> sectionConfig = [
      {
        'name': 'Inspector Information',
        'icon': Icons.person_rounded,
        'description': 'Inspector and inspection details',
        'required': true,
      },
      {
        'name': 'Insured Information',
        'icon': Icons.home_rounded,
        'description': 'Property owner and basic information',
        'required': true,
      },
      {
        'name': 'Location Information',
        'icon': Icons.location_on_rounded,
        'description': 'Property location and neighborhood details',
        'required': true,
      },
      {
        'name': 'Elevation & Structure',
        'icon': Icons.foundation_rounded,
        'description': 'Building structure and foundation details',
        'required': true,
      },
      {
        'name': 'Exterior Features',
        'icon': Icons.home_work_rounded,
        'description': 'External building features and conditions',
        'required': true,
      },
      {
        'name': 'Electrical',
        'icon': Icons.electrical_services_rounded,
        'description': 'Electrical system inspection',
        'required': true,
      },
      {
        'name': 'Plumbing',
        'icon': Icons.plumbing_rounded,
        'description': 'Plumbing system inspection',
        'required': true,
      },
      {
        'name': 'Roof',
        'icon': Icons.roofing_rounded,
        'description': 'Roof condition and materials',
        'required': true,
      },
      {
        'name': 'Garage / Outbuilding',
        'icon': Icons.garage_rounded,
        'description': 'Garage and outbuilding inspection',
        'required': false,
      },
      {
        'name': 'Hazard',
        'icon': Icons.warning_rounded,
        'description': 'Identified hazards and safety issues',
        'required': true,
      },
      {
        'name': 'Possible Hazards',
        'icon': Icons.dangerous_rounded,
        'description': 'Potential hazards and liability concerns',
        'required': true,
      },
      {
        'name': 'General',
        'icon': Icons.quiz_outlined,
        'description': 'Additional notes and observations',
        'required': false,
      },
    ];

    final List<QuestionSection> organizedSections = [];

    // Create sections in defined order
    for (int i = 0; i < sectionConfig.length; i++) {
      final config = sectionConfig[i];
      final sectionName = config['name'];
      final sectionQuestions = sectionMap[sectionName];

      if (sectionQuestions != null && sectionQuestions.isNotEmpty) {
        // Sort questions within section by order
        sectionQuestions.sort((a, b) => a.order.compareTo(b.order));

        organizedSections.add(
          QuestionSection(
            id: sectionName
                .toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll('/', '_'),
            title: sectionName,
            description: config['description'],
            icon: config['icon'],
            order: i,
            questions: sectionQuestions,
            isRequired: config['required'] ?? false,
          ),
        );
      }
    }

    // Add any remaining sections not in the predefined order
    sectionMap.forEach((sectionName, sectionQuestions) {
      if (!sectionConfig.any((config) => config['name'] == sectionName)) {
        sectionQuestions.sort((a, b) => a.order.compareTo(b.order));
        organizedSections.add(
          QuestionSection(
            id: sectionName
                .toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll('/', '_'),
            title: sectionName,
            icon: Icons.quiz_outlined,
            order: sectionConfig.length + organizedSections.length,
            questions: sectionQuestions,
            isRequired: false,
          ),
        );
      }
    });

    _sections.assignAll(organizedSections);
  }

  Future<void> addQuestion(Question question) async {
    try {
      await _firestore.collection(_collection).add(question.toFirestore());
      await loadQuestions();
      Get.snackbar(
        'Success',
        'Question added successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      throw Exception('Failed to add question: ${e.toString()}');
    }
  }

  Future<void> updateQuestion(String questionId, Question question) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(questionId)
          .update(question.toFirestore());
      await loadQuestions();
      Get.snackbar(
        'Success',
        'Question updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      throw Exception('Failed to update question: ${e.toString()}');
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection(_collection).doc(questionId).update(
          {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});
      await loadQuestions();
      Get.snackbar(
        'Success',
        'Question deleted successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      throw Exception('Failed to delete question: ${e.toString()}');
    }
  }

  // Helper methods
  Question? getQuestionById(String questionId) {
    return _questions.firstWhereOrNull((q) => q.id == questionId);
  }

  // Helper method to get dynamic question by ID
  DynamicQuestion? getDynamicQuestionById(String questionId) {
    return _dynamicStructure.value?.getQuestionById(questionId);
  }

  List<Question> getQuestionsBySection(String section) {
    return _questions.where((q) => q.section == section).toList();
  }

  List<Question> getRequiredQuestions() {
    return _questions.where((q) => q.isRequired).toList();
  }

  QuestionSection? getSectionById(String sectionId) {
    return _sections.firstWhereOrNull((s) => s.id == sectionId);
  }

  bool shouldShowQuestion(Question question, Map<String, dynamic> formData) {
    if (question.logic == null) return true;

    final logic = question.logic!;

    if (logic.dependsOnQuestionId != null) {
      final dependentValue = formData[logic.dependsOnQuestionId]?.toString();

      if (logic.showOnValue != null) {
        return dependentValue == logic.showOnValue;
      }

      if (logic.hideOnValue != null) {
        return dependentValue != logic.hideOnValue;
      }

      if (logic.showOnValues != null) {
        return logic.showOnValues!.contains(dependentValue);
      }

      if (logic.hideOnValues != null) {
        return !logic.hideOnValues!.contains(dependentValue);
      }
    }

    return true;
  }

  // Widget generation method for dynamic questions
  Widget getWidgetForDynamicQuestion(
    DynamicQuestion question, {
    String? currentValue,
    Function(String?)? onChanged,
    String? Function(String?)? validator,
    String labelPrefix = '',
    bool hasError = false,
    bool viewOnly = false,
    required Null Function(dynamic otherValue) onOtherChanged,
  }) {
    final label = labelPrefix + question.label;
    switch (question.questionType) {
      case DynamicQuestionType.text:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText: 'Enter ${question.label.toLowerCase()}',
          isRequired:
              true, // All questions are required based on your description
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
      case DynamicQuestionType.longText:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText: 'Enter ${question.label.toLowerCase()}',
          isRequired: true,
          maxLines: 3,
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
      case DynamicQuestionType.number:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText: 'Enter ${question.label.toLowerCase()}',
          isRequired: true,
          keyboardType: TextInputType.number,
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
      case DynamicQuestionType.dropdown:
        return DropdownWidget(
          label: label,
          value: currentValue,
          items: question.effectiveOptions,
          hintText: 'Select ${question.label.toLowerCase()}',
          isRequired: true,
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
      case DynamicQuestionType.date:
        return DateInputWidget(
          label: label,
          initialDate:
              currentValue != null ? DateTime.tryParse(currentValue) : null,
          isRequired: true,
          onChanged: viewOnly
              ? null
              : (date) => onChanged?.call(date?.toIso8601String()),
          validator: (date) => validator?.call(date?.toIso8601String()),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          hasError: hasError,
          enabled: !viewOnly,
        );
      case DynamicQuestionType.radio:
        // Determine the current "Other" text value
        String? otherTextValue;
        String? displayValue = currentValue;
        
        if (question.hasOtherOption && currentValue != null) {
          // If current value is not in the predefined options, it's a custom "Other" value
          if (!question.effectiveOptions.contains(currentValue)) {
            otherTextValue = currentValue;
            displayValue = 'Other';
          }
        }
        
        return RadioButtonWidget(
          label: label,
          options: question.effectiveOptions,
          selectedValue: displayValue,
          isRequired: true,
          onChanged: viewOnly ? null : (value) {
            if (value == 'Other') {
              // When "Other" is selected, don't change the form value yet
              // The form value will be updated when user types in the text field
              onChanged?.call(value);
            } else {
              // For regular options, update normally
              onChanged?.call(value);
            }
          },
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
          hasOther: question.hasOtherOption,
          otherValue: otherTextValue,
          onOtherChanged: viewOnly ? null : (otherValue) {
            // Only call onChanged if there's actually a value
            if (otherValue.trim().isNotEmpty) {
              onChanged?.call(otherValue);
            }
          },
        );
      case DynamicQuestionType.yesNo:
        return RadioButtonWidget(
          label: label,
          options: const ['Yes', 'No'],
          selectedValue: currentValue,
          isRequired: true,
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
      case DynamicQuestionType.yesNoUnknown:
        return RadioButtonWidget(
          label: label,
          options: const ['Yes', 'No', 'Unknown'],
          selectedValue: currentValue,
          isRequired: true,
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
      default:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText: 'Enter ${question.label.toLowerCase()}',
          isRequired: true,
          onChanged: viewOnly ? null : onChanged,
          validator: validator,
          hasError: hasError,
          enabled: !viewOnly,
        );
    }
  }

  // Enhanced validation helpers
  String? validateQuestion(Question question, String? value) {
    if (question.isRequired && (value == null || value.trim().isEmpty)) {
      return question.validation?.errorMessage ??
          '${question.text} is required';
    }

    if (value != null && value.isNotEmpty && question.validation != null) {
      final validation = question.validation!;

      if (validation.type == 'email' && !isValidEmail(value)) {
        return validation.errorMessage ?? 'Please enter a valid email address';
      }

      if (validation.type == 'phone' && !isValidPhoneNumber(value)) {
        return validation.errorMessage ?? 'Please enter a valid phone number';
      }

      if (validation.type == 'zipCode' && !isValidZipCode(value)) {
        return validation.errorMessage ??
            'Please enter a valid 5-digit zip code';
      }

      if (validation.pattern != null &&
          !RegExp(validation.pattern!).hasMatch(value)) {
        return validation.errorMessage ?? 'Please enter a valid format';
      }

      if (validation.minLength != null &&
          value.length < validation.minLength!) {
        return validation.errorMessage ??
            'Must be at least ${validation.minLength} characters';
      }

      if (validation.maxLength != null &&
          value.length > validation.maxLength!) {
        return validation.errorMessage ??
            'Must be no more than ${validation.maxLength} characters';
      }

      if (question.type == QuestionType.number) {
        final numValue = num.tryParse(value);
        if (numValue == null) {
          return validation.errorMessage ?? 'Please enter a valid number';
        }

        if (validation.min != null && numValue < validation.min!) {
          return validation.errorMessage ??
              'Must be at least ${validation.min}';
        }

        if (validation.max != null && numValue > validation.max!) {
          return validation.errorMessage ??
              'Must be no more than ${validation.max}';
        }
      }
    }

    return null;
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone);
  }

  bool isValidZipCode(String zipCode) {
    return RegExp(r'^\d{5}$').hasMatch(zipCode);
  }

  // Data persistence helpers
  Future<void> saveFormData(Map<String, dynamic> formData) async {
    try {
      await _firestore.collection('form_submissions').add({
        'formData': formData,
        'timestamp': FieldValue.serverTimestamp(),
        'version': '1.0',
      });
    } catch (e) {
      throw Exception('Failed to save form data: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> loadFormData(String submissionId) async {
    try {
      final doc = await _firestore
          .collection('form_submissions')
          .doc(submissionId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['formData'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load form data: ${e.toString()}');
    }
  }

  // Statistics and analytics
  int get totalQuestions => _questions.length;
  int get totalSections => _sections.length;
  int get requiredQuestionsCount => getRequiredQuestions().length;

  Map<String, int> get questionsBySection {
    final Map<String, int> counts = {};
    for (final section in _sections) {
      counts[section.title] = section.questions.length;
    }
    return counts;
  }
}
