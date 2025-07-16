import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inspection_report_model.dart';
import 'inspection_photos_controller.dart';
import 'inspection_questionaire_controller.dart';
import '../services/inspection_report_submission_service.dart';
import '../services/dynamic_pdf_generation_service.dart';

/*
InspectionReportsController
--------------------------
This controller manages the lifecycle and persistence of inspection reports.

- All report data (questionnaire + images) is centralized in InspectionReportModel.
- Controllers (questionnaire/photos) always update/load their state from the model.
- Every change (form or photo) triggers an immediate atomic save to local storage.
- Incomplete reports can be resumed perfectly, even after app restarts.
- Completed reports are uploaded and cannot be resumed/viewed (no read-only logic).
- Serialization/deserialization is robust and versioned for future migrations.
- Print/debug statements are included for every lifecycle event and error.
*/
class InspectionReportsController extends GetxController {
  static const String localReportsKey = 'local_inspection_reports';

  final RxList<InspectionReportModel> localReports =
      <InspectionReportModel>[].obs;
  final RxList<InspectionReportModel> uploadedReports =
      <InspectionReportModel>[].obs;
  final Rx<InspectionReportModel?> currentReport =
      Rx<InspectionReportModel?>(null);
  final RxList<InspectionReportModel> cloudReports =
      <InspectionReportModel>[].obs;
  final RxBool isLoadingCloudReports = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoadingReport = false.obs;

  late SharedPreferences _prefs;
  late InspectionPhotosController photosController;
  late QuestionnaireController questionnaireController;
  late InspectionReportService reportService;

  @override
  void onInit() {
    super.onInit();
    /*
    Lifecycle: Initialization
    - Loads local reports from storage.
    - Prepares controllers for use.
    */
    _prefs = Get.find<SharedPreferences>();
    photosController = Get.find<InspectionPhotosController>();
    questionnaireController = Get.find<QuestionnaireController>();
    reportService = Get.find<InspectionReportService>();
    print(
        '[Lifecycle] InspectionReportsController initialized. Loading local reports...');
    loadLocalReports();
  }

  /// Start a new inspection report.
  /// - Clears all controller state.
  /// - Creates a fresh model and saves immediately.
  /// - All progress is now tracked atomically.
  void startNewReport(String userId) {
    print('[Lifecycle] Starting new report for user: $userId');
    final newReport = InspectionReportModel(
      id: _generateReportId(),
      userId: userId,
      status: InspectionReportStatus.inProgress,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questionnaireResponses: {},
      images: {},
      syncedToCloud: false,
    );
    currentReport.value = newReport;
    questionnaireController.formData.clear();
    photosController.clearData();
    saveCurrentReportProgress();
  }

  /// Save current report progress atomically.
  /// - Always updates the model from controllers first.
  /// - Persists to local storage.
  /// - Called automatically on every change.
  /// - Prevents duplicate saves with debouncing
  Timer? _saveDebounce;
  bool _isSavingInProgress = false;

