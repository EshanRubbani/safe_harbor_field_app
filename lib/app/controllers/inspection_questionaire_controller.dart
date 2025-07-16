import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_photos_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/services/inspection_report_submission_service.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_reports_controller.dart';
import 'dart:async';
import 'package:safe_harbor_field_app/app/models/dynamic_question_model.dart';

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

  final RxBool viewOnly = false.obs;

  void setViewOnly(bool value) {
    viewOnly.value = value;
  }

  // Get questions and sections from service
List<DynamicQuestion> get questions => _questionnaireService.dynamicStructure?.questions ?? [];
List<DynamicQuestionSectionWithQuestions> get sections => _questionnaireService.dynamicStructure?.organizedSections ?? [];
  bool get isLoading => _questionnaireService.isLoading;
  String get error => _questionnaireService.error;

  bool isLoadingFromModel = false;

  Timer? _autoSaveDebounce;
  bool _autoSavePaused = false;
  final RxBool _hasUnsavedChanges = false.obs;
  final RxBool _isSavingManually = false.obs;

  void pauseAutoSave() {
    _autoSavePaused = true;
  }

  void resumeAutoSave() {
    _autoSavePaused = false;
  }

  // Getter for unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges.value;
  RxBool get hasUnsavedChangesObs => _hasUnsavedChanges;
  
  // Getter for manual saving state
  bool get isSavingManually => _isSavingManually.value;
  RxBool get isSavingManuallyObs => _isSavingManually;

  @override
  void onInit() {
    super.onInit();
    _setupValidation();
    _initializeSectionStates();
    _bindSubmissionState();
    // Track changes without auto-saving
    ever(formData, (_) {
      if (!isLoadingFromModel) {
        _hasUnsavedChanges.value = true;
        print('[Change Tracking] formData changed, marking as unsaved');
      }
    });
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
    
    // Immediately validate the form to update button state
    validateForm();
    
    print('[UpdateForm] Question $questionId updated with value: $value');
    print('[UpdateForm] Form valid: ${isFormValid.value}, Answered: $answeredQuestions/$totalQuestions');
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

  String? validateDynamicQuestion(DynamicQuestion question, dynamic value) {
    // All questions are required in the new structure
    if (value == null || value.toString().trim().isEmpty) {
      fieldErrors[question.id] = true;
      return '${question.label} is required';
    }
    
    fieldErrors[question.id] = false;
    return null;
  }

  void validateForm() {
    bool isValid = true;

    // All questions are required in new structure
    for (final question in questions) {
      final value = formData[question.id];
      if (value == null || value.toString().trim().isEmpty) {
        isValid = false;
        break;
      }
    }

    isFormValid.value = isValid;
    print('[Validation] Form valid: $isValid, Answered: $answeredQuestions, Total: $totalQuestions');
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
        Summary: 'Summary',
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

  // Prepare form data for submission with enhanced structure
  Map<String, dynamic> _prepareSubmissionData() {
    final formDataForSubmission = getFormData();
    final Map<String, dynamic> submissionData = {};
    
    // Convert the enhanced structure to a submission-friendly format
    formDataForSubmission.forEach((fieldKey, fieldData) {
      if (fieldData is Map<String, dynamic> && fieldData.containsKey('value')) {
        // Store both the value and metadata for comprehensive data
        submissionData[fieldKey] = fieldData;
      } else {
        // Fallback for any legacy data
        submissionData[fieldKey] = fieldData;
      }
    });
    
    print('[DEBUG] Prepared submission data: ' + submissionData.toString());
    return submissionData;
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
void loadDynamicFormData() {
  final structure = _questionnaireService.dynamicStructure;
  if (structure == null) {
    print('[ERROR] Dynamic structure not loaded');
    return;
  }

  formData.assignAll({
    for (var question in structure.questions)
      question.id: null, // Initialize with null, will be filled by user
  });

  _initializeSectionStates();
  print('[INFO] Loaded dynamic form data');
}

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
    _hasUnsavedChanges.value = false;
    _isSavingManually.value = false;
  }

  // Method to get form data for saving with enhanced structure including question text
  Map<String, dynamic> getFormData() {
    final Map<String, dynamic> structuredData = <String, dynamic>{};
    
    // Ensure consistent data structure for all question types
    formData.forEach((questionId, value) {
      if (questionId != null && value != null) {
        final question = _questionnaireService.getQuestionById(questionId);
        if (question != null) {
          // Create a field key based on question text for better extraction
          final fieldKey = _convertQuestionToFieldKey(question.text);
          
          // Structure data based on question type for consistency
          dynamic processedValue;
          switch (question.type) {
            case QuestionType.date:
              // Ensure date is stored as ISO string
              if (value is DateTime) {
                processedValue = value.toIso8601String();
              } else if (value is String && value.isNotEmpty) {
                try {
                  final dateTime = DateTime.parse(value);
                  processedValue = dateTime.toIso8601String();
                } catch (e) {
                  processedValue = value;
                }
              } else {
                processedValue = value;
              }
              break;
            case QuestionType.number:
              // Ensure numbers are stored as strings for consistency
              if (value is num) {
                processedValue = value.toString();
              } else {
                processedValue = value.toString();
              }
              break;
            case QuestionType.yesNo:
            case QuestionType.multipleChoice:
            case QuestionType.dropdown:
            case QuestionType.text:
            case QuestionType.longText:
            default:
              // Store as string for consistency
              processedValue = value.toString();
              break;
          }
          
          // Store with both field key and enhanced metadata
          structuredData[fieldKey] = {
            'value': processedValue,
            'question_id': questionId,
            'question_text': question.text,
            'question_type': question.type.toString().split('.').last,
            'section': question.section ?? 'General'
          };
        } else {
          // If question not found, store with fallback structure
          structuredData[questionId] = {
            'value': value.toString(),
            'question_id': questionId,
            'question_text': 'Unknown Question',
            'question_type': 'unknown',
            'section': 'Unknown'
          };
        }
      }
    });
    
    print('[DEBUG] getFormData returning enhanced structured data: ' + structuredData.toString());
    if (structuredData.isEmpty) print('[WARNING] getFormData: structured data is empty!');
    return structuredData;
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

  // Method to manually save form data
  Timer? _manualSaveDebounce;
  
  Future<void> saveFormDataManually() async {
    if (_isSavingManually.value) {
      print('[Manual Save] Save already in progress, ignoring duplicate request');
      return; // Prevent double saves
    }
    
    // Debounce manual saves to prevent rapid clicks
    _manualSaveDebounce?.cancel();
    _manualSaveDebounce = Timer(const Duration(milliseconds: 200), () {
      _performManualSave();
    });
  }
  
  Future<void> _performManualSave() async {
    if (_isSavingManually.value) return;
    
    _isSavingManually.value = true;
    print('[Manual Save] Starting manual save...');
    
    try {
      final reportsController = Get.find<InspectionReportsController>();
      await Future.delayed(const Duration(milliseconds: 300)); // Small delay for UI feedback
      reportsController.saveCurrentReportProgress();
      _hasUnsavedChanges.value = false;
      print('[Manual Save] Manual save completed successfully');
      
      Get.snackbar(
        'Saved',
        'Questionnaire responses saved successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
      );
    } catch (e) {
      print('[Manual Save] Error during manual save: $e');
      Get.snackbar(
        'Error',
        'Failed to save questionnaire responses',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isSavingManually.value = false;
    }
  }

  // Method to save on navigation back
  Future<void> saveOnNavigationBack() async {
    if (_hasUnsavedChanges.value) {
      print('[Navigation Save] Saving before navigation back...');
      try {
        final reportsController = Get.find<InspectionReportsController>();
        reportsController.saveCurrentReportProgress();
        _hasUnsavedChanges.value = false;
        print('[Navigation Save] Navigation save completed');
      } catch (e) {
        print('[Navigation Save] Error during navigation save: $e');
      }
    }
  }

  // Method to load form data (from saved draft)
  void loadFormData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      print('[ERROR] Refusing to load empty formData');
      return;
    }
    isLoadingFromModel = true;
    print('[DEBUG] loadFormData called with: ' + data.toString());
    
    // Clear existing form data first
    formData.clear();
    
    // Load the saved data with proper structure validation
    final Map<String, dynamic> validatedData = <String, dynamic>{};
    
    // Handle both new enhanced structure and legacy structure
    data.forEach((key, value) {
      if (key != null && value != null) {
        if (value is Map<String, dynamic> && value.containsKey('value') && value.containsKey('question_id')) {
          // New enhanced structure - extract the actual value and use question_id as key
          final questionId = value['question_id'] as String;
          final actualValue = value['value'];
          validatedData[questionId] = actualValue;
        } else {
          // Legacy structure or simple key-value pairs
          if (value is String || value is num || value is bool) {
            validatedData[key] = value;
          } else {
            // Convert complex types to string representation
            validatedData[key] = value.toString();
          }
        }
      }
    });
    
    formData.assignAll(validatedData);
    validateForm();
    _hasUnsavedChanges.value = false; // Mark as saved after loading
    print('[DEBUG] formData after assignAll: ' + formData.toString());
    isLoadingFromModel = false;
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

  // Get total number of questions
  int get totalQuestions => questions.length;

  // Get number of answered questions
  int get answeredQuestions {
    return formData.entries
        .where((entry) => entry.value != null && entry.value.toString().trim().isNotEmpty)
        .length;
  }
  
  // Get number of required questions
  int get requiredQuestions {
    return questions.where((q) => q.isRequired).length;
  }
  
  // Get number of answered required questions
  int get answeredRequiredQuestions {
    int count = 0;
    for (final question in questions) {
      if (question.isRequired) {
        final value = formData[question.id];
        if (value != null && value.toString().trim().isNotEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  // Ensures form is valid by answering all questions
  void ensureFormValidity() {
    final questionsCount = totalQuestions;
    if (questionsCount > 0 && answeredQuestions >= questionsCount) {
      isFormValid.value = true;
    } else {
      isFormValid.value = false;
    }
    print("[Form Check] $answeredQuestions out of $totalQuestions answered");
  }

  // Check if all questions are answered
  bool get isAllQuestionsAnswered => answeredQuestions >= totalQuestions;
  
  @override
  void onClose() {
    _manualSaveDebounce?.cancel();
    super.onClose();
  }
}
