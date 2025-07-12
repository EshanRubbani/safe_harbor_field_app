import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/complete_report_model.dart';
import '../models/inspection_report_model.dart';
import '../controllers/inspection_reports_controller.dart';
import '../controllers/pdf_template_controller.dart';
import '../utils/pdf_template.dart';
import 'inspection_report_submission_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfGenerationService extends GetxService {
  late InspectionReportsController _reportsController;
  late InspectionPDFController _pdfController;
  late InspectionReportService _reportService;
  
  final RxBool isGenerating = false.obs;
  final RxString currentStatus = ''.obs;
  final RxDouble progress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _reportsController = Get.find<InspectionReportsController>();
    _pdfController = Get.find<InspectionPDFController>();
    _reportService = Get.find<InspectionReportService>();
    print('[PDFGenerationService] Service initialized');
  }

  /// Generate PDF from a complete report document ID
  Future<String?> generatePdfFromReportId(String reportId) async {
    try {
      isGenerating.value = true;
      currentStatus.value = 'Fetching report data...';
      progress.value = 0.1;

      // Get complete report document from Firebase
      final reportData = await _reportService.getInspectionReport(reportId);
      if (reportData == null) {
        throw Exception('Report not found with ID: $reportId');
      }

      // Convert Firebase document to CompleteReport model
      final completeReport = CompleteReport.fromJson(reportData);
      
      currentStatus.value = 'Processing report data...';
      progress.value = 0.2;

      return await _generatePdfFromCompleteReport(completeReport);
    } catch (e) {
      print('[PDFGenerationService] Error generating PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    } finally {
      isGenerating.value = false;
      currentStatus.value = '';
      progress.value = 0.0;
    }
  }

  /// Generate PDF from a CompleteReport model
  Future<String?> _generatePdfFromCompleteReport(CompleteReport report) async {
    try {
      currentStatus.value = 'Mapping report data to PDF controller...';
      progress.value = 0.3;

      // Map CompleteReport data to PDF controller
      await _mapCompleteReportToPdfController(report);
      
      currentStatus.value = 'Downloading and processing images...';
      progress.value = 0.4;

      // Download and process images from URLs
      await _downloadAndSetImages(report.images);
      
      currentStatus.value = 'Generating PDF document...';
      progress.value = 0.8;

      // Generate PDF using the PDF controller
      await _pdfController.generatePDF();
      
      currentStatus.value = 'PDF generated successfully!';
      progress.value = 1.0;

      // Automatically open the PDF after generation
      final pdfPath = _pdfController.pdfPath.value;
      if (pdfPath.isNotEmpty) {
        // Small delay to ensure file is fully written
        await Future.delayed(const Duration(milliseconds: 500));
        await _pdfController.openPDF();
      }

      return pdfPath;
    } catch (e) {
      print('[PDFGenerationService] Error in PDF generation process: $e');
      rethrow;
    }
  }

  /// Map CompleteReport data to PDF controller fields
  Future<void> _mapCompleteReportToPdfController(CompleteReport report) async {
    try {
      // Extract questionnaire responses
      final responses = report.questionnaireResponse.responses;
      
      // Map basic property information
      _mapBasicPropertyInfo(responses);
      
      // Map overall risk information
      _mapOverallRiskInfo(responses);
      
      // Map elevation condition
      _mapElevationCondition(responses);
      
      // Map roof condition
      _mapRoofCondition(responses);
      
      // Map garage/outbuilding condition
      _mapGarageCondition(responses);
      
      // Map dwelling hazards
      _mapDwellingHazards(responses);
      
      // Map possible hazards
      _mapPossibleHazards(responses);

      print('[PDFGenerationService] Successfully mapped report data to PDF controller');
    } catch (e) {
      print('[PDFGenerationService] Error mapping report data: $e');
      rethrow;
    }
  }

  /// Map basic property information
  void _mapBasicPropertyInfo(Map<String, Question> responses) {
    _pdfController.updateClientName(_getQuestionValue(responses, 'insured_name'));
    _pdfController.updateAddress(_getQuestionValue(responses, 'insured_street_address'));
    _pdfController.updateState(_getQuestionValue(responses, 'insured_state'));
    _pdfController.updateZipCode(_getQuestionValue(responses, 'insured_zip_code'));
    _pdfController.updatePolicyNumber(_getQuestionValue(responses, 'policy_number'));
    _pdfController.updateDateOfOrigin(_getQuestionValue(responses, 'date_of_inspection'));
    // _pdfController.updateTypeOfInspection(_getQuestionValue(responses, 'type_of_inspection'));
    _pdfController.updateTypeOfInspection("Under-Writing");
    _pdfController.updateInspectorName(_getQuestionValue(responses, 'inspectors_name'));
    _pdfController.updateInspectionDate(_getQuestionValue(responses, 'date_of_inspection'));
    _pdfController.updateReportDate(_getQuestionValue(responses, 'date_of_inspection'));
    // _pdfController.updateSummary(_getQuestionValue(responses, 'Summary'));
    _pdfController.updateSummary("We We We We We We We We We We We We We We We We We We We We We We We We We We We We We We We We We I I I For We I We I For For I For We We I For ");
  }

  /// Map overall risk information
  void _mapOverallRiskInfo(Map<String, Question> responses) {
    _pdfController.updateNeighborhood(_getQuestionValue(responses, 'neighborhood'));
    _pdfController.updateAreaEconomy(_getQuestionValue(responses, 'area_economy'));
    _pdfController.updateGatedCommunity(_getQuestionValue(responses, 'gated_community'));
    _pdfController.updatePropertyVacant(_getQuestionValue(responses, 'property_vacant'));
    _pdfController.updateNearestBodyOfWater(_getQuestionValue(responses, 'nearest_body_of_water'));
    _pdfController.updateRentalProperty(_getQuestionValue(responses, 'rental_property'));
    _pdfController.updateBusinessOnSite(_getQuestionValue(responses, 'business_on_site'));
    _pdfController.updateSeasonalHome(_getQuestionValue(responses, 'seasonal_home'));
    _pdfController.updateHistoricProperty(_getQuestionValue(responses, 'historic_property'));
    _pdfController.updateNearestDwelling(_getQuestionValue(responses, 'nearest_dwelling_in_feet'));
  }

  /// Map elevation condition
  void _mapElevationCondition(Map<String, Question> responses) {
    _pdfController.updateDwellingType(_getQuestionValue(responses, 'dwelling_type'));
    _pdfController.updateYearBuilt(_getQuestionValue(responses, 'year_built'));
    _pdfController.updateTypeOfFoundation(_getQuestionValue(responses, 'type_of_foundation'));
    _pdfController.updatePrimaryConstruction(_getQuestionValue(responses, 'primary_construction'));
    _pdfController.updateNumberOfStories(_getQuestionValue(responses, 'number_of_stories'));
    _pdfController.updateLivingArea(_getQuestionValue(responses, 'living_area_sf'));
    _pdfController.updateLotSize(_getQuestionValue(responses, 'lot_size'));
    _pdfController.updateSiding(_getQuestionValue(responses, 'siding'));
    _pdfController.updateHvac(_getQuestionValue(responses, 'hvac'));
    _pdfController.updateNumberOfSystems(_getQuestionValue(responses, 'number_of_hvac_systems'));
    _pdfController.updateHvacSerial(_getQuestionValue(responses, 'hvac_serial_numbers'));
    _pdfController.updateGuttersAndDownspout(_getQuestionValue(responses, 'gutters_and_downspout'));
    _pdfController.updateFuelTank(_getQuestionValue(responses, 'fuel_tank'));
    _pdfController.updateSidingDamage(_getQuestionValue(responses, 'siding_damage'));
    _pdfController.updatePeelingPaint(_getQuestionValue(responses, 'peeling_paint'));
    _pdfController.updateMildewMoss(_getQuestionValue(responses, 'mildewmoss'));
    _pdfController.updateWindowDamage(_getQuestionValue(responses, 'window_damage'));
    _pdfController.updateFoundationCracks(_getQuestionValue(responses, 'foundation_cracks'));
    _pdfController.updateWallCracks(_getQuestionValue(responses, 'wall_cracks'));
    _pdfController.updateChimneyDamage(_getQuestionValue(responses, 'chimney_damage'));
    _pdfController.updateWaterDamage(_getQuestionValue(responses, 'water_damage'));
    _pdfController.updateUnderRenovation(_getQuestionValue(responses, 'under_renovation'));
    _pdfController.updateMainBreakerPanel(_getQuestionValue(responses, 'main_breaker_panel'));
    _pdfController.updateWaterSpicketDamage(_getQuestionValue(responses, 'water_spicket_damage'));
    _pdfController.updateDoorDamage(_getQuestionValue(responses, 'door_damage'));
  }

  /// Map roof condition
  void _mapRoofCondition(Map<String, Question> responses) {
    _pdfController.updateRoofMaterial(_getQuestionValue(responses, 'roof_materials'));
    _pdfController.updateRoofCovering(_getQuestionValue(responses, 'roof_covering'));
    _pdfController.updateAgeOfRoof(_getQuestionValue(responses, 'age_of_roof_in_years'));
    _pdfController.updateShapeOfRoof(_getQuestionValue(responses, 'shape_of_roof'));
    _pdfController.updateTreeLimbsOnRoof(_getQuestionValue(responses, 'tree_limbs_on_roof'));
    _pdfController.updateDebrisOnRoof(_getQuestionValue(responses, 'debris_on_roof'));
    _pdfController.updateSolarPanel(_getQuestionValue(responses, 'solar_panel'));
    _pdfController.updateExposedFelt(_getQuestionValue(responses, 'exposed_felt'));
    _pdfController.updateMissingShinglesTile(_getQuestionValue(responses, 'missing_shinglestiles'));
    _pdfController.updatePriorRepairs(_getQuestionValue(responses, 'prior_repairs'));
    _pdfController.updateCurlingShingles(_getQuestionValue(responses, 'curling_shingles'));
    _pdfController.updateAlgaeMoss(_getQuestionValue(responses, 'algaemoss'));
    _pdfController.updateTarpOnRoof(_getQuestionValue(responses, 'tarp_on_roof'));
    _pdfController.updateBrokenOrCrackTiles(_getQuestionValue(responses, 'broken_or_cracked_tiles'));
    _pdfController.updateSatelliteDish(_getQuestionValue(responses, 'satellite_dish'));
    _pdfController.updateUnevenDecking(_getQuestionValue(responses, 'uneven_decking'));
  }

  /// Map garage/outbuilding condition
  void _mapGarageCondition(Map<String, Question> responses) {
    _pdfController.updateGarageType(_getQuestionValue(responses, 'garage_type'));
    _pdfController.updateOutbuilding(_getQuestionValue(responses, 'garageoutbuilding_overall_condition'));
    _pdfController.updateOutbuildingType(_getQuestionValue(responses, 'outbuilding_type'));
    _pdfController.updateFence(_getQuestionValue(responses, 'fence_heighttypedetails'));
    _pdfController.updateGarageCondition(_getQuestionValue(responses, 'garage_condition'));
    _pdfController.updateCarportOrAwning(_getQuestionValue(responses, 'carport_or_awning'));
    _pdfController.updateCarportConstruction(_getQuestionValue(responses, 'carport_construction'));
    _pdfController.updateFenceCondition(_getQuestionValue(responses, 'fence_condition'));
  }

  /// Map dwelling hazards
  void _mapDwellingHazards(Map<String, Question> responses) {
    _pdfController.updateBoardedDoorsWindows(_getQuestionValue(responses, 'boarded_doorswindows'));
    _pdfController.updateOvergrownVegetation(_getQuestionValue(responses, 'overgrown_vegetation'));
    _pdfController.updateAbandonedVehicles(_getQuestionValue(responses, 'abandoned_vehicles'));
    _pdfController.updateMissingDamageSteps(_getQuestionValue(responses, 'missingdamaged_steps'));
    _pdfController.updateMissingDamageRailing(_getQuestionValue(responses, 'missingdamage_railing'));
    _pdfController.updateDwellingSidingDamage(_getQuestionValue(responses, 'siding_damaged'));
    _pdfController.updateHurricaneShutters(_getQuestionValue(responses, 'hurricane_shutters'));
    _pdfController.updateTreeBranch(_getQuestionValue(responses, 'treebranch'));
    _pdfController.updateChimneyThroughRoof(_getQuestionValue(responses, 'chimney_through_roof'));
    _pdfController.updateFireplacePitOutside(_getQuestionValue(responses, 'fireplacepit_outside'));
    _pdfController.updateSecurityBars(_getQuestionValue(responses, 'security_bars'));
    // _pdfController.updateFaciaSoffitDamage(_getQuestionValue(responses, 'facia_soffit_damage'));
    _pdfController.updateFaciaSoffitDamage("No");
  }

  /// Map possible hazards
  void _mapPossibleHazards(Map<String, Question> responses) {
    _pdfController.updateSwimmingPool(_getQuestionValue(responses, 'swimming_pool'));
    _pdfController.updateDivingBoardOrSlide(_getQuestionValue(responses, 'diving_board_or_slide'));
    _pdfController.updatePoolFenced(_getQuestionValue(responses, 'pool_fenced'));
    _pdfController.updateTrampoline(_getQuestionValue(responses, 'trampoline'));
    _pdfController.updateSwingSet(_getQuestionValue(responses, 'swing_set'));
    _pdfController.updateBasketballGoal(_getQuestionValue(responses, 'basketball_goal'));
    _pdfController.updateDog(_getQuestionValue(responses, 'dog'));
    _pdfController.updateDogType(_getQuestionValue(responses, 'dog_type'));
    _pdfController.updateDogSign(_getQuestionValue(responses, 'dog_sign'));
    _pdfController.updateSkateboardOrBikeRamp(_getQuestionValue(responses, 'skateboard_or_bike_ramp'));
    _pdfController.updateTreeHouse(_getQuestionValue(responses, 'tree_house'));
    _pdfController.updateDebrisInYard(_getQuestionValue(responses, 'debris_in_yard'));
  }

  /// Download and set images from URLs
  Future<void> _downloadAndSetImages(Images images) async {
    try {
      // Download images from URLs and convert to Uint8List
      final downloadTasks = <Future<void>>[];
      
      // Primary risk photos
      if (images.primaryRisk.isNotEmpty) {
        downloadTasks.add(_downloadImagesForCategory('primary_risk', images.primaryRisk));
      }
      
      // Front elevation photos
      if (images.frontElevation.isNotEmpty) {
        downloadTasks.add(_downloadImagesForCategory('front_elevation', images.frontElevation));
      }
      
      // Right elevation photos
      if (images.rightElevation.isNotEmpty) {
        downloadTasks.add(_downloadImagesForCategory('right_elevation', images.rightElevation));
      }
      
      // Rear elevation photos
      if (images.rearElevation.isNotEmpty) {
        downloadTasks.add(_downloadImagesForCategory('rear_elevation', images.rearElevation));
      }
      
      // Roof photos
      if (images.roof.isNotEmpty) {
        downloadTasks.add(_downloadImagesForCategory('roof', images.roof));
      }
      
      // Additional photos
      if (images.additional.isNotEmpty) {
        downloadTasks.add(_downloadImagesForCategory('additional', images.additional));
      }
      
      // Wait for all downloads to complete
      await Future.wait(downloadTasks);
      
      print('[PDFGenerationService] All images downloaded and processed successfully');
    } catch (e) {
      print('[PDFGenerationService] Error downloading images: $e');
      rethrow;
    }
  }

  /// Download images for a specific category
  Future<void> _downloadImagesForCategory(String category, List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        if (url.isNotEmpty) {
          final imageBytes = await _downloadImageFromUrl(url);
          if (imageBytes != null) {
            _addImageToCategory(category, imageBytes);
          }
        }
      }
    } catch (e) {
      print('[PDFGenerationService] Error downloading images for category $category: $e');
      // Don't rethrow - continue with other categories
    }
  }

  /// Download an image from URL and return as Uint8List
  Future<Uint8List?> _downloadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('[PDFGenerationService] Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[PDFGenerationService] Error downloading image from $url: $e');
      return null;
    }
  }

  /// Helper method to get question value safely
  String _getQuestionValue(Map<String, Question> responses, String questionId) {
    final question = responses[questionId];
    if (question != null && question.value != null) {
      final value = question.value;
      // Handle Timestamp objects
      if (value is Timestamp) {
        final DateFormat formatter = DateFormat('MM-dd-yyyy HH:mm:ss');
        return formatter.format(value.toDate());
      }
      return value.toString();
    }
    return '';
  }

  /// Generate PDF from local report data (for testing/development)
  Future<String?> generatePdfFromLocalReport(String reportId) async {
    try {
      isGenerating.value = true;
      currentStatus.value = 'Loading local report...';
      progress.value = 0.1;

      // Try to find the report in local reports first
      final localReports = _reportsController.getUploadedReports();
      final report = localReports.firstWhereOrNull((r) => r.id == reportId);
      
      if (report == null) {
        throw Exception('Local report not found with ID: $reportId');
      }

      currentStatus.value = 'Converting local report to complete report format...';
      progress.value = 0.2;

      // Convert local report to CompleteReport format
      final completeReport = _convertLocalReportToCompleteReport(report);
      
      return await _generatePdfFromCompleteReport(completeReport);
    } catch (e) {
      print('[PDFGenerationService] Error generating PDF from local report: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF from local report: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    } finally {
      isGenerating.value = false;
      currentStatus.value = '';
      progress.value = 0.0;
    }
  }

  /// Convert local InspectionReportModel to CompleteReport
  CompleteReport _convertLocalReportToCompleteReport(dynamic localReport) {
    // This is a simplified conversion - adjust based on your actual data structure
    final Map<String, Question> questionResponses = {};
    
    // Convert questionnaire responses to Question objects
    if (localReport.questionnaireResponses is Map<String, dynamic>) {
      (localReport.questionnaireResponses as Map<String, dynamic>).forEach((key, value) {
        questionResponses[key] = Question(
          questionId: key,
          questionText: '', // You might want to maintain a mapping of question IDs to texts
          questionType: 'text', // Default type
          section: 'general', // Default section
          value: value,
        );
      });
    }

    // Convert image URLs to Images object
    final Images images = Images(
      additional: localReport.images['additional'] ?? <String>[],
      frontElevation: localReport.images['front_elevation'] ?? <String>[],
      primaryRisk: localReport.images['primary_risk'] ?? <String>[],
      rearElevation: localReport.images['rear_elevation'] ?? <String>[],
      rightElevation: localReport.images['right_elevation'] ?? <String>[],
      roof: localReport.images['roof'] ?? <String>[],
    );

    return CompleteReport(
      createdAt: localReport.createdAt.toIso8601String(),
      images: images,
      inspectorId: localReport.userId,
      questionnaireResponse: QuestionnaireResponse(responses: questionResponses),
      reportId: localReport.id,
      status: localReport.status.toString(),
      updatedAt: localReport.updatedAt.toIso8601String(),
      version: '1.0',
    );
  }

  /// Open generated PDF
  Future<void> openPdf(String pdfPath) async {
    try {
      if (pdfPath.isNotEmpty) {
        await _pdfController.openPDF();
      } else {
        Get.snackbar(
          'Error',
          'No PDF available to open',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('[PDFGenerationService] Error opening PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to open PDF: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Share generated PDF (kept for backward compatibility)
  Future<void> sharePdf(String pdfPath) async {
    try {
      if (pdfPath.isNotEmpty) {
        await _pdfController.sharePDF();
      } else {
        Get.snackbar(
          'Error',
          'No PDF available to share',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('[PDFGenerationService] Error sharing PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to share PDF: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Reset PDF controller state
  void resetPdfController() {
    _pdfController.resetForm();
  }

  /// Add image to PDF controller category
  void _addImageToCategory(String category, Uint8List bytes) {
    switch (category) {
      case 'primary_risk':
        _pdfController.primaryRiskPhotos.add(bytes);
        break;
      case 'front_elevation':
        _pdfController.frontElevationPhotos.add(bytes);
        break;
      case 'right_elevation':
        _pdfController.rightElevationPhotos.add(bytes);
        break;
      case 'rear_elevation':
        _pdfController.rearElevationPhotos.add(bytes);
        break;
      case 'roof':
        _pdfController.roofPhotos.add(bytes);
        break;
      case 'additional':
        _pdfController.additionalPhotos.add(bytes);
        break;
      default:
        print('[PDFGenerationService] Unknown image category: $category');
    }
  }

  /// Get generation status
  bool get isGeneratingPdf => isGenerating.value;
  String get generationStatus => currentStatus.value;
  double get generationProgress => progress.value;
}
