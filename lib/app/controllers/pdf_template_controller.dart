  import 'dart:io';
  import 'dart:typed_data';
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:safe_harbor_field_app/app/utils/pdf_template_optimized.dart';
  import 'package:share_plus/share_plus.dart';
  import 'package:open_file/open_file.dart';

  class InspectionPDFController extends GetxController {
    final RxBool isGenerating = false.obs;
    final RxString pdfPath = ''.obs;

    // Property Information
    final RxString clientName = ''.obs;
    final RxString address = ''.obs;
    final RxString state = ''.obs;
    final RxString zipCode = ''.obs;
    final RxString policyNumber = ''.obs;
    final RxString dateOfOrigin = ''.obs;
    final RxString typeOfInspection = ''.obs;
    final RxString inspectorName = ''.obs;
    final RxString inspectionDate = ''.obs;
    final RxString reportDate = ''.obs;
    final RxString summary = ''.obs;

    // Images - Multiple photos per category
    final Rx<Uint8List?> logoImage = Rx<Uint8List?>(null);
    final Rx<Uint8List?> coverPhoto = Rx<Uint8List?>(null);
    final RxList<Uint8List> primaryRiskPhotos = <Uint8List>[].obs;
    final RxList<Uint8List> frontElevationPhotos = <Uint8List>[].obs;
    final RxList<Uint8List> rightElevationPhotos = <Uint8List>[].obs;
    final RxList<Uint8List> rearElevationPhotos = <Uint8List>[].obs;
    final RxList<Uint8List> roofPhotos = <Uint8List>[].obs;
    final RxList<Uint8List> additionalPhotos = <Uint8List>[].obs;

    // Overall Risk Information
    final RxString neighborhood = ''.obs;
    final RxString areaEconomy = ''.obs;
    final RxString gatedCommunity = ''.obs;
    final RxString propertyVacant = ''.obs;
    final RxString nearestBodyOfWater = ''.obs;
    final RxString rentalProperty = ''.obs;
    final RxString businessOnSite = ''.obs;
    final RxString seasonalHome = ''.obs;
    final RxString historicProperty = ''.obs;
    final RxString nearestDwelling = ''.obs;

    // Overall Elevation Condition
    final RxString dwellingType = ''.obs;
    final RxString yearBuilt = ''.obs;
    final RxString typeOfFoundation = ''.obs;
    final RxString primaryConstruction = ''.obs;
    final RxString numberOfStories = ''.obs;
    final RxString livingArea = ''.obs;
    final RxString lotSize = ''.obs;
    final RxString siding = ''.obs;
    final RxString hvac = ''.obs;
    final RxString numberOfSystems = ''.obs;
    final RxString hvacSerial = ''.obs;
    final RxString guttersAndDownspout = ''.obs;
    final RxString fuelTank = ''.obs;
    final RxString sidingDamage = ''.obs;
    final RxString peelingPaint = ''.obs;
    final RxString mildewMoss = ''.obs;
    final RxString windowDamage = ''.obs;
    final RxString foundationCracks = ''.obs;
    final RxString wallCracks = ''.obs;
    final RxString chimneyDamage = ''.obs;
    final RxString waterDamage = ''.obs;
    final RxString underRenovation = ''.obs;
    final RxString mainBreakerPanel = ''.obs;
    final RxString waterSpicketDamage = ''.obs;
    final RxString doorDamage = ''.obs;

    // Overall Roof Condition
    final RxString roofMaterial = ''.obs;
    final RxString roofCovering = ''.obs;
    final RxString ageOfRoof = ''.obs;
    final RxString shapeOfRoof = ''.obs;
    final RxString treeLimbsOnRoof = ''.obs;
    final RxString debrisOnRoof = ''.obs;
    final RxString solarPanel = ''.obs;
    final RxString exposedFelt = ''.obs;
    final RxString missingShinglesTile = ''.obs;
    final RxString priorRepairs = ''.obs;
    final RxString curlingShingles = ''.obs;
    final RxString algaeMoss = ''.obs;
    final RxString tarpOnRoof = ''.obs;
    final RxString brokenOrCrackTiles = ''.obs;
    final RxString satelliteDish = ''.obs;
    final RxString unevenDecking = ''.obs;

    // Garage/Outbuilding Overall Condition
    final RxString garageType = ''.obs;
    final RxString outbuilding = ''.obs;
    final RxString outbuildingType = ''.obs;
    final RxString fence = ''.obs;
    final RxString garageCondition = ''.obs;
    final RxString carportOrAwning = ''.obs;
    final RxString carportConstruction = ''.obs;
    final RxString fenceCondition = ''.obs;

    // Dwelling Hazards
    final RxString boardedDoorsWindows = ''.obs;
    final RxString overgrownVegetation = ''.obs;
    final RxString abandonedVehicles = ''.obs;
    final RxString missingDamageSteps = ''.obs;
    final RxString missingDamageRailing = ''.obs;
    final RxString dwellingSidingDamage = ''.obs;
    final RxString hurricaneShutters = ''.obs;
    final RxString treeBranch = ''.obs;
    final RxString chimneyThroughRoof = ''.obs;
    final RxString fireplacePitOutside = ''.obs;
    final RxString securityBars = ''.obs;
    final RxString faciaSoffitDamage = ''.obs;

    // Possible Hazards
    final RxString swimmingPool = ''.obs;
    final RxString divingBoardOrSlide = ''.obs;
    final RxString poolFenced = ''.obs;
    final RxString trampoline = ''.obs;
    final RxString swingSet = ''.obs;
    final RxString basketballGoal = ''.obs;
    final RxString dog = ''.obs;
    final RxString dogType = ''.obs;
    final RxString dogSign = ''.obs;
    final RxString skateboardOrBikeRamp = ''.obs;
    final RxString treeHouse = ''.obs;
    final RxString debrisInYard = ''.obs;

    @override
    void onInit() {
      super.onInit();
      // reportDate and inspectionDate should be set from input, not initialized here.
    }

    // Property Information Methods
    void updateClientName(String name) => clientName.value = name;
    void updateAddress(String addr) => address.value = addr;
    void updateState(String st) => state.value = st;
    void updateZipCode(String zip) => zipCode.value = zip;
    void updatePolicyNumber(String policy) => policyNumber.value = policy;
    void updateDateOfOrigin(String date) => dateOfOrigin.value = date;
    void updateTypeOfInspection(String type) => typeOfInspection.value = type;
    void updateInspectorName(String name) => inspectorName.value = name;
    void updateInspectionDate(String date) => inspectionDate.value = date;
    void updateReportDate(String date) => reportDate.value = date;
    void updateSummary(String summaryText) => summary.value = summaryText;

    // Overall Risk Information Methods
    void updateNeighborhood(String value) => neighborhood.value = value;
    void updateAreaEconomy(String value) => areaEconomy.value = value;
    void updateGatedCommunity(String value) => gatedCommunity.value = value;
    void updatePropertyVacant(String value) => propertyVacant.value = value;
    void updateNearestBodyOfWater(String value) => nearestBodyOfWater.value = value;
    void updateRentalProperty(String value) => rentalProperty.value = value;
    void updateBusinessOnSite(String value) => businessOnSite.value = value;
    void updateSeasonalHome(String value) => seasonalHome.value = value;
    void updateHistoricProperty(String value) => historicProperty.value = value;
    void updateNearestDwelling(String value) => nearestDwelling.value = value;

    // Overall Elevation Condition Methods
    void updateDwellingType(String value) => dwellingType.value = value;
    void updateYearBuilt(String value) => yearBuilt.value = value;
    void updateTypeOfFoundation(String value) => typeOfFoundation.value = value;
    void updatePrimaryConstruction(String value) => primaryConstruction.value = value;
    void updateNumberOfStories(String value) => numberOfStories.value = value;
    void updateLivingArea(String value) => livingArea.value = value;
    void updateLotSize(String value) => lotSize.value = value;
    void updateSiding(String value) => siding.value = value;
    void updateHvac(String value) => hvac.value = value;
    void updateNumberOfSystems(String value) => numberOfSystems.value = value;
    void updateHvacSerial(String value) => hvacSerial.value = value;
    void updateGuttersAndDownspout(String value) => guttersAndDownspout.value = value;
    void updateFuelTank(String value) => fuelTank.value = value;
    void updateSidingDamage(String value) => sidingDamage.value = value;
    void updatePeelingPaint(String value) => peelingPaint.value = value;
    void updateMildewMoss(String value) => mildewMoss.value = value;
    void updateWindowDamage(String value) => windowDamage.value = value;
    void updateFoundationCracks(String value) => foundationCracks.value = value;
    void updateWallCracks(String value) => wallCracks.value = value;
    void updateChimneyDamage(String value) => chimneyDamage.value = value;
    void updateWaterDamage(String value) => waterDamage.value = value;
    void updateUnderRenovation(String value) => underRenovation.value = value;
    void updateMainBreakerPanel(String value) => mainBreakerPanel.value = value;
    void updateWaterSpicketDamage(String value) => waterSpicketDamage.value = value;
    void updateDoorDamage(String value) => doorDamage.value = value;

    // Overall Roof Condition Methods
    void updateRoofMaterial(String value) => roofMaterial.value = value;
    void updateRoofCovering(String value) => roofCovering.value = value;
    void updateAgeOfRoof(String value) => ageOfRoof.value = value;
    void updateShapeOfRoof(String value) => shapeOfRoof.value = value;
    void updateTreeLimbsOnRoof(String value) => treeLimbsOnRoof.value = value;
    void updateDebrisOnRoof(String value) => debrisOnRoof.value = value;
    void updateSolarPanel(String value) => solarPanel.value = value;
    void updateExposedFelt(String value) => exposedFelt.value = value;
    void updateMissingShinglesTile(String value) => missingShinglesTile.value = value;
    void updatePriorRepairs(String value) => priorRepairs.value = value;
    void updateCurlingShingles(String value) => curlingShingles.value = value;
    void updateAlgaeMoss(String value) => algaeMoss.value = value;
    void updateTarpOnRoof(String value) => tarpOnRoof.value = value;
    void updateBrokenOrCrackTiles(String value) => brokenOrCrackTiles.value = value;
    void updateSatelliteDish(String value) => satelliteDish.value = value;
    void updateUnevenDecking(String value) => unevenDecking.value = value;

    // Garage/Outbuilding Methods
    void updateGarageType(String value) => garageType.value = value;
    void updateOutbuilding(String value) => outbuilding.value = value;
    void updateOutbuildingType(String value) => outbuildingType.value = value;
    void updateFence(String value) => fence.value = value;
    void updateGarageCondition(String value) => garageCondition.value = value;
    void updateCarportOrAwning(String value) => carportOrAwning.value = value;
    void updateCarportConstruction(String value) => carportConstruction.value = value;
    void updateFenceCondition(String value) => fenceCondition.value = value;

    // Dwelling Hazards Methods
    void updateBoardedDoorsWindows(String value) => boardedDoorsWindows.value = value;
    void updateOvergrownVegetation(String value) => overgrownVegetation.value = value;
    void updateAbandonedVehicles(String value) => abandonedVehicles.value = value;
    void updateMissingDamageSteps(String value) => missingDamageSteps.value = value;
    void updateMissingDamageRailing(String value) => missingDamageRailing.value = value;
    void updateDwellingSidingDamage(String value) => dwellingSidingDamage.value = value;
    void updateHurricaneShutters(String value) => hurricaneShutters.value = value;
    void updateTreeBranch(String value) => treeBranch.value = value;
    void updateChimneyThroughRoof(String value) => chimneyThroughRoof.value = value;
    void updateFireplacePitOutside(String value) => fireplacePitOutside.value = value;
    void updateSecurityBars(String value) => securityBars.value = value;
    void updateFaciaSoffitDamage(String value) => faciaSoffitDamage.value = value;

    // Possible Hazards Methods
    void updateSwimmingPool(String value) => swimmingPool.value = value;
    void updateDivingBoardOrSlide(String value) => divingBoardOrSlide.value = value;
    void updatePoolFenced(String value) => poolFenced.value = value;
    void updateTrampoline(String value) => trampoline.value = value;
    void updateSwingSet(String value) => swingSet.value = value;
    void updateBasketballGoal(String value) => basketballGoal.value = value;
    void updateDog(String value) => dog.value = value;
    void updateDogType(String value) => dogType.value = value;
    void updateDogSign(String value) => dogSign.value = value;
    void updateSkateboardOrBikeRamp(String value) => skateboardOrBikeRamp.value = value;
    void updateTreeHouse(String value) => treeHouse.value = value;
    void updateDebrisInYard(String value) => debrisInYard.value = value;

    // Image Management Methods
    final ImagePicker _picker = ImagePicker();

    Future<void> pickImage(String category) async {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        
        if (image != null) {
          final bytes = await image.readAsBytes();
          _addImageToCategory(category, bytes);
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
      }
    }

    Future<void> pickMultipleImages(String category) async {
      try {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
        );
        
        for (var image in images) {
          final bytes = await image.readAsBytes();
          _addImageToCategory(category, bytes);
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to pick images: ${e.toString()}');
      }
    }

    void _addImageToCategory(String category, Uint8List bytes) {
      switch (category) {
        case 'logo':
          logoImage.value = bytes;
          break;
        case 'cover':
          coverPhoto.value = bytes;
          break;
        case 'primary_risk':
          primaryRiskPhotos.add(bytes);
          break;
        case 'front_elevation':
          frontElevationPhotos.add(bytes);
          break;
        case 'right_elevation':
          rightElevationPhotos.add(bytes);
          break;
        case 'rear_elevation':
          rearElevationPhotos.add(bytes);
          break;
        case 'roof':
          roofPhotos.add(bytes);
          break;
        case 'additional':
          additionalPhotos.add(bytes);
          break;
      }
    }

    void removeImage(String category, int index) {
      switch (category) {
        case 'logo':
          logoImage.value = null;
          break;
        case 'cover':
          coverPhoto.value = null;
          break;
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
    }

    // PDF Generation Method
    Future<void> generatePDF() async {
      try {
        print('📝 [PDF] Starting PDF generation...');
        isGenerating.value = true;

        // Create model objects
        final overallRiskInfo = OverallRiskInfo(
          neighborhood: neighborhood.value,
          areaEconomy: areaEconomy.value,
          gatedCommunity: gatedCommunity.value == 'Yes',
          propertyVacant: propertyVacant.value == 'Yes',
          nearestBodyOfWater: nearestBodyOfWater.value,
          rentalProperty: rentalProperty.value == 'Yes',
          businessOnSite: businessOnSite.value == 'Yes',
          seasonalHome: seasonalHome.value == 'Yes',
          historicProperty: historicProperty.value == 'Yes',
          nearestDwelling: int.tryParse(nearestDwelling.value) ?? 0,
        );

        final elevationCondition = ElevationCondition(
          dwellingType: dwellingType.value,
          yearBuilt: int.tryParse(yearBuilt.value) ?? 0,
          foundationType: typeOfFoundation.value,
          primaryConstruction: primaryConstruction.value,
          numberOfStories: int.tryParse(numberOfStories.value) ?? 0,
          livingArea: int.tryParse(livingArea.value) ?? 0,
          lotSize: lotSize.value,
          siding: siding.value,
          hvac: hvac.value,
          numberOfSystems: int.tryParse(numberOfSystems.value) ?? 0,
          hvacSerial: hvacSerial.value,
          guttersAndDownspout: guttersAndDownspout.value == 'Yes',
          fuelTank: fuelTank.value == 'Yes',
          sidingDamage: sidingDamage.value == 'Yes',
          peelingPaint: peelingPaint.value == 'Yes',
          mildewMoss: mildewMoss.value == 'Yes',
          windowDamage: windowDamage.value == 'Yes',
          foundationCracks: foundationCracks.value == 'Yes',
          wallCracks: wallCracks.value == 'Yes',
          chimneyDamage: chimneyDamage.value,
          waterDamage: waterDamage.value == 'Yes',
          underRenovation: underRenovation.value == 'Yes',
          mainBreakerPanel: mainBreakerPanel.value == 'Yes',
          waterSpicketDamage: waterSpicketDamage.value == 'Yes',
          doorDamage: doorDamage.value == 'Yes',
        );

        final roofCondition = RoofCondition(
          roofMaterial: roofMaterial.value,
          roofCovering: roofCovering.value,
          ageOfRoof: ageOfRoof.value,
          shapeOfRoof: shapeOfRoof.value,
          treeLimbsOnRoof: treeLimbsOnRoof.value == 'Yes',
          debrisOnRoof: debrisOnRoof.value == 'Yes',
          solarPanel: solarPanel.value == 'Yes',
          exposedFelt: exposedFelt.value == 'Yes',
          missingShingles: missingShinglesTile.value == 'Yes',
          priorRepairs: priorRepairs.value == 'Yes',
          curlingShingles: curlingShingles.value == 'Yes',
          algaeMoss: algaeMoss.value == 'Yes',
          tarpOnRoof: tarpOnRoof.value == 'Yes',
          brokenCrackTiles: brokenOrCrackTiles.value,
          satelliteDish: satelliteDish.value == 'Yes',
          unevenDecking: unevenDecking.value == 'Yes',
        );

        final garageConditionModel = GarageCondition(
          garageType: garageType.value,
          outbuilding: outbuilding.value == 'Yes',
          outbuildingType: outbuildingType.value,
          fence: fence.value,
          garageCondition: garageCondition.value,
          carportOrAwning: carportOrAwning.value == 'Yes',
          carportConstruction: carportConstruction.value,
          fenceCondition: fenceCondition.value,
        );

        final dwellingHazards = DwellingHazards(
          boardedDoorsWindows: boardedDoorsWindows.value == 'Yes',
          overgrownVegetation: overgrownVegetation.value == 'Yes',
          abandonedVehicles: abandonedVehicles.value == 'Yes',
          missingSteps: missingDamageSteps.value == 'Yes',
          missingRailing: missingDamageRailing.value == 'Yes',
          sidingDamage: dwellingSidingDamage.value == 'Yes',
          hurricaneShutters: hurricaneShutters.value == 'Yes',
          treeBranch: treeBranch.value == 'Yes',
          chimneyThroughRoof: chimneyThroughRoof.value == 'Yes',
          fireplacePit: fireplacePitOutside.value == 'Yes',
          securityBars: securityBars.value == 'Yes',
          faciaSoffitDamage: faciaSoffitDamage.value == 'Yes',
        );

        final possibleHazards = PossibleHazards(
          swimmingPool: swimmingPool.value == 'Yes',
          divingBoard: divingBoardOrSlide.value == 'Yes',
          poolFenced: poolFenced.value == 'Yes',
          trampoline: trampoline.value == 'Yes',
          swingSet: swingSet.value == 'Yes',
          basketballGoal: basketballGoal.value == 'Yes',
          dog: dog.value == 'Yes',
          dogType: dogType.value,
          dogSign: dogSign.value == 'Yes',
          skateboardRamp: skateboardOrBikeRamp.value == 'Yes',
          treeHouse: treeHouse.value == 'Yes',
          debrisInYard: debrisInYard.value == 'Yes',
        );

        print('🖨️ [PDF] Generating PDF bytes...');
        final pdfBytes = await OptimizedInspectionPDFTemplate.generateInspectionReport(
          clientName: clientName.value,
          address: address.value,
          state: state.value,
          zipCode: zipCode.value,
          policyNumber: policyNumber.value,
          dateOfOrigin: dateOfOrigin.value,
          typeOfInspection: typeOfInspection.value,
          inspectorName: inspectorName.value,
          inspectionDate: inspectionDate.value,
          reportDate: reportDate.value,
          logoImage: logoImage.value,
          coverPhoto: coverPhoto.value,
          primaryRiskPhotos: primaryRiskPhotos.toList(),
          frontElevationPhotos: frontElevationPhotos.toList(),
          rightElevationPhotos: rightElevationPhotos.toList(),
          rearElevationPhotos: rearElevationPhotos.toList(),
          roofPhotos: roofPhotos.toList(),
          additionalPhotos: additionalPhotos.toList(),
          overallRiskInfo: overallRiskInfo,
          elevationCondition: elevationCondition,
          roofCondition: roofCondition,
          garageCondition: garageConditionModel,
          dwellingHazards: dwellingHazards,
          possibleHazards: possibleHazards,
          summary: summary.value,
        );

        print('📁 [PDF] Determining save location...');
        Directory? saveDir;
        String? savePath;
        try {
          if (Platform.isAndroid) {
            saveDir = Directory('/storage/emulated/0/Download');
            if (!await saveDir.exists()) {
              print('⚠️ [PDF] Download dir not found, using external storage dir.');
              saveDir = await getExternalStorageDirectory();
            }
          } else if (Platform.isIOS) {
            saveDir = await getApplicationDocumentsDirectory();
          } else {
            saveDir = await getApplicationDocumentsDirectory();
          }
          if (saveDir == null) {
            print('⚠️ [PDF] Save dir is null, using app documents dir.');
            saveDir = await getApplicationDocumentsDirectory();
          }
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'inspection_report_$timestamp.pdf';
          savePath = '${saveDir.path}/$filename';
          print('📁 [PDF] Saving to: $savePath');
          final file = File(savePath);
          await file.writeAsBytes(pdfBytes);
          pdfPath.value = file.path;
          print('✅ [PDF] PDF saved successfully at $savePath');
          Get.snackbar(
            'Success',
            'PDF saved to downloads successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          print('❌ [PDF] Error saving PDF: $e');
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/inspection_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(pdfBytes);
          pdfPath.value = file.path;
          print('✅ [PDF] PDF saved to fallback app directory: ${file.path}');
          Get.snackbar(
            'Success',
            'PDF generated successfully (saved to app directory)',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        print('❌ [PDF] Error generating PDF: $e');
        Get.snackbar(
          'Error',
          'Failed to generate PDF: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isGenerating.value = false;
      }
    }

    // Open PDF Method
    Future<void> openPDF() async {
      if (pdfPath.value.isEmpty) {
        print('❌ [PDF] No PDF to open. Please generate PDF first.');
        Get.snackbar('Error', 'No PDF to open. Please generate PDF first.');
        return;
      }

      try {
        final file = File(pdfPath.value);
        if (!await file.exists()) {
          print('❌ [PDF] PDF file not found at ${pdfPath.value}');
          Get.snackbar('Error', 'PDF file not found. Please generate PDF first.');
          return;
        }

        print('🚀 [PDF] Attempting to open PDF at ${pdfPath.value}...');
        final result = await OpenFile.open(pdfPath.value);
        print('📦 [PDF] OpenFile result: type=${result.type}, message=${result.message}');
        if (result.type == ResultType.done) {
          print('✅ [PDF] PDF opened successfully!');
          Get.snackbar(
            'PDF Opened',
            'PDF opened successfully in your default PDF viewer',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          print('❌ [PDF] Could not open PDF automatically. Showing share option.');
          Get.snackbar(
            'PDF Ready',
            'PDF saved to downloads. Tap to share or open with another app.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            mainButton: TextButton(
              onPressed: () async {
                try {
                  await Share.shareXFiles([XFile(pdfPath.value)], text: 'Inspection Report PDF');
                } catch (e) {
                  print('❌ [PDF] Failed to share PDF: $e');
                  Get.snackbar('Error', 'Failed to share PDF: ${e.toString()}');
                }
              },
              child: const Text('Share', style: TextStyle(color: Colors.white)),
            ),
          );
        }
      } catch (e) {
        print('❌ [PDF] Error opening PDF: $e');
        // Fallback to sharing
        try {
          await Share.shareXFiles([XFile(pdfPath.value)], text: 'Inspection Report PDF');
        } catch (shareError) {
          print('❌ [PDF] Failed to open or share PDF: $shareError');
          Get.snackbar('Error', 'Failed to open or share PDF: ${e.toString()}');
        }
      }
    }

    // Share PDF Method (kept for backward compatibility)
    Future<void> sharePDF() async {
      if (pdfPath.value.isEmpty) {
        Get.snackbar('Error', 'No PDF to share. Please generate PDF first.');
        return;
      }

      try {
        await Share.shareXFiles([XFile(pdfPath.value)], text: 'Inspection Report PDF');
      } catch (e) {
        Get.snackbar('Error', 'Failed to share PDF: ${e.toString()}');
      }
    }

    // Reset all fields
    void resetForm() {
      // Property Information
      clientName.value = '';
      address.value = '';
      state.value = '';
      zipCode.value = '';
      policyNumber.value = '';
      dateOfOrigin.value = '';
      typeOfInspection.value = '';
      inspectorName.value = '';
      inspectionDate.value = DateTime.now().toString().split(' ')[0];
      reportDate.value = DateTime.now().toString().split(' ')[0];
      summary.value = '';

      // Clear images
      logoImage.value = null;
      coverPhoto.value = null;
      primaryRiskPhotos.clear();
      frontElevationPhotos.clear();
      rightElevationPhotos.clear();
      rearElevationPhotos.clear();
      roofPhotos.clear();
      additionalPhotos.clear();

      // Reset all form fields
      neighborhood.value = '';
      areaEconomy.value = '';
      gatedCommunity.value = '';
      propertyVacant.value = '';
      nearestBodyOfWater.value = '';
      rentalProperty.value = '';
      businessOnSite.value = '';
      seasonalHome.value = '';
      historicProperty.value = '';
      nearestDwelling.value = '';

      // Reset all other fields...
      dwellingType.value = '';
      yearBuilt.value = '';
      typeOfFoundation.value = '';
      primaryConstruction.value = '';
      numberOfStories.value = '';
      livingArea.value = '';
      lotSize.value = '';
      siding.value = '';
      hvac.value = '';
      numberOfSystems.value = '';
      hvacSerial.value = '';
      guttersAndDownspout.value = '';
      fuelTank.value = '';
      sidingDamage.value = '';
      peelingPaint.value = '';
      mildewMoss.value = '';
      windowDamage.value = '';
      foundationCracks.value = '';
      wallCracks.value = '';
      chimneyDamage.value = '';
      waterDamage.value = '';
      underRenovation.value = '';
      mainBreakerPanel.value = '';
      waterSpicketDamage.value = '';
      doorDamage.value = '';

      pdfPath.value = '';
      
      Get.snackbar('Success', 'Form reset successfully');
    }
  }