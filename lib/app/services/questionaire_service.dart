// Incomplete Updated code with fix structure.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    loadQuestions();
  }

  @override
  void onClose() {
    _questions.clear();
    _sections.clear();
    super.onClose();
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

  // Widget generation method
  Widget getWidgetForQuestion(
    Question question, {
    String? currentValue,
    Function(String?)? onChanged,
    String? Function(String?)? validator,
    String labelPrefix = '', // <-- add this
    bool hasError = false,
  }) {
    final label = labelPrefix + question.text;
    switch (question.type) {
      case QuestionType.text:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText:
              question.placeholder ?? 'Enter ${question.text.toLowerCase()}',
          isRequired: question.isRequired,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
        );

      case QuestionType.longText:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText:
              question.placeholder ?? 'Enter ${question.text.toLowerCase()}',
          isRequired: question.isRequired,
          maxLines: 3,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
        );

      case QuestionType.number:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText:
              question.placeholder ?? 'Enter ${question.text.toLowerCase()}',
          isRequired: question.isRequired,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
        );

      case QuestionType.dropdown:
        return DropdownWidget(
          label: label,
          value: currentValue,
          items: question.options ?? [],
          hintText:
              question.placeholder ?? 'Select ${question.text.toLowerCase()}',
          isRequired: question.isRequired,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
        );

      case QuestionType.date:
        return DateInputWidget(
          label: label,
          initialDate:
              currentValue != null ? DateTime.tryParse(currentValue) : null,
          isRequired: question.isRequired,
          onChanged: (date) => onChanged?.call(date?.toIso8601String()),
          validator: (date) => validator?.call(date?.toIso8601String()),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          hasError: hasError,
        );

      case QuestionType.multipleChoice:
        // Use RadioButtonWidget for multiple choice (since it's already imported and styled)
        return RadioButtonWidget(
          label: label,
          options: question.options ?? [],
          selectedValue: currentValue,
          isRequired: question.isRequired,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
        );

      case QuestionType.yesNo:
        return RadioButtonWidget(
          label: label,
          options: const ['Yes', 'No'],
          selectedValue: currentValue,
          isRequired: question.isRequired,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
        );

      default:
        return TextInputWidget(
          label: label,
          initialValue: currentValue,
          hintText:
              question.placeholder ?? 'Enter ${question.text.toLowerCase()}',
          isRequired: question.isRequired,
          onChanged: onChanged,
          validator: validator,
          hasError: hasError,
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

  // Helper method to create a structured question
  Question createQuestion({
    required String text,
    required QuestionType type,
    required bool isRequired,
    required String section,
    required int order,
    List<String>? options,
    String? placeholder,
    String? helpText,
    QuestionValidation? validation,
    QuestionLogic? logic,
    Map<String, dynamic>? metadata,
  }) {
    return Question(
      id: '',
      text: text,
      type: type,
      isRequired: isRequired,
      section: section,
      order: order,
      options: options,
      placeholder: placeholder,
      helpText: helpText,
      validation: validation,
      logic: logic,
      metadata: metadata,
    );
  }

  // Method to initialize default questions (run once)
  Future<void> initializeDefaultQuestions() async {
    try {
      // Check if questions already exist
      final existing = await _firestore.collection(_collection).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return; // Questions already exist
      }

      final List<Question> defaultQuestions = _getDefaultQuestions();

      // Add all default questions in batches
      final batch = _firestore.batch();
      for (final question in defaultQuestions) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, question.toFirestore());
      }
      await batch.commit();

      await loadQuestions();
    } catch (e) {
      throw Exception('Error initializing default questions: $e');
    }
  }

  List<Question> _getDefaultQuestions() {
    return [
      // Inspector Information Section
      createQuestion(
        text: "Inspector's Name",
        type: QuestionType.text,
        isRequired: true,
        section: 'Inspector Information',
        order: 1,
        placeholder: 'Enter inspector name',
        validation: QuestionValidation(
          type: 'text',
          minLength: 2,
          maxLength: 50,
          errorMessage: 'Inspector name must be between 2 and 50 characters',
        ),
      ),

      createQuestion(
        text: 'Drone Number',
        type: QuestionType.text,
        isRequired: true,
        section: 'Inspector Information',
        order: 2,
        placeholder: 'Number of the drone assigned to you',
        validation: QuestionValidation(
          type: 'text',
          minLength: 1,
          maxLength: 20,
          errorMessage: 'Drone number is required',
        ),
      ),

      createQuestion(
        text: 'Policy Number',
        type: QuestionType.text,
        isRequired: true,
        section: 'Inspector Information',
        order: 3,
        placeholder: 'Enter policy number',
        validation: QuestionValidation(
          type: 'text',
          minLength: 5,
          maxLength: 30,
          errorMessage: 'Policy number must be between 5 and 30 characters',
        ),
      ),

      // Insured Information Section
      createQuestion(
        text: 'Insured Name',
        type: QuestionType.text,
        isRequired: true,
        section: 'Insured Information',
        order: 4,
        placeholder: 'Enter insured name',
        validation: QuestionValidation(
          type: 'text',
          minLength: 2,
          maxLength: 100,
          errorMessage: 'Insured name must be between 2 and 100 characters',
        ),
      ),

      createQuestion(
        text: 'Insured Street Address',
        type: QuestionType.longText,
        isRequired: true,
        section: 'Insured Information',
        order: 5,
        placeholder: 'Enter complete address',
        validation: QuestionValidation(
          type: 'text',
          minLength: 10,
          maxLength: 200,
          errorMessage: 'Address must be between 10 and 200 characters',
        ),
      ),

      createQuestion(
        text: 'Insured State',
        type: QuestionType.dropdown,
        isRequired: true,
        section: 'Insured Information',
        order: 6,
        options: [
          'Alabama',
          'Alaska',
          'Arizona',
          'Arkansas',
          'California',
          'Colorado',
          'Connecticut',
          'Delaware',
          'Florida',
          'Georgia',
          'Hawaii',
          'Idaho',
          'Illinois',
          'Indiana',
          'Iowa',
          'Kansas',
          'Kentucky',
          'Louisiana',
          'Maine',
          'Maryland',
          'Massachusetts',
          'Michigan',
          'Minnesota',
          'Mississippi',
          'Missouri',
          'Montana',
          'Nebraska',
          'Nevada',
          'New Hampshire',
          'New Jersey',
          'New Mexico',
          'New York',
          'North Carolina',
          'North Dakota',
          'Ohio',
          'Oklahoma',
          'Oregon',
          'Pennsylvania',
          'Rhode Island',
          'South Carolina',
          'South Dakota',
          'Tennessee',
          'Texas',
          'Utah',
          'Vermont',
          'Virginia',
          'Washington',
          'West Virginia',
          'Wisconsin',
          'Wyoming'
        ],
        placeholder: 'Select state',
      ),

      createQuestion(
        text: 'Insured Zip Code',
        type: QuestionType.number,
        isRequired: true,
        section: 'Insured Information',
        order: 7,
        placeholder: 'Enter 5-digit zip code',
        validation: QuestionValidation(
          type: 'zipCode',
          pattern: r'^\d{5}$',
          errorMessage: 'Please enter a valid 5-digit zip code',
        ),
      ),

      createQuestion(
        text: 'Date of Inspection',
        type: QuestionType.date,
        isRequired: true,
        section: 'Insured Information',
        order: 8,
        placeholder: 'Select inspection date',
      ),

      // Location Information Section
      createQuestion(
        text: 'Neighborhood',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Location Information',
        order: 9,
        options: ['Suburban', 'Rural', 'City'],
      ),

      createQuestion(
        text: 'Area Economy',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Location Information',
        order: 10,
        options: ['Stable', 'Unstable', 'Declining'],
      ),

      createQuestion(
        text: 'Gated Community',
        type: QuestionType.yesNo,
        isRequired: false,
        section: 'Location Information',
        order: 11,
      ),

      createQuestion(
        text: 'Property Vacant',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Location Information',
        order: 12,
      ),

      createQuestion(
        text: 'Nearest Body of Water',
        type: QuestionType.text,
        isRequired: true,
        section: 'Location Information',
        order: 13,
        placeholder: 'Enter nearest body of water',
      ),

      createQuestion(
        text: 'Rental Property',
        type: QuestionType.yesNo,
        isRequired: false,
        section: 'Location Information',
        order: 14,
      ),

      createQuestion(
        text: 'Business On Site',
        type: QuestionType.yesNo,
        isRequired: false,
        section: 'Location Information',
        order: 15,
      ),

      createQuestion(
        text: 'Seasonal Home',
        type: QuestionType.multipleChoice,
        isRequired: false,
        section: 'Location Information',
        order: 16,
        options: ['Yes', 'No', 'Unknown'],
      ),

      createQuestion(
        text: 'Historic Property',
        type: QuestionType.multipleChoice,
        isRequired: false,
        section: 'Location Information',
        order: 17,
        options: ['Yes', 'No', 'Unknown'],
      ),

      createQuestion(
        text: 'Nearest Dwelling (in feet)',
        type: QuestionType.number,
        isRequired: true,
        section: 'Location Information',
        order: 18,
        placeholder: 'Enter distance in feet',
      ),

      // Elevation & Structure Section
      createQuestion(
        text: 'Overall Elevation Condition',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 19,
        options: ['Above average', 'Average', 'Below average'],
      ),

      createQuestion(
        text: 'Dwelling Type',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 20,
        options: ['Single Family', 'Multi Family'],
      ),

      createQuestion(
        text: 'Year Built',
        type: QuestionType.text,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 21,
        placeholder: 'Enter year built or Unknown',
      ),

      createQuestion(
        text: 'Type of Foundation',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 22,
        options: ['Slab', 'Elevated', 'Floating'],
      ),

      createQuestion(
        text: 'Primary Construction',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 23,
        options: ['Wood Frame', 'Steel', 'Masonry'],
      ),

      createQuestion(
        text: 'Number of Stories',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 24,
        options: ['1', '2', '3', 'Other'],
      ),

      createQuestion(
        text: 'Living Area (SF)',
        type: QuestionType.text,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 25,
        placeholder: 'Enter square footage or Unknown',
      ),

      createQuestion(
        text: 'Lot Size',
        type: QuestionType.text,
        isRequired: true,
        section: 'Elevation & Structure',
        order: 26,
        placeholder: 'Enter lot size or Unknown',
      ),

      // Exterior Features Section
      createQuestion(
        text: 'Siding',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Exterior Features',
        order: 27,
        options: ['Wood', 'Vinyl', 'Masonry', 'Other'],
      ),

      createQuestion(
        text: 'HVAC',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Exterior Features',
        order: 28,
        options: ['Central', 'Window Unit', 'Other'],
      ),

      createQuestion(
        text: 'Number of HVAC Systems',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Exterior Features',
        order: 29,
        options: ['1', '2', '3', 'Other'],
      ),

      createQuestion(
        text: 'HVAC Serial Number(s)',
        type: QuestionType.text,
        isRequired: true,
        section: 'Exterior Features',
        order: 30,
        placeholder: 'Separate by commas',
      ),

      createQuestion(
        text: 'Gutters and Downspout',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 31,
      ),

      createQuestion(
        text: 'Fuel Tank',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 32,
      ),

      createQuestion(
        text: 'Siding Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 33,
      ),

      createQuestion(
        text: 'Peeling Paint',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 34,
      ),

      createQuestion(
        text: 'Mildew/Moss',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 35,
      ),

      createQuestion(
        text: 'Window Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 36,
      ),

      createQuestion(
        text: 'Foundation Cracks',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 37,
      ),

      createQuestion(
        text: 'Wall Cracks',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 38,
      ),

      createQuestion(
        text: 'Chimney Damage',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Exterior Features',
        order: 39,
        options: ['Yes', 'No', 'N/A'],
      ),

      createQuestion(
        text: 'Water Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 40,
      ),

      createQuestion(
        text: 'Under Renovation',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 41,
      ),

      createQuestion(
        text: 'Door Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Exterior Features',
        order: 42,
      ),

      // Electrical Section
      createQuestion(
        text: 'Main Breaker Panel',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Electrical',
        order: 43,
      ),

      // Plumbing Section
      createQuestion(
        text: 'Water Spicket Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Plumbing',
        order: 44,
      ),

      // Roof Section
      createQuestion(
        text: 'Overall Roof Condition',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Roof',
        order: 45,
        options: ['Above average', 'Average', 'Below average'],
      ),

      createQuestion(
        text: 'Roof Materials',
        type: QuestionType.text,
        isRequired: true,
        section: 'Roof',
        order: 46,
        placeholder: 'Enter roof materials',
      ),

      createQuestion(
        text: 'Roof Covering',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Roof',
        order: 47,
        options: ['Asphalt', 'Wood', 'Metal', 'Other'],
      ),

      createQuestion(
        text: 'Age of Roof (in years)',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Roof',
        order: 48,
        options: ['0-5', '6-10', '11-15', '16+'],
      ),

      createQuestion(
        text: 'Shape of Roof',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Roof',
        order: 49,
        options: ['Hip and Valley', 'Flat', 'Gable', 'Complex', 'Hip', 'Other'],
      ),

      createQuestion(
        text: 'Tree Limbs on Roof',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 50,
      ),

      createQuestion(
        text: 'Debris On Roof',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 51,
      ),

      createQuestion(
        text: 'Solar Panel',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 52,
      ),

      createQuestion(
        text: 'Exposed Felt',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 53,
      ),

      createQuestion(
        text: 'Missing Shingles/Tiles',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 54,
      ),

      createQuestion(
        text: 'Prior Repairs',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 55,
      ),

      createQuestion(
        text: 'Curling Shingles',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 56,
      ),

      createQuestion(
        text: 'Algae/Moss',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 57,
      ),

      createQuestion(
        text: 'Tarp On Roof',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 58,
      ),

      createQuestion(
        text: 'Broken or Cracked Tiles',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Roof',
        order: 59,
        options: ['Yes', 'No', 'N/A'],
      ),

      createQuestion(
        text: 'Satellite Dish',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 60,
      ),

      createQuestion(
        text: 'Uneven Decking',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Roof',
        order: 61,
      ),

      // Garage / Outbuilding Section
      createQuestion(
        text: 'Garage/Outbuilding Overall Condition',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 62,
        options: ['Above average', 'Average', 'Below average', 'N/A'],
      ),

      createQuestion(
        text: 'Garage Type',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 63,
        options: ['Attached', 'Detached', 'N/A'],
      ),

      createQuestion(
        text: 'Outbuilding',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 64,
        options: ['Yes', 'No', 'N/A'],
      ),

      createQuestion(
        text: 'Outbuilding Type',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 65,
        options: ['Vinyl', 'Metal', 'Wood', 'N/A'],
      ),

      createQuestion(
        text: 'Fence (Height/type/details)',
        type: QuestionType.longText,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 66,
        placeholder: 'Describe fence details',
      ),

      createQuestion(
        text: 'Garage Condition',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 67,
        options: ['Above average', 'Average', 'Below average', 'N/A'],
      ),

      createQuestion(
        text: 'Carport or Awning',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 68,
      ),

      createQuestion(
        text: 'Carport Construction',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 69,
        options: ['Metal', 'Wood', 'N/A'],
      ),

      createQuestion(
        text: 'Fence Condition',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Garage / Outbuilding',
        order: 70,
        options: ['Above average', 'Average', 'Below average', 'N/A'],
      ),

      // Hazard Section
      createQuestion(
        text: 'Boarded Doors/Windows',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 71,
      ),

      createQuestion(
        text: 'Overgrown Vegetation',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 72,
      ),

      createQuestion(
        text: 'Abandoned Vehicles',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 73,
      ),

      createQuestion(
        text: 'Missing/Damaged Steps',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Hazard',
        order: 74,
        options: ['Yes', 'No', 'N/A'],
      ),

      createQuestion(
        text: 'Missing/Damage Railing',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Hazard',
        order: 75,
        options: ['Yes', 'No', 'N/A'],
      ),

      createQuestion(
        text: 'Siding Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 76,
      ),

      createQuestion(
        text: 'Hurricane Shutters',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 77,
      ),

      createQuestion(
        text: 'Tree/Branch',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 78,
      ),

      createQuestion(
        text: 'Chimney Through Roof',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 79,
      ),

      createQuestion(
        text: 'Fireplace/Pit Outside',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 80,
      ),

      createQuestion(
        text: 'Security Bars',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 81,
      ),

      createQuestion(
        text: 'Fascia/Soffit Damage',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Hazard',
        order: 82,
      ),

      // Possible Hazards Section
      createQuestion(
        text: 'Swimming Pool',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 83,
      ),

      createQuestion(
        text: 'Diving Board or Slide',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 84,
      ),

      createQuestion(
        text: 'Pool Fenced',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Possible Hazards',
        order: 85,
        options: ['Yes', 'No', 'N/A'],
      ),

      createQuestion(
        text: 'Trampoline',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 86,
      ),

      createQuestion(
        text: 'Swing Set',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 87,
      ),

      createQuestion(
        text: 'Basketball Goal',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 88,
      ),

      createQuestion(
        text: 'Dog',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 89,
      ),

      createQuestion(
        text: 'Dog Type',
        type: QuestionType.multipleChoice,
        isRequired: true,
        section: 'Possible Hazards',
        order: 90,
        options: ['Small', 'Medium', 'Large', 'N/A'],
      ),

      createQuestion(
        text: 'Dog Sign',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 91,
      ),

      createQuestion(
        text: 'Skateboard or Bike Ramp',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 92,
      ),

      createQuestion(
        text: 'Tree House',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 93,
      ),

      createQuestion(
        text: 'Debris in Yard',
        type: QuestionType.yesNo,
        isRequired: true,
        section: 'Possible Hazards',
        order: 94,
      ),
    ];
  }
}
