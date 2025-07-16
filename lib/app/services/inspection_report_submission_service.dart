import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class InspectionReportService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _collection = 'inspection_reports';
  final RxBool _isSubmitting = false.obs;
  final RxString _error = ''.obs;

  // Getters
  bool get isSubmitting => _isSubmitting.value;
  String get error => _error.value;
  RxBool get isSubmittingObs => _isSubmitting;
  RxString get errorObs => _error;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Submit inspection report
  Future<String?> submitInspectionReport({
    required Map<String, dynamic> questionnaireData,
    Map<String, List<String>>? imageUrlsByCategory,
    required String Summary,
  }) async {
    try {
      _isSubmitting.value = true;
      _error.value = '';

      // Validate user is logged in
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Validate required data
      if (questionnaireData.isEmpty) {
        throw Exception('Questionnaire data is required');
      }

      // Create report data structure (without report_id)
      final reportData = _createReportData(
        questionnaireData: questionnaireData,
        imageUrlsByCategory: imageUrlsByCategory ?? {},
        Summary: Summary,
      );

      // Submit to Firestore
      final docRef = await _firestore.collection(_collection).add(reportData);

      // Update the document to set report_id to the Firestore document ID
      await docRef.update({'report_id': docRef.id});

      Get.snackbar(
        'Success',
        'Inspection report submitted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
      );

      return docRef.id;
    } catch (e) {
      _error.value = 'Failed to submit inspection report:  ${e.toString()}';
      Get.snackbar(
        'Error',
        _error.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return null;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // Create comprehensive report data structure
  Map<String, dynamic> _createReportData({
    required Map<String, dynamic> questionnaireData,
    required Map<String, List<String>> imageUrlsByCategory,
    required String Summary,
  }) {
    return {
      // Basic metadata
      // 'report_id': _generateReportId(), // Removed, will be set after doc creation
      'inspector_id': currentUserId,
      'status': 'submitted',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'version': '1.0',

      // All questionnaire responses (including inspector, insured, property)
      'questionnaire_responses': questionnaireData,

      // Image URLs by category
      'images': imageUrlsByCategory,

      // Summary statistics
      'summary': Summary,
    };
  }

  // Get inspection report by ID
  Future<Map<String, dynamic>?> getInspectionReport(String reportId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reportId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _error.value = 'Failed to fetch inspection report: ${e.toString()}';
      return null;
    }
  }

  // Get all inspection reports for current user
  Future<List<Map<String, dynamic>>> getInspectionReports() async {
    try {
      if (currentUserId == null) return [];

      final query = await _firestore
          .collection(_collection)
          .where('inspector_id', isEqualTo: currentUserId)
          .orderBy('created_at', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _error.value = 'Failed to fetch inspection reports: ${e.toString()}';
      return [];
    }
  }
}
