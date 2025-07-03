import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
  
  @override
  void onInit() {
    super.onInit();
    _checkValidation();
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
            final File imageFile = File(image.path);
            _addPhotoToCategory(imageFile, photoType);
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
          final File imageFile = File(image.path);
          _addPhotoToCategory(imageFile, photoType);
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
    switch (photoType) {
      case 'primary_risk':
        if (index < primaryRiskPhotos.length) {
          primaryRiskPhotos.removeAt(index);
        }
        break;
      case 'front_elevation':
        if (index < frontElevationPhotos.length) {
          frontElevationPhotos.removeAt(index);
        }
        break;
      case 'right_elevation':
        if (index < rightElevationPhotos.length) {
          rightElevationPhotos.removeAt(index);
        }
        break;
      case 'rear_elevation':
        if (index < rearElevationPhotos.length) {
          rearElevationPhotos.removeAt(index);
        }
        break;
      case 'roof':
        if (index < roofPhotos.length) {
          roofPhotos.removeAt(index);
        }
        break;
      case 'additional':
        if (index < additionalPhotos.length) {
          additionalPhotos.removeAt(index);
        }
        break;
    }
    _checkValidation();
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
}