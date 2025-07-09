import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_photos_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/services/inspection_report_submission_service.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';

class QuestionnaireController extends GetxController {
  final QuestionnaireService _questionnaireService = Get.put(QuestionnaireService());
  final InspectionReportService _inspectionReportService = Get.put(InspectionReportService());
 
  
  // Dynamic form data storage
  final RxMap<String, dynamic> formData = <String, dynamic>{}.obs;
  final RxMap<String, bool> fieldErrors = <String, bool>{}.obs;
  final RxBool isFormValid = false.obs;

  // Section expansion states
  final RxMap<String, bool> sectionExpanded = <String, bool>{}.obs;

  // Submission state
  final RxBool isSubmitting = false.obs;
  final RxString submissionError = ''.obs;
  final RxString lastSubmittedReportId = ''.obs;

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
    _bindSubmissionState();
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

  void _bindSubmissionState() {
    // Bind submission state from service
    ever(_inspectionReportService.isSubmittingObs, (isSubmitting) {
      this.isSubmitting.value = isSubmitting;
    });
    
    ever(_inspectionReportService.errorObs, (error) {
      submissionError.value = error;
    });
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

  // Submit the complete inspection report
  Future<bool> submitInspectionReport() async {
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

    try {
      // Convert form data to proper format for submission
      final submissionData = _prepareSubmissionData();
      
      // Submit the report
      final reportId = await _inspectionReportService.submitInspectionReport(
        questionnaireData: submissionData,
        imageUrlsByCategory: _getDummyImageUrls(), // Will be replaced with actual image URLs later
      );

      if (reportId != null) {
        lastSubmittedReportId.value = reportId;
        
        // Show success dialog with report ID
        Get.dialog(
          AlertDialog(
            title: const Text('Report Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your inspection report has been submitted successfully!'),
                const SizedBox(height: 8),
                Text(
                  'Report ID: $reportId',
                  style: Get.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  // _showReportOptions();
                  //clear all data in controllers.
                  resetForm();
                  Get.toNamed(AppRoutes.HOME);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      Get.snackbar(
        'Submission Error',
        'Failed to submit report: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  // Prepare form data for submission with proper field mapping
  Map<String, dynamic> _prepareSubmissionData() {
    final Map<String, dynamic> submissionData = {};
    
    // Map all questions to their values
    for (final question in questions) {
      final value = formData[question.id];
      if (value != null) {
        // Convert question text to field key
        final fieldKey = _convertQuestionToFieldKey(question.text);
        submissionData[fieldKey] = value;
      }
    }
    
    return submissionData;
  }

  // Convert question text to database field key
  String _convertQuestionToFieldKey(String questionText) {
    return questionText
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // Get dummy image URLs (to be replaced with actual implementation)
  Map<String, List<String>> _getDummyImageUrls() {
    return {
      'exterior_front': [
        'https://firebasestorage.googleapis.com/dummy/exterior_front_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/exterior_front_2.jpg',
      ],
      'exterior_back': [
        'https://firebasestorage.googleapis.com/dummy/exterior_back_1.jpg',
      ],
      'roof_overview': [
        'https://firebasestorage.googleapis.com/dummy/roof_overview_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/roof_overview_2.jpg',
      ],
      'damages': [
        'https://firebasestorage.googleapis.com/dummy/damage_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/damage_2.jpg',
      ],
    };
  }

  // // Show options after successful submission
  // void _showReportOptions() {
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text('What would you like to do next?'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: const Icon(Icons.description),
  //             title: const Text('View Report'),
  //             onTap: () {
  //               Get.back();
  //               viewSubmittedReport();
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.add_circle_outline),
  //             title: const Text('Start New Report'),
  //             onTap: () {
  //               Get.back();
  //               startNewReport();
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.list),
  //             title: const Text('View All Reports'),
  //             onTap: () {
  //               Get.back();
  //               viewAllReports();
  //             },
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text('Close'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // View the submitted report
  void viewSubmittedReport() {
    if (lastSubmittedReportId.value.isNotEmpty) {
      // Navigate to report view page
      Get.toNamed('/report-view', arguments: {
        'reportId': lastSubmittedReportId.value,
      });
    }
  }

  // Start a new report
  void startNewReport() {
    resetForm();
    Get.snackbar(
      'New Report',
      'Ready to start a new inspection report',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  // View all reports
  void viewAllReports() {
    Get.toNamed('/reports-list');
  }

  // Legacy submit method (for backward compatibility)
  bool submitForm() {
    return submitInspectionReport() as bool;
  }

  // Method to reset form
  void resetForm() {
    final InspectionPhotosController photosController = Get.find<InspectionPhotosController>();
    photosController.clearData(); // Clear all photos in the controller
    formData.clear();
    fieldErrors.clear();
    isFormValid.value = false;
    lastSubmittedReportId.value = '';
    submissionError.value = '';
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

  // Get form completion statistics
  Map<String, dynamic> getFormStats() {
    final totalQuestions = questions.length;
    final answeredQuestions = formData.entries
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .length;
    
    return {
      'total_questions': totalQuestions,
      'answered_questions': answeredQuestions,
      'completion_percentage': totalQuestions > 0 
          ? (answeredQuestions / totalQuestions * 100).round()
          : 0,
      'remaining_questions': totalQuestions - answeredQuestions,
    };
  }

  // Check if form is ready for submission
  bool get isReadyForSubmission => isFormValid.value && !isSubmitting.value;
}