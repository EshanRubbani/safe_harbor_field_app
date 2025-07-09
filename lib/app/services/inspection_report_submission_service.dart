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

      // Create report data structure
      final reportData = _createReportData(
        questionnaireData: questionnaireData,
        imageUrlsByCategory: imageUrlsByCategory ?? _generateDummyImageUrls(),
      );

      // Submit to Firestore
      final docRef = await _firestore.collection(_collection).add(reportData);

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
      _error.value = 'Failed to submit inspection report: ${e.toString()}';
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
  }) {
    return {
      // Basic metadata
      'report_id': _generateReportId(),
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
      // 'summary': _generateSummary(questionnaireData, imageUrlsByCategory),
    };
  }

  // Extract inspector information from questionnaire data
  Map<String, dynamic> _extractInspectorInfo(Map<String, dynamic> data) {
    return {
      'name': data['inspector_name'] ?? '',
      'drone_number': data['drone_number'] ?? '',
      'policy_number': data['policy_number'] ?? '',
      'inspection_date': data['inspection_date'] ?? '',
    };
  }

  // Extract insured information from questionnaire data
  Map<String, dynamic> _extractInsuredInfo(Map<String, dynamic> data) {
    return {
      'name': data['insured_name'] ?? '',
      'street_address': data['insured_address'] ?? '',
      'state': data['insured_state'] ?? '',
      'zip_code': data['insured_zip'] ?? '',
    };
  }

  // Extract property details from questionnaire data
  Map<String, dynamic> _extractPropertyDetails(Map<String, dynamic> data) {
    return {
      'neighborhood': data['neighborhood'] ?? '',
      'area_economy': data['area_economy'] ?? '',
      'property_vacant': data['property_vacant'] ?? '',
      'dwelling_type': data['dwelling_type'] ?? '',
      'year_built': data['year_built'] ?? '',
      'foundation_type': data['foundation_type'] ?? '',
      'primary_construction': data['primary_construction'] ?? '',
      'number_of_stories': data['number_of_stories'] ?? '',
      'living_area_sf': data['living_area_sf'] ?? '',
      'lot_size': data['lot_size'] ?? '',
      'overall_condition': data['overall_elevation_condition'] ?? '',
      'roof_condition': data['overall_roof_condition'] ?? '',
    };
  }

  // Generate summary statistics
  Map<String, dynamic> _generateSummary(
    Map<String, dynamic> questionnaireData,
    Map<String, List<String>> imageUrlsByCategory,
  ) {
    int totalQuestions = 94;
    int answeredQuestions = questionnaireData.entries
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .length;
    
    int totalImages = imageUrlsByCategory.values
        .fold(0, (sum, urls) => sum + urls.length);
    
    // Count hazards and issues
    int hazardCount = _countHazards(questionnaireData);
    int issueCount = _countIssues(questionnaireData);
    
    return {
      'total_questions': totalQuestions,
      'answered_questions': answeredQuestions,
      'completion_percentage': (answeredQuestions / totalQuestions * 100).round(),
      'total_images': totalImages,
      'hazard_count': hazardCount,
      'issue_count': issueCount,
      'categories_with_images': imageUrlsByCategory.keys.toList(),
    };
  }

  // Count identified hazards
  int _countHazards(Map<String, dynamic> data) {
    int count = 0;
    final hazardFields = [
      'boarded_doors_windows',
      'overgrown_vegetation',
      'abandoned_vehicles',
      'missing_damaged_steps',
      'missing_damage_railing',
      'tree_branch',
      'swimming_pool',
      'trampoline',
      'dog',
    ];
    
    for (final field in hazardFields) {
      if (data[field] == 'Yes') count++;
    }
    
    return count;
  }

  // Count structural issues
  int _countIssues(Map<String, dynamic> data) {
    int count = 0;
    final issueFields = [
      'siding_damage',
      'peeling_paint',
      'mildew_moss',
      'window_damage',
      'foundation_cracks',
      'wall_cracks',
      'chimney_damage',
      'water_damage',
      'door_damage',
      'missing_shingles_tiles',
      'curling_shingles',
      'broken_cracked_tiles',
      'uneven_decking',
    ];
    
    for (final field in issueFields) {
      if (data[field] == 'Yes') count++;
    }
    
    return count;
  }

  // Generate dummy image URLs for testing
  Map<String, List<String>> _generateDummyImageUrls() {
    return {
      'exterior_front': [
        'https://firebasestorage.googleapis.com/dummy/exterior_front_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/exterior_front_2.jpg',
      ],
      'exterior_back': [
        'https://firebasestorage.googleapis.com/dummy/exterior_back_1.jpg',
      ],
      'exterior_left': [
        'https://firebasestorage.googleapis.com/dummy/exterior_left_1.jpg',
      ],
      'exterior_right': [
        'https://firebasestorage.googleapis.com/dummy/exterior_right_1.jpg',
      ],
      'roof_overview': [
        'https://firebasestorage.googleapis.com/dummy/roof_overview_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/roof_overview_2.jpg',
        'https://firebasestorage.googleapis.com/dummy/roof_overview_3.jpg',
      ],
      'roof_details': [
        'https://firebasestorage.googleapis.com/dummy/roof_details_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/roof_details_2.jpg',
      ],
      'hvac_systems': [
        'https://firebasestorage.googleapis.com/dummy/hvac_1.jpg',
      ],
      'electrical_panel': [
        'https://firebasestorage.googleapis.com/dummy/electrical_1.jpg',
      ],
      'foundation': [
        'https://firebasestorage.googleapis.com/dummy/foundation_1.jpg',
      ],
      'garage_outbuilding': [
        'https://firebasestorage.googleapis.com/dummy/garage_1.jpg',
      ],
      'hazards': [
        'https://firebasestorage.googleapis.com/dummy/hazard_1.jpg',
      ],
      'damages': [
        'https://firebasestorage.googleapis.com/dummy/damage_1.jpg',
        'https://firebasestorage.googleapis.com/dummy/damage_2.jpg',
      ],
    };
  }

  // Generate unique report ID
  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'RPT_${timestamp}_$random';
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

  // Update inspection report
  Future<bool> updateInspectionReport(
    String reportId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        ...updatedData,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error.value = 'Failed to update inspection report: ${e.toString()}';
      return false;
    }
  }

  // Delete inspection report
  Future<bool> deleteInspectionReport(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).delete();
      return true;
    } catch (e) {
      _error.value = 'Failed to delete inspection report: ${e.toString()}';
      return false;
    }
  }

  // Get reports summary/statistics
  Future<Map<String, dynamic>> getReportsSummary() async {
    try {
      if (currentUserId == null) return {};
      
      final query = await _firestore
          .collection(_collection)
          .where('inspector_id', isEqualTo: currentUserId)
          .get();

      final reports = query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      return {
        'total_reports': reports.length,
        'reports_this_month': reports.where((report) {
          final createdAt = report['created_at'] as Timestamp?;
          if (createdAt == null) return false;
          final now = DateTime.now();
          final reportDate = createdAt.toDate();
          return reportDate.year == now.year && reportDate.month == now.month;
        }).length,
        'average_hazards': reports.isEmpty ? 0 : reports
            .map((r) => (r['summary']?['hazard_count'] as int?) ?? 0)
            .reduce((a, b) => a + b) / reports.length,
        'average_issues': reports.isEmpty ? 0 : reports
            .map((r) => (r['summary']?['issue_count'] as int?) ?? 0)
            .reduce((a, b) => a + b) / reports.length,
      };
    } catch (e) {
      _error.value = 'Failed to fetch reports summary: ${e.toString()}';
      return {};
    }
  }
}