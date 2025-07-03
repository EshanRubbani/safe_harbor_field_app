import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';

class QuestionnaireController extends GetxController {
  final QuestionnaireService _questionnaireService = Get.find<QuestionnaireService>();
  
  // Dynamic form data storage
  final RxMap<String, dynamic> formData = <String, dynamic>{}.obs;
  final RxMap<String, bool> fieldErrors = <String, bool>{}.obs;
  final RxBool isFormValid = false.obs;

  // Section expansion states
  final RxMap<String, bool> sectionExpanded = <String, bool>{}.obs;

  // Get questions and sections from service
  List<Question> get questions => _questionnaireService.questions;
  List<QuestionSection> get sections => _questionnaireService.sections;
  bool get isLoading => _questionnaireService.isLoading;
  String get error => _questionnaireService.error;

  @override
  void onInit() {
    super.onInit();
    _setupValidation();
    _initializeSectionStates();
  }

  void _setupValidation() {
    // Listen to form data changes for validation
    ever(formData, (_) => validateForm());
    
    // Listen to questions changes to reinitialize sections
    ever(_questionnaireService.questionsObs, (_) => _initializeSectionStates());
  }

  void _initializeSectionStates() {
    // Initialize all sections as expanded
    for (final section in sections) {
      sectionExpanded[section.id] = true;
    }
  }

  // Update form data for a specific question
  void updateFormData(String questionId, dynamic value) {
    formData[questionId] = value;
    fieldErrors[questionId] = false;
    validateForm();
  }

  // Get current value for a question
  dynamic getFormValue(String questionId) {
    return formData[questionId];
  }

  // Section toggle methods
  void toggleSection(String sectionId) {
    sectionExpanded[sectionId] = !(sectionExpanded[sectionId] ?? false);
  }

  bool isSectionExpanded(String sectionId) {
    return sectionExpanded[sectionId] ?? false;
  }

  // Validation methods
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.toString().trim().isEmpty) {
      fieldErrors[fieldName] = true;
      return '$fieldName is required';
    }
    fieldErrors[fieldName] = false;
    return null;
  }

  String? validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      fieldErrors['zipCode'] = true;
      return 'Zip code is required';
    }
    if (value.length != 5 || !RegExp(r'^\d{5}$').hasMatch(value)) {
      fieldErrors['zipCode'] = true;
      return 'Please enter a valid 5-digit zip code';
    }
    fieldErrors['zipCode'] = false;
    return null;
  }

  String? validateDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      fieldErrors['date'] = true;
      return 'Date is required';
    }
    try {
      DateTime.parse(dateString);
      fieldErrors['date'] = false;
      return null;
    } catch (e) {
      fieldErrors['date'] = true;
      return 'Please enter a valid date';
    }
  }

  String? validateQuestion(Question question, dynamic value) {
    if (question.isRequired && (value == null || value.toString().trim().isEmpty)) {
      fieldErrors[question.id] = true;
      return '${question.text} is required';
    }

    // Enhanced validation using QuestionValidation
    final validation = question.validation;
    if (value != null && value.toString().isNotEmpty && validation != null) {
      final valStr = value.toString();
      // Pattern validation (e.g., zip code, email, etc.)
      if (validation.pattern != null && !RegExp(validation.pattern!).hasMatch(valStr)) {
        fieldErrors[question.id] = true;
        return validation.errorMessage ?? 'Invalid format';
      }
      // Min/Max length
      if (validation.minLength != null && valStr.length < validation.minLength!) {
        fieldErrors[question.id] = true;
        return validation.errorMessage ?? 'Minimum length is ${validation.minLength}';
      }
      if (validation.maxLength != null && valStr.length > validation.maxLength!) {
        fieldErrors[question.id] = true;
        return validation.errorMessage ?? 'Maximum length is ${validation.maxLength}';
      }
      // Min/Max value (for numbers)
      if (validation.min != null || validation.max != null) {
        final numValue = num.tryParse(valStr);
        if (numValue == null) {
          fieldErrors[question.id] = true;
          return validation.errorMessage ?? 'Invalid number';
        }
        if (validation.min != null && numValue < validation.min!) {
          fieldErrors[question.id] = true;
          return validation.errorMessage ?? 'Minimum value is ${validation.min}';
        }
        if (validation.max != null && numValue > validation.max!) {
          fieldErrors[question.id] = true;
          return validation.errorMessage ?? 'Maximum value is ${validation.max}';
        }
      }
      // Type-specific validation
      if (validation.type == 'date') {
        try {
          DateTime.parse(valStr);
        } catch (e) {
          fieldErrors[question.id] = true;
          return validation.errorMessage ?? 'Please enter a valid date';
        }
      }
    }

    fieldErrors[question.id] = false;
    return null;
  }

  void validateForm() {
    bool isValid = true;

    for (final question in questions) {
      if (question.isRequired) {
        final value = formData[question.id];
        if (value == null || value.toString().trim().isEmpty) {
          isValid = false;
          break;
        }
      }
      // Use enhanced validation for all questions
      final error = validateQuestion(question, formData[question.id]);
      if (error != null) {
        isValid = false;
        break;
      }
    }

    isFormValid.value = isValid;
  }

  bool submitForm() {
    validateForm();
    
    if (!isFormValid.value) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields correctly',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    // Here you would typically send the data to your API
    Get.snackbar(
      'Success',
      'Questionnaire submitted successfully!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );

    return true;
  }

  // Method to reset form
  void resetForm() {
    formData.clear();
    fieldErrors.clear();
    isFormValid.value = false;
  }

  // Method to get form data for saving
  Map<String, dynamic> getFormData() {
    return Map<String, dynamic>.from(formData);
  }

  // Method to load form data (from saved draft)
  void loadFormData(Map<String, dynamic> data) {
    formData.assignAll(data);
    validateForm();
  }

  // Method to save draft
  void saveDraft() {
    final draftData = getFormData();
    // Here you would save to local storage or API
    Get.snackbar(
      'Draft Saved',
      'Your progress has been saved',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.secondary,
      colorText: Get.theme.colorScheme.onSecondary,
    );
  }

  // Method to initialize default questions (call once)
  Future<void> initializeDefaultQuestions() async {
    try {
      await _questionnaireService.initializeDefaultQuestions();
      Get.snackbar(
        'Success',
        'Default questions initialized successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initialize questions: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
}