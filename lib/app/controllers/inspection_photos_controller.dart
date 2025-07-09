import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'inspection_reports_controller.dart';

class InspectionPhotosController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  
  // Photo lists for each category
  final RxList<File> primaryRiskPhotos = <File>[].obs;
  final RxList<File> frontElevationPhotos = <File>[].obs;
  final RxList<File> rightElevationPhotos = <File>[].obs;
  final RxList<File> rearElevationPhotos = <File>[].obs;
  final RxList<File> roofPhotos = <File>[].obs;
  final RxList<File> additionalPhotos = <File>[].obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  
  // Error states
  final RxBool hasPrimaryRiskError = false.obs;
  final RxString primaryRiskErrorMessage = ''.obs;

  final RxBool viewOnly = false.obs;

  // Directory for storing persistent images
  Directory? _persistentDir;

  bool isLoadingFromModel = false;

  void setViewOnly(bool value) {
    viewOnly.value = value;
  }
  
  @override
  void onInit() async {
    super.onInit();
    await _initializePersistentDirectory();
    _checkValidation();
    _setupAutoSave();
  }

  Future<void> _initializePersistentDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _persistentDir = Directory(path.join(appDir.path, 'inspection_photos'));
      if (!await _persistentDir!.exists()) {
        await _persistentDir!.create(recursive: true);
      }
      print('[Photos] Persistent directory initialized: ${_persistentDir!.path}');
    } catch (e) {
      print('[Photos] Error initializing persistent directory: $e');
    }
  }

  void _setupAutoSave() {
    // Auto-save on photo list changes
    ever(primaryRiskPhotos, (_) { if (!isLoadingFromModel) _saveReportProgress('primaryRiskPhotos'); });
    ever(frontElevationPhotos, (_) { if (!isLoadingFromModel) _saveReportProgress('frontElevationPhotos'); });
    ever(rightElevationPhotos, (_) { if (!isLoadingFromModel) _saveReportProgress('rightElevationPhotos'); });
    ever(rearElevationPhotos, (_) { if (!isLoadingFromModel) _saveReportProgress('rearElevationPhotos'); });
    ever(roofPhotos, (_) { if (!isLoadingFromModel) _saveReportProgress('roofPhotos'); });
    ever(additionalPhotos, (_) { if (!isLoadingFromModel) _saveReportProgress('additionalPhotos'); });
  }

  void _saveReportProgress(String category) {
    print('[Auto-Save] $category changed, saving report progress...');
    try {
      Get.find<InspectionReportsController>().saveCurrentReportProgress();
    } catch (e) {
      print('[Auto-Save] Error saving report progress from $category: $e');
    }
  }
  
  // Check validation for required fields
  void _checkValidation() {
    if (primaryRiskPhotos.isEmpty) {
      hasPrimaryRiskError.value = true;
      primaryRiskErrorMessage.value = 'Primary Risk Photo is required.';
    } else {
      hasPrimaryRiskError.value = false;
      primaryRiskErrorMessage.value = '';
    }
  }
  
  // Generic method to show photo source dialog
  Future<void> showPhotoSourceDialog(String photoType) async {
    Get.dialog(
      AlertDialog(
        title: Text('Select Photo Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera, photoType);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery, photoType);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source, String photoType) async {
    try {
      isLoading.value = true;
      
      // Request permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          Get.snackbar('Permission Denied', 'Camera permission is required to take photos');
          return;
        }
      }
      
      if (source == ImageSource.gallery) {
        // Allow multiple selection for gallery
        final List<XFile>? images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (images != null && images.isNotEmpty) {
          for (final image in images) {
            await _processAndAddImage(image, photoType);
          }
          _checkValidation();
          Get.snackbar('Success', 'Photo(s) added successfully', 
                      snackPosition: SnackPosition.TOP);
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          await _processAndAddImage(image, photoType);
          _checkValidation();
          Get.snackbar('Success', 'Photo added successfully', 
                      snackPosition: SnackPosition.TOP);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e', 
                  snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }

  // Process and add image to persistent storage
  Future<void> _processAndAddImage(XFile pickedImage, String photoType) async {
    try {
      if (_persistentDir == null) {
        await _initializePersistentDirectory();
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(pickedImage.path);
      final filename = '${photoType}_${timestamp}${extension}';
      final persistentPath = path.join(_persistentDir!.path, filename);

      // Copy image to persistent storage
      final originalFile = File(pickedImage.path);
      final persistentFile = await originalFile.copy(persistentPath);

      print('[Photos] Image saved to persistent storage: $persistentPath');
      
      // Add to appropriate category
      _addPhotoToCategory(persistentFile, photoType);
      
    } catch (e) {
      print('[Photos] Error processing image: $e');
      Get.snackbar('Error', 'Failed to save image: $e');
    }
  }
  
  // Add photo to specific category
  void _addPhotoToCategory(File photo, String photoType) {
    switch (photoType) {
      case 'primary_risk':
        if (primaryRiskPhotos.length < 1) {
          primaryRiskPhotos.add(photo);
        } else {
          Get.snackbar('Limit Reached', 'Only 1 primary risk photo allowed');
        }
        break;
      case 'front_elevation':
        frontElevationPhotos.add(photo);
        break;
      case 'right_elevation':
        rightElevationPhotos.add(photo);
        break;
      case 'rear_elevation':
        rearElevationPhotos.add(photo);
        break;
      case 'roof':
        roofPhotos.add(photo);
        break;
      case 'additional':
        additionalPhotos.add(photo);
        break;
    }
  }
  
  // Remove photo from specific category
  void removePhoto(String photoType, int index) {
    File? fileToDelete;
    
    switch (photoType) {
      case 'primary_risk':
        if (index < primaryRiskPhotos.length) {
          fileToDelete = primaryRiskPhotos[index];
          primaryRiskPhotos.removeAt(index);
        }
        break;
      case 'front_elevation':
        if (index < frontElevationPhotos.length) {
          fileToDelete = frontElevationPhotos[index];
          frontElevationPhotos.removeAt(index);
        }
        break;
      case 'right_elevation':
        if (index < rightElevationPhotos.length) {
          fileToDelete = rightElevationPhotos[index];
          rightElevationPhotos.removeAt(index);
        }
        break;
      case 'rear_elevation':
        if (index < rearElevationPhotos.length) {
          fileToDelete = rearElevationPhotos[index];
          rearElevationPhotos.removeAt(index);
        }
        break;
      case 'roof':
        if (index < roofPhotos.length) {
          fileToDelete = roofPhotos[index];
          roofPhotos.removeAt(index);
        }
        break;
      case 'additional':
        if (index < additionalPhotos.length) {
          fileToDelete = additionalPhotos[index];
          additionalPhotos.removeAt(index);
        }
        break;
    }
    
    // Delete the physical file
    if (fileToDelete != null) {
      _deletePhysicalFile(fileToDelete);
    }
    
    _checkValidation();
  }

  // Delete physical file from storage
  Future<void> _deletePhysicalFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        print('[Photos] Deleted physical file: ${file.path}');
      }
    } catch (e) {
      print('[Photos] Error deleting physical file: $e');
    }
  }
  
  // Get photos for specific category
  List<File> getPhotosForCategory(String photoType) {
    switch (photoType) {
      case 'primary_risk':
        return primaryRiskPhotos;
      case 'front_elevation':
        return frontElevationPhotos;
      case 'right_elevation':
        return rightElevationPhotos;
      case 'rear_elevation':
        return rearElevationPhotos;
      case 'roof':
        return roofPhotos;
      case 'additional':
        return additionalPhotos;
      default:
        return [];
    }
  }
  
  // Get photo count text for specific category
  String getPhotoCountText(String photoType) {
    List<File> photos = getPhotosForCategory(photoType);
    switch (photoType) {
      case 'primary_risk':
        return '${photos.length} / 1 photo';
      default:
        return '${photos.length} photo(s)';
    }
  }
  
  // Check if category can add more photos
  bool canAddMorePhotos(String photoType) {
    List<File> photos = getPhotosForCategory(photoType);
    switch (photoType) {
      case 'primary_risk':
        return photos.length < 1;
      default:
        return true;
    }
  }
  
  // Validate all required fields
  bool validateForm() {
    _checkValidation();
    return !hasPrimaryRiskError.value;
  }
  
  // Get total photo count
  int get totalPhotoCount =>
      primaryRiskPhotos.length +
      frontElevationPhotos.length +
      rightElevationPhotos.length +
      rearElevationPhotos.length +
      roofPhotos.length +
      additionalPhotos.length;
  
  // Clear all photo data and errors (does NOT delete files)
  void clearData() {
    primaryRiskPhotos.clear();
    frontElevationPhotos.clear();
    rightElevationPhotos.clear();
    rearElevationPhotos.clear();
    roofPhotos.clear();
    additionalPhotos.clear();
    isLoading.value = false;
    hasPrimaryRiskError.value = false;
    primaryRiskErrorMessage.value = '';
  }

  // Delete all physical files
  Future<void> _deleteAllPhysicalFiles() async {
    final allPhotos = [
      ...primaryRiskPhotos,
      ...frontElevationPhotos,
      ...rightElevationPhotos,
      ...rearElevationPhotos,
      ...roofPhotos,
      ...additionalPhotos,
    ];
    
    for (final photo in allPhotos) {
      await _deletePhysicalFile(photo);
    }
  }

  // Export all photos as a map of category to file paths
  Map<String, List<String>> getAllPhotosAsMap() {
    final map = {
      'primary_risk': primaryRiskPhotos.map((f) => f.path).toList(),
      'front_elevation': frontElevationPhotos.map((f) => f.path).toList(),
      'right_elevation': rightElevationPhotos.map((f) => f.path).toList(),
      'rear_elevation': rearElevationPhotos.map((f) => f.path).toList(),
      'roof': roofPhotos.map((f) => f.path).toList(),
      'additional': additionalPhotos.map((f) => f.path).toList(),
    };
    print('[DEBUG] getAllPhotosAsMap returning: ' + map.toString());
    if (map.values.every((l) => l.isEmpty)) print('[WARNING] getAllPhotosAsMap: all photo lists are empty!');
    return map;
  }

  // Load photos from a map of category to file paths
  Future<void> loadPhotosFromMap(Map<String, List<String>> map) async {
    isLoadingFromModel = true;
    print('[Photos] Loading photos from map: $map');
    if (map.values.every((l) => l.isEmpty)) print('[WARNING] loadPhotosFromMap: all photo lists are empty!');
    // Clear existing photos first
    primaryRiskPhotos.clear();
    frontElevationPhotos.clear();
    rightElevationPhotos.clear();
    rearElevationPhotos.clear();
    roofPhotos.clear();
    additionalPhotos.clear();
    // Load photos for each category
    await _loadCategoryPhotos('primary_risk', map['primary_risk'] ?? [], primaryRiskPhotos);
    await _loadCategoryPhotos('front_elevation', map['front_elevation'] ?? [], frontElevationPhotos);
    await _loadCategoryPhotos('right_elevation', map['right_elevation'] ?? [], rightElevationPhotos);
    await _loadCategoryPhotos('rear_elevation', map['rear_elevation'] ?? [], rearElevationPhotos);
    await _loadCategoryPhotos('roof', map['roof'] ?? [], roofPhotos);
    await _loadCategoryPhotos('additional', map['additional'] ?? [], additionalPhotos);
    _checkValidation();
    isLoadingFromModel = false;
    print('[Photos] Photos loaded successfully. Total: $totalPhotoCount');
    print('[DEBUG] After loadPhotosFromMap, getAllPhotosAsMap: ' + getAllPhotosAsMap().toString());
  }

  // Load photos for a specific category
  Future<void> _loadCategoryPhotos(String category, List<String> paths, RxList<File> targetList) async {
    for (final filePath in paths) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          targetList.add(file);
          print('[Photos] Loaded $category photo: $filePath');
        } else {
          print('[Photos] File not found for $category: $filePath');
        }
      } catch (e) {
        print('[Photos] Error loading $category photo from $filePath: $e');
      }
    }
  }

  // Clean up orphaned files (files not referenced in any active report)
  Future<void> cleanupOrphanedFiles() async {
    if (_persistentDir == null) return;
    
    try {
      final allFiles = await _persistentDir!.list().toList();
      final referencedPaths = getAllPhotosAsMap().values.expand((list) => list).toSet();
      
      for (final entity in allFiles) {
        if (entity is File && !referencedPaths.contains(entity.path)) {
          await entity.delete();
          print('[Photos] Deleted orphaned file: ${entity.path}');
        }
      }
    } catch (e) {
      print('[Photos] Error cleaning up orphaned files: $e');
    }
  }

  @override
  void onClose() {
    // Optional: Clean up on controller disposal
    super.onClose();
  }
}