  void saveCurrentReportProgress() {
    // Prevent duplicate saves
    if (_isSavingInProgress) {
      print('[Save] Save already in progress, skipping...');
      return;
    }

    // Cancel any pending saves
    _saveDebounce?.cancel();

    // Debounce saves to prevent rapid-fire saves
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSave();
    });
  }

  void _performSave() {
    _isSavingInProgress = true;
    isSaving.value = true;

    try {
      if (currentReport.value == null) {
        print('[Save] No current report to save.');
        return;
      }

      final report = currentReport.value!;
      final formData = questionnaireController.getFormData();
      final imagesMap = photosController.getAllPhotosAsMap();

      // Skip saving if both formData and all photo lists are empty
      if (formData.isEmpty && imagesMap.values.every((l) => l.isEmpty)) {
        print('[WARNING] Skipping save: No data to save');
        return;
      }

      print('[DEBUG] Saving formData: ' + formData.toString());
      print('[DEBUG] Saving images: ' + imagesMap.toString());

      report.questionnaireResponses = formData;
      report.images = imagesMap;
      report.updatedAt = DateTime.now();

      // Auto-assess completion status based on photos and questionnaire
      if (report.status != InspectionReportStatus.uploaded) {
        final totalQuestions = questionnaireController.totalQuestions;
        if (report.isCompleted(totalQuestions: totalQuestions)) {
          report.status = InspectionReportStatus.completed;
          print('[Save] Report marked as completed: ${report.id}');
        } else {
          report.status = InspectionReportStatus.inProgress;
        }
      }

      // Check for existing report and prevent duplicates
      final idx = localReports.indexWhere((r) => r.id == report.id);
      if (idx >= 0) {
        localReports[idx] = report;
        print(
            '[Save] Updated existing report in localReports: [32m${report.id}[0m');
      } else {
        // Double-check for duplicates before adding
        if (!localReports.any((r) => r.id == report.id)) {
          localReports.add(report);
          print('[Save] Added new report to localReports: [32m${report.id}[0m');
        } else {
          print('[WARNING] Prevented duplicate report addition: ${report.id}');
        }
      }

      _saveLocalReportsToPrefs();
      print('[Save] Saved report progress to local storage: ${report.id}');
    } finally {
      _isSavingInProgress = false;
      isSaving.value = false;
    }
  }

  /// Resume an incomplete report.
  /// - Loads model from storage.
  /// - Populates all controller state from the model.
  Future<void> resumeReport(String reportId) async {
    print('[Lifecycle] Attempting to resume report: $reportId');
    isLoadingReport.value = true;
    try {
      final report = localReports.firstWhereOrNull((r) => r.id == reportId);
      if (report != null) {
        // Pause auto-save in both controllers
        questionnaireController.pauseAutoSave();
        photosController.pauseAutoSave();
        // Clear controllers before loading new data
        questionnaireController.formData.clear();
        photosController.clearData();
        // Set current report
        currentReport.value = report;
        // Load questionnaire data (synchronous)
        print('[DEBUG] Loading formData into controller: ' +
            report.questionnaireResponses.toString());
        questionnaireController.loadFormData(report.questionnaireResponses);
        print('[DEBUG] Controller formData after load: ' +
            questionnaireController.formData.toString());
        // Load photos data (asynchronous)
        print('[DEBUG] Loading images into controller: ' +
            report.images.toString());
        await photosController.loadPhotosFromMap(report.images);
        print('[DEBUG] Controller images after load: ' +
            photosController.getAllPhotosAsMap().toString());
        print(
            '[Lifecycle] Successfully resumed report: $reportId. Data loaded into controllers.');
        // Resume auto-save after a short delay to avoid race condition
        Future.delayed(const Duration(seconds: 1), () {
          questionnaireController.resumeAutoSave();
          photosController.resumeAutoSave();
        });
      } else {
        print('[Lifecycle] No report found with ID: $reportId');
        Get.snackbar(
          'Error',
          'Report not found: $reportId',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('[Lifecycle] Error resuming report $reportId: $e');
      Get.snackbar(
        'Error',
        'Failed to resume report: $e',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingReport.value = false;
    }
  }

  /// Assess and update the current report status based on completion checks.
  void assessReportCompletion(String reportId) {
    final report = localReports.firstWhereOrNull((r) => r.id == reportId);
    if (report == null) return;
    final totalQuestions = questionnaireController.totalQuestions;
    if (report.isCompleted(totalQuestions: totalQuestions)) {
      report.status = InspectionReportStatus.completed;
    } else {
      report.status = InspectionReportStatus.inProgress;
    }
    saveCurrentReportProgress();
  }

  /// Complete and upload the current report if it is fully completed.
  /// - Marks as uploaded and saves again if successful.
  Future<void> completeAndUploadCurrentReport() async {
    if (currentReport.value == null) {
      print('[Complete/Upload] No current report to complete/upload.');
      return;
    }
    final report = currentReport.value!;

    final totalQuestions = questionnaireController.totalQuestions;
    if (!report.isCompleted(totalQuestions: totalQuestions)) {
      print('[Complete/Upload] Report is not completed: ${report.id}');
      return;
    }

    report.status = InspectionReportStatus.completed;
    report.updatedAt = DateTime.now();
    saveCurrentReportProgress();
    print(
        '[Complete/Upload] Marked report as completed: ${report.id}. Uploading to Firestore...');
    final reportId = await reportService.submitInspectionReport(
      questionnaireData: report.questionnaireResponses,
      imageUrlsByCategory: report.images,
      Summary: 'Summary',
    );
    if (reportId != null) {
      report.status = InspectionReportStatus.uploaded;
      report.syncedToCloud = true;
      saveCurrentReportProgress();
      print(
          '[Complete/Upload] Report uploaded to Firestore and marked as uploaded: ${report.id}');

      // Clean up uploaded reports from local storage after successful sync
      Future.delayed(const Duration(seconds: 2), () {
        _cleanupUploadedReports();
      });

      // Clear current report to prevent duplication
      currentReport.value = null;
      questionnaireController.resetForm();
      photosController.clearData();
    } else {
      print('[Complete/Upload] Failed to upload report: ${report.id}');
    }
  }

  /// Get all incomplete (in-progress) reports.
  List<InspectionReportModel> getIncompleteReports() {
    final incompletes = localReports
        .where((r) => r.status != InspectionReportStatus.uploaded)
        .toList();
    print('[Query] Fetched incomplete reports: count=${incompletes.length}');
    return incompletes;
  }

  /// Get all uploaded (completed) reports.
  List<InspectionReportModel> getUploadedReports() {
    final uploaded = localReports
        .where((r) => r.status == InspectionReportStatus.uploaded)
        .toList();
    print('[Query] Fetched uploaded reports: count=${uploaded.length}');
    return uploaded;
  }

  /// Load all local reports from SharedPreferences.
  void loadLocalReports() {
    try {
      final jsonStr = _prefs.getString(localReportsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        // Filter out nulls and non-Map entries before deserialization
        final validJsonList = jsonList
            .where((e) => e != null && e is Map<String, dynamic>)
            .toList();

        // Safely deserialize each report
        final List<InspectionReportModel> reports = [];
        for (final jsonItem in validJsonList) {
          try {
            final report = InspectionReportModel.fromJson(
                jsonItem as Map<String, dynamic>);
            reports.add(report);
          } catch (e) {
            print('[Load] Failed to deserialize report: $e');
            print('[Load] Problematic JSON: $jsonItem');
          }
        }

        localReports.assignAll(reports);
        print(
            '[Load] Loaded local reports from storage. Count: ${localReports.length}');
        if (jsonList.length != reports.length) {
          print(
              '[WARNING] Skipped ${jsonList.length - reports.length} invalid or corrupted report entries during load.');
        }
      } else {
        print('[Load] No local reports found in storage.');
      }
    } catch (e) {
      print('[Load] Error loading local reports: $e');
      // Clear corrupted data
      _prefs.remove(localReportsKey);
      localReports.clear();
    }
  }

  /// Save all local reports to SharedPreferences.
  void _saveLocalReportsToPrefs() {
    final jsonList = localReports.map((r) => r.toJson()).toList();
    _prefs.setString(localReportsKey, json.encode(jsonList));
    print(
        '[Save] All local reports saved to SharedPreferences. Count: ${localReports.length}');
  }

  /// Generate a unique report ID.
  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'RPT_${timestamp}_$random';
  }

  /// Fetch submitted reports from Firestore.
  /// - Only for summary/statistics, not for resuming/viewing.
  Future<void> fetchCloudReports() async {
    isLoadingCloudReports.value = true;
    print('🌩️ [Cloud] Starting to fetch submitted reports from Firestore...');
    try {
      print('📡 [Cloud] Calling reportService.getInspectionReports()...');
      final List<Map<String, dynamic>> cloudData =
          await reportService.getInspectionReports();
      print('📥 [Cloud] Received ${cloudData.length} reports from Firestore');

      // Process each report with detailed logging
      final processedReports = <InspectionReportModel>[];
      for (int i = 0; i < cloudData.length; i++) {
        final data = cloudData[i];
        print('🔄 [Cloud] Processing report ${i + 1}/${cloudData.length}');
        print('📋 [Cloud] Raw data keys: ${data.keys.toList()}');

        try {
          // Log each field before processing
          print(
              '🆔 [Cloud] Report ID: ${data['id'] ?? data['report_id'] ?? 'MISSING'}');
          print(
              '👤 [Cloud] Inspector ID: ${data['inspector_id'] ?? 'MISSING'}');
          print(
              '📅 [Cloud] Created at type: ${data['created_at']?.runtimeType}');
          print(
              '📅 [Cloud] Updated at type: ${data['updated_at']?.runtimeType}');
          print(
              '❓ [Cloud] Questionnaire responses type: ${data['questionnaire_responses']?.runtimeType}');
          print('🖼️ [Cloud] Images type: ${data['images']?.runtimeType}');
          print('📊 [Cloud] Summary type: ${data['summary']?.runtimeType}');
          print('🔢 [Cloud] Version: ${data['version'] ?? 'MISSING'}');

          // Parse questionnaire responses with detailed logging
          print('🔍 [Cloud] Parsing questionnaire responses...');
          final questionnaireResponses =
              _parseQuestionnaireResponses(data['questionnaire_responses']);
          print(
              '✅ [Cloud] Questionnaire responses parsed successfully: ${questionnaireResponses.length} items');

          // Parse images with detailed logging
          print('🔍 [Cloud] Parsing images...');
          final images = _parseImages(data['images']);
          print(
              '✅ [Cloud] Images parsed successfully: ${images.length} categories');

          // Create the report model
          final report = InspectionReportModel(
            id: data['id'] ?? data['report_id'] ?? '',
            userId: data['inspector_id'] ?? '',
            status: InspectionReportStatus.uploaded,
            createdAt: (data['created_at'] is DateTime)
                ? data['created_at']
                : (data['created_at'] is Timestamp)
                    ? (data['created_at'] as Timestamp).toDate()
                    : DateTime.tryParse(data['created_at']?.toString() ?? '') ??
                        DateTime.now(),
            updatedAt: (data['updated_at'] is DateTime)
                ? data['updated_at']
                : (data['updated_at'] is Timestamp)
                    ? (data['updated_at'] as Timestamp).toDate()
                    : DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
                        DateTime.now(),
            questionnaireResponses: questionnaireResponses,
            images: images,
            syncedToCloud: true,
            summary: data['summary']?.toString(),
            version: data['version'] as String? ?? '1.0',
          );

          processedReports.add(report);
          print(
              '✅ [Cloud] Report ${i + 1} processed successfully: ${report.id}');
        } catch (e) {
          print('❌ [Cloud] Error processing report ${i + 1}: $e');
          print('🔍 [Cloud] Problematic data: $data');
          // Continue with next report instead of failing completely
        }
      }

      print(
          '📦 [Cloud] Assigning ${processedReports.length} processed reports to cloudReports...');
      cloudReports.assignAll(processedReports);
      print(
          '🎉 [Cloud] Cloud reports successfully assigned. Final count: ${cloudReports.length}');
    } catch (e) {
      print('💥 [Cloud] Critical error fetching cloud reports: $e');
      print('🔍 [Cloud] Error type: ${e.runtimeType}');
      if (e is TypeError) {
        print('🔍 [Cloud] TypeError details: ${e.toString()}');
      }
    } finally {
      isLoadingCloudReports.value = false;
      print('🏁 [Cloud] Finished fetchCloudReports process');
    }
  }

  /// Generate dynamic PDF for a specific report
  Future<String?> generateDynamicPDF(String reportId) async {
    final report = localReports.firstWhereOrNull((r) => r.id == reportId);
    if (report == null) {
      print('[PDF] Report not found: $reportId');
      return null;
    }

    try {
      print('[PDF] Generating dynamic PDF for report: $reportId');
      final dynamicPdfService = Get.find<DynamicPDFGenerationService>();

      final pdfBytes = await dynamicPdfService.generatePDFFromInspectionReport(
        report: report,
        summary:
            'This inspection report has been completed in accordance with standard underwriting guidelines.',
      );

      // Save PDF to device storage
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'inspection_report_${report.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('[PDF] PDF generated successfully at: $filePath');
      return filePath;
    } catch (e) {
      print('[PDF] Error generating PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// Upload a specific completed report to Firestore
  Future<bool> uploadReport(String reportId) async {
    final report = localReports.firstWhereOrNull((r) => r.id == reportId);
    if (report == null) {
      print('[Upload] Report not found: $reportId');
      return false;
    }

    if (report.status == InspectionReportStatus.uploaded) {
      print('[Upload] Report already uploaded: $reportId');
      return true;
    }

    final totalQuestions = questionnaireController.totalQuestions;
    if (!report.isCompleted(totalQuestions: totalQuestions)) {
      print('[Upload] Report is not completed: $reportId');
      Get.snackbar(
        'Cannot Upload',
        'This report is not complete. Please finish all photos and questionnaire responses.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      print('[Upload] Uploading report to Firestore: $reportId');
      final firestoreReportId = await reportService.submitInspectionReport(
        questionnaireData: report.questionnaireResponses,
        imageUrlsByCategory: report.images,
        Summary: 'Summary',
      );

      if (firestoreReportId != null) {
        report.status = InspectionReportStatus.uploaded;
        report.syncedToCloud = true;
        report.updatedAt = DateTime.now();

        final idx = localReports.indexWhere((r) => r.id == reportId);
        if (idx >= 0) {
          localReports[idx] = report;
        }
        _saveLocalReportsToPrefs();

        print('[Upload] Report uploaded successfully: $reportId');

        // Clean up uploaded reports from local storage after successful sync
        Future.delayed(const Duration(seconds: 2), () {
          _cleanupUploadedReports();
        });

        return true;
      }
      return false;
    } catch (e) {
      print('[Upload] Error uploading report $reportId: $e');
      Get.snackbar(
        'Upload Failed',
        'Failed to upload report: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Delete an in-progress report by id.
  Future<void> deleteInProgressReport(String reportId) async {
    final idx = localReports.indexWhere(
        (r) => r.id == reportId && r.status != InspectionReportStatus.uploaded);
    if (idx >= 0) {
      print('[Delete] Deleting in-progress report: $reportId');
      final report = localReports[idx];
      // Delete associated photo files
      try {
        for (final photoList in report.images.values) {
          for (final photoPath in photoList) {
            final file = File(photoPath);
            if (await file.exists()) {
              await file.delete();
              print('[Delete] Deleted photo file: $photoPath');
            }
          }
        }
      } catch (e) {
        print('[Delete] Error deleting photo files for report $reportId: $e');
      }
      // Remove from local reports
      localReports.removeAt(idx);
      _saveLocalReportsToPrefs();
      // If this was the current report, clear it and controllers
      if (currentReport.value?.id == reportId) {
        currentReport.value = null;
        questionnaireController.formData.clear();
        photosController.clearData();
      }
    } else {
      print('[Delete] Report not found or already uploaded: $reportId');
    }
  }

  /// Helper method to safely parse questionnaire responses from Firestore data
  /// Handles cases where the data might be a Map, String (JSON), or null
  Map<String, dynamic> _parseQuestionnaireResponses(dynamic data) {
    if (data == null) {
      print('[Parse] questionnaire_responses is null, returning empty map');
      return {};
    }

    if (data is Map<String, dynamic>) {
      print('[Parse] questionnaire_responses is already a Map, using as-is');
      return data;
    }

    if (data is String) {
      try {
        print(
            '[Parse] questionnaire_responses is a String, attempting JSON decode');
        final parsed = json.decode(data);
        if (parsed is Map<String, dynamic>) {
          return parsed;
        } else {
          print(
              '[Parse] JSON decoded but result is not a Map: ${parsed.runtimeType}');
          return {};
        }
      } catch (e) {
        print(
            '[Parse] Failed to parse questionnaire_responses JSON string: $e');
        print('[Parse] Problematic data: $data');
        return {};
      }
    }

    print(
        '[Parse] questionnaire_responses has unexpected type: ${data.runtimeType}');
    print('[Parse] Data: $data');
    return {};
  }

  /// Helper method to safely parse images from Firestore data
  /// Handles cases where the data might be a Map, String (JSON), or null
  Map<String, List<String>> _parseImages(dynamic data) {
    if (data == null) {
      print('[Parse] images is null, returning empty map');
      return {};
    }

    if (data is Map<String, dynamic>) {
      print('[Parse] images is a Map, attempting to parse nested lists');
      try {
        final result = <String, List<String>>{};
        data.forEach((key, value) {
          if (value is List) {
            result[key] = value.map((item) => item.toString()).toList();
          } else if (value is String) {
            result[key] = [value];
          } else {
            print(
                '[Parse] Unexpected image value type for key $key: ${value.runtimeType}');
            result[key] = [];
          }
        });
        return result;
      } catch (e) {
        print('[Parse] Error parsing images Map: $e');
        print('[Parse] Problematic data: $data');
        return {};
      }
    }

    if (data is String) {
      try {
        print('[Parse] images is a String, attempting JSON decode');
        final parsed = json.decode(data);
        if (parsed is Map<String, dynamic>) {
          return _parseImages(parsed); // Recursively parse the decoded map
        } else {
          print(
              '[Parse] JSON decoded but result is not a Map: ${parsed.runtimeType}');
          return {};
        }
      } catch (e) {
        print('[Parse] Failed to parse images JSON string: $e');
        print('[Parse] Problematic data: $data');
        return {};
      }
    }

    print('[Parse] images has unexpected type: ${data.runtimeType}');
    print('[Parse] Data: $data');
    return {};
  }

  /// Clean up uploaded reports from local storage
  /// Keep only in-progress and completed reports locally
  void _cleanupUploadedReports() {
    final uploadedCount = localReports
        .where((r) => r.status == InspectionReportStatus.uploaded)
        .length;
    if (uploadedCount > 0) {
      print(
          '[Cleanup] Removing $uploadedCount uploaded reports from local storage...');
      localReports
          .removeWhere((r) => r.status == InspectionReportStatus.uploaded);
      _saveLocalReportsToPrefs();
      print(
          '[Cleanup] Local storage cleaned. Remaining reports: ${localReports.length}');
    }
  }

  /// Force manual cleanup of uploaded reports
  void cleanupUploadedReports() {
    _cleanupUploadedReports();
  }

  @override
  void onClose() {
    _saveDebounce?.cancel();
    super.onClose();
  }

  // Completed reports cannot be resumed or viewed in the app.
  // No read-only/view-only logic is present.
}
