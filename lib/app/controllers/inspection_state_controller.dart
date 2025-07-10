import 'package:get/get.dart';
import 'dart:async';

/// Unified state controller for managing inspection workflow state
/// Provides consistent state management across all inspection-related controllers
class InspectionStateController extends GetxController {
  // Workflow state
  final RxBool isInspectionActive = false.obs;
  final RxString currentInspectionId = ''.obs;
  final RxString currentWorkflowStep = ''.obs; // photos, questionnaire, finalize
  
  // Sync and save states
  final RxBool isAutoSaving = false.obs;
  final RxBool isManualSaving = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool hasUnsavedChanges = false.obs;
  
  // Progress tracking
  final RxInt totalSteps = 3.obs; // photos, questionnaire, finalize
  final RxInt currentStep = 1.obs;
  
  // Debounce timers
  Timer? _autoSaveDebounce;
  Timer? _stateChangeDebounce;
  
  /// Start a new inspection workflow
  void startInspectionWorkflow(String inspectionId) {
    currentInspectionId.value = inspectionId;
    isInspectionActive.value = true;
    currentWorkflowStep.value = 'photos';
    currentStep.value = 1;
    hasUnsavedChanges.value = false;
    print('[InspectionState] Started inspection workflow: $inspectionId');
  }
  
  /// Update workflow step
  void updateWorkflowStep(String step) {
    currentWorkflowStep.value = step;
    
    // Update step number
    switch (step) {
      case 'photos':
        currentStep.value = 1;
        break;
      case 'questionnaire':
        currentStep.value = 2;
        break;
      case 'finalize':
        currentStep.value = 3;
        break;
    }
    
    print('[InspectionState] Updated workflow step: $step (${currentStep.value}/${totalSteps.value})');
  }
  
  /// Mark changes as unsaved
  void markAsUnsaved() {
    if (!hasUnsavedChanges.value) {
      hasUnsavedChanges.value = true;
      print('[InspectionState] Marked as having unsaved changes');
    }
  }
  
  /// Mark changes as saved
  void markAsSaved() {
    if (hasUnsavedChanges.value) {
      hasUnsavedChanges.value = false;
      print('[InspectionState] Marked as saved');
    }
  }
  
  /// Set auto-saving state
  void setAutoSaving(bool saving) {
    isAutoSaving.value = saving;
  }
  
  /// Set manual saving state
  void setManualSaving(bool saving) {
    isManualSaving.value = saving;
  }
  
  /// Set syncing state
  void setSyncing(bool syncing) {
    isSyncing.value = syncing;
  }
  
  /// Complete inspection workflow
  void completeInspectionWorkflow() {
    isInspectionActive.value = false;
    currentInspectionId.value = '';
    currentWorkflowStep.value = '';
    currentStep.value = 1;
    hasUnsavedChanges.value = false;
    print('[InspectionState] Completed inspection workflow');
  }
  
  /// Get workflow progress percentage
  double get progressPercentage {
    return currentStep.value / totalSteps.value;
  }
  
  /// Check if currently saving (auto or manual)
  bool get isSaving => isAutoSaving.value || isManualSaving.value;
  
  /// Get current workflow status for UI display
  String get workflowStatus {
    if (isSyncing.value) return 'Syncing...';
    if (isManualSaving.value) return 'Saving...';
    if (isAutoSaving.value) return 'Auto Saving...';
    if (hasUnsavedChanges.value) return 'Unsaved Changes';
    return 'Saved';
  }
  
  @override
  void onClose() {
    _autoSaveDebounce?.cancel();
    _stateChangeDebounce?.cancel();
    super.onClose();
  }
}
