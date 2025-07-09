import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_report_model.dart';
import 'inspection_photos_controller.dart';
import 'inspection_questionaire_controller.dart';
import '../services/inspection_report_submission_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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

  final RxList<InspectionReportModel> localReports = <InspectionReportModel>[].obs;
  final RxList<InspectionReportModel> uploadedReports = <InspectionReportModel>[].obs;
  final Rx<InspectionReportModel?> currentReport = Rx<InspectionReportModel?>(null);
  final RxList<InspectionReportModel> cloudReports = <InspectionReportModel>[].obs;
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
    print('[Lifecycle] InspectionReportsController initialized. Loading local reports...');
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
  void saveCurrentReportProgress() {
    isSaving.value = true;
    if (currentReport.value == null) {
      print('[Save] No current report to save.');
      isSaving.value = false;
      return;
    }
    final report = currentReport.value!;
    final formData = questionnaireController.getFormData();
    final imagesMap = photosController.getAllPhotosAsMap();
    print('[DEBUG] Saving formData: ' + formData.toString());
    print('[DEBUG] Saving images: ' + imagesMap.toString());
    if (formData.isEmpty) print('[WARNING] formData is empty when saving!');
    if (imagesMap.values.every((l) => l.isEmpty)) print('[WARNING] images are empty when saving!');
    report.questionnaireResponses = formData;
    report.images = imagesMap;
    report.updatedAt = DateTime.now();
    final idx = localReports.indexWhere((r) => r.id == report.id);
    if (idx >= 0) {
      localReports[idx] = report;
      print('[Save] Updated existing report in localReports:  [32m${report.id} [0m');
    } else {
      localReports.add(report);
      print('[Save] Added new report to localReports:  [32m${report.id} [0m');
    }
    _saveLocalReportsToPrefs();
    print('[Save] Saved report progress to local storage: ${report.id}');
    isSaving.value = false;
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
        // Clear controllers before loading new data
        questionnaireController.formData.clear();
        photosController.clearData();
        // Set current report
        currentReport.value = report;
        // Load questionnaire data (synchronous)
        print('[DEBUG] Loading formData into controller: ' + report.questionnaireResponses.toString());
        questionnaireController.loadFormData(report.questionnaireResponses);
        print('[DEBUG] Controller formData after load: ' + questionnaireController.formData.toString());
        // Load photos data (asynchronous)
        print('[DEBUG] Loading images into controller: ' + report.images.toString());
        await photosController.loadPhotosFromMap(report.images);
        print('[DEBUG] Controller images after load: ' + photosController.getAllPhotosAsMap().toString());
        print('[Lifecycle] Successfully resumed report: $reportId. Data loaded into controllers.');
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

  /// Complete and upload the current report.
  /// - Marks as completed, saves, uploads to Firestore.
  /// - If upload succeeds, marks as uploaded and saves again.
  /// - Completed reports cannot be resumed or viewed.
  Future<void> completeAndUploadCurrentReport() async {
    if (currentReport.value == null) {
      print('[Complete/Upload] No current report to complete/upload.');
      return;
    }
    final report = currentReport.value!;
    report.status = InspectionReportStatus.completed;
    report.updatedAt = DateTime.now();
    saveCurrentReportProgress();
    print('[Complete/Upload] Marked report as completed: ${report.id}. Uploading to Firestore...');
    final reportId = await reportService.submitInspectionReport(
      questionnaireData: report.questionnaireResponses,
      imageUrlsByCategory: report.images,
    );
    if (reportId != null) {
      report.status = InspectionReportStatus.uploaded;
      report.syncedToCloud = true;
      saveCurrentReportProgress();
      print('[Complete/Upload] Report uploaded to Firestore and marked as uploaded: ${report.id}');
    } else {
      print('[Complete/Upload] Failed to upload report: ${report.id}');
    }
  }

  /// Get all incomplete (in-progress) reports.
  List<InspectionReportModel> getIncompleteReports() {
    final incompletes = localReports.where((r) => r.status != InspectionReportStatus.uploaded).toList();
    print('[Query] Fetched incomplete reports: count=${incompletes.length}');
    return incompletes;
  }

  /// Get all uploaded (completed) reports.
  List<InspectionReportModel> getUploadedReports() {
    final uploaded = localReports.where((r) => r.status == InspectionReportStatus.uploaded).toList();
    print('[Query] Fetched uploaded reports: count=${uploaded.length}');
    return uploaded;
  }

  /// Load all local reports from SharedPreferences.
  void loadLocalReports() {
    final jsonStr = _prefs.getString(localReportsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> jsonList = json.decode(jsonStr);
      localReports.assignAll(jsonList.map((e) => InspectionReportModel.fromJson(e)).toList());
      print('[Load] Loaded local reports from storage. Count: ${localReports.length}');
    } else {
      print('[Load] No local reports found in storage.');
    }
  }

  /// Save all local reports to SharedPreferences.
  void _saveLocalReportsToPrefs() {
    final jsonList = localReports.map((r) => r.toJson()).toList();
    _prefs.setString(localReportsKey, json.encode(jsonList));
    print('[Save] All local reports saved to SharedPreferences. Count: ${localReports.length}');
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
    print('[Cloud] Fetching submitted reports from Firestore...');
    try {
      final List<Map<String, dynamic>> cloudData = await reportService.getInspectionReports();
      cloudReports.assignAll(cloudData.map((data) => InspectionReportModel(
        id: data['id'] ?? data['report_id'] ?? '',
        userId: data['inspector_id'] ?? '',
        status: InspectionReportStatus.uploaded,
        createdAt: (data['created_at'] is DateTime)
            ? data['created_at']
            : (data['created_at'] is Timestamp)
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: (data['updated_at'] is DateTime)
            ? data['updated_at']
            : (data['updated_at'] is Timestamp)
                ? (data['updated_at'] as Timestamp).toDate()
                : DateTime.tryParse(data['updated_at']?.toString() ?? '') ?? DateTime.now(),
        questionnaireResponses: Map<String, dynamic>.from(data['questionnaire_responses'] ?? {}),
        images: (data['images'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, List<String>.from(v))) ?? {},
        syncedToCloud: true,
        summary: data['summary'] != null ? Map<String, dynamic>.from(data['summary']) : null,
        version: data['version'] as String? ?? '1.0',
      )));
      print('[Cloud] Cloud reports fetched. Count: ${cloudReports.length}');
    } catch (e) {
      print('[Cloud] Error fetching cloud reports: ' + e.toString());
    } finally {
      isLoadingCloudReports.value = false;
    }
  }

  /// Delete an in-progress report by id.
  Future<void> deleteInProgressReport(String reportId) async {
    final idx = localReports.indexWhere((r) => r.id == reportId && r.status != InspectionReportStatus.uploaded);
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

  // Completed reports cannot be resumed or viewed in the app.
  // No read-only/view-only logic is present.
} 