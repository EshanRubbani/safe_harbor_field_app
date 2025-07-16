//old code
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class OptimizedInspectionPDFTemplate {
  // Cache for fonts and images to improve performance
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static Uint8List? _logoImage;
  static Uint8List? _coverImageBytes;
  static Uint8List? _headerImageBytes;

  /// Initialize fonts and images for better performance
  static Future<void> _initializeAssets() async {
    if (_regularFont == null) {
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
    }

    if (_logoImage == null) {
      try {
        _logoImage = (await rootBundle.load('assets/safe_harbor_small.png'))
            .buffer
            .asUint8List();
      } catch (e) {
        print('Failed to load logo image: $e');
      }
    }

    if (_coverImageBytes == null) {
      try {
        _coverImageBytes = (await rootBundle.load('assets/cover_image.png'))
            .buffer
            .asUint8List();
      } catch (e) {
        print('Failed to load cover image: $e');
      }
    }
  }

  static Future<Uint8List> generateInspectionReport({
    required String clientName,
    required String address,
    required String state,
    required String zipCode,
    required String policyNumber,
    required String dateOfOrigin,
    required String typeOfInspection,
    required String inspectorName,
    required String inspectionDate,
    required String reportDate,
    required Uint8List? logoImage,
    required Uint8List? coverPhoto,
    required List<Uint8List> primaryRiskPhotos,
    required List<Uint8List> frontElevationPhotos,
    required List<Uint8List> rightElevationPhotos,
    required List<Uint8List> rearElevationPhotos,
    required List<Uint8List> roofPhotos,
    required List<Uint8List> additionalPhotos,
    required OverallRiskInfo overallRiskInfo,
    required ElevationCondition elevationCondition,
    required RoofCondition roofCondition,
    required GarageCondition garageCondition,
    required DwellingHazards dwellingHazards,
    required PossibleHazards possibleHazards,
    required String summary,
  }) async {
    // Initialize assets for better performance
    await _initializeAssets();

    final pdf = pw.Document();
    final font = _regularFont!;
    final boldFont = _boldFont!;

    String formattedDate = '';
    try {
      final date = DateTime.parse(dateOfOrigin);
      formattedDate = DateFormat('MM/dd/yyyy').format(date);
    } catch (_) {
      formattedDate = dateOfOrigin; // fallback if parsing fails
    }

    // New Cover Page with exact design
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildNewCoverPage(
            clientName: clientName,
            address: address,
            state: state,
            zipCode: zipCode,
            policyNumber: policyNumber,
            dateOfOrigin: dateOfOrigin,
            typeOfInspection: typeOfInspection,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    // Optimized Photo sections with headers only on pages with photos
    final photoSections = [
      {'title': 'Primary Risk Photo', 'photos': primaryRiskPhotos},
      {'title': 'Front Elevation Photos', 'photos': frontElevationPhotos},
      {'title': 'Right Elevation Photos', 'photos': rightElevationPhotos},
      {'title': 'Rear Elevation Photos', 'photos': rearElevationPhotos},
      {'title': 'Roof Photos', 'photos': roofPhotos},
      {'title': 'Additional Photos', 'photos': additionalPhotos},
    ];

    for (var section in photoSections) {
      final photos = section['photos'] as List<Uint8List>;
      if (photos.isNotEmpty) {
        _addOptimizedPhotoSection(
            pdf: pdf,
            title: section['title'] as String,
            photos: photos,
            clientName: clientName,
            address: address,
            state: state,
            zipCode: zipCode,
            policyNumber: policyNumber,
            font: font,
            boldFont: boldFont,
            dateOfOrigin: formattedDate);
      }
    }

    // Details Section (without header)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildDetailsPage(
            clientName: clientName,
            address: address,
            state: state,
            zipCode: zipCode,
            policyNumber: policyNumber,
            inspectionDate: inspectionDate,
            inspectorName: inspectorName,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    // Data pages without headers
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildOverallRiskPage(
            overallRiskInfo: overallRiskInfo,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildElevationConditionPage(
            elevationCondition: elevationCondition,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildRoofConditionPage(
            roofCondition: roofCondition,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildGarageConditionPage(
            garageCondition: garageCondition,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildDwellingHazardsPage(
            dwellingHazards: dwellingHazards,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildPossibleHazardsPage(
            possibleHazards: possibleHazards,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildSummaryPage(
            summary: summary,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Build the new cover page exactly as specified
  static pw.Widget _buildNewCoverPage({
    required String clientName,
    required String address,
    required String state,
    required String zipCode,
    required String policyNumber,
    required String dateOfOrigin,
    required String typeOfInspection,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    String formattedDate = '';
    try {
      final date = DateTime.parse(dateOfOrigin);
      formattedDate = DateFormat('MM/dd/yyyy').format(date);
    } catch (_) {
      formattedDate = dateOfOrigin; // fallback if parsing fails
    }

    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Column(
        children: [
          // Logo at the top
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.only(top: 30, bottom: 15),
            child: pw.Center(
              child: pw.Container(
                width: 180,
                height: 50,
                decoration: pw.BoxDecoration(
                  image: _logoImage != null
                      ? pw.DecorationImage(
                          image: pw.MemoryImage(_logoImage!),
                          fit: pw.BoxFit.contain,
                        )
                      : null,
                ),
                child: _logoImage == null
                    ? pw.Center(
                        child: pw.Text(
                          'Safe Harbor',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 22,
                            color: PdfColors.blue,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Main title
          pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: 15),
            child: pw.Text(
              'Underwriting Inspection Report',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 28,
                color: PdfColors.black,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          // Safe Harbor Adjusting with underline
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              children: [
                pw.Text(
                  'Safe Harbor Adjusting',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: PdfColors.blue,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Container(
                  margin: pw.EdgeInsets.only(top: 5),
                  width: 180,
                  height: 2,
                  color: PdfColors.blue,
                ),
              ],
            ),
          ),

          // Center hexagonal image
          pw.Container(
            width: 350,
            height: 200,
            child: pw.ClipRRect(
              child: pw.Image(
                pw.MemoryImage(_coverImageBytes!),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),

          pw.SizedBox(height: 10),

          // Address and information at the bottom
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.only(bottom: 30),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Address',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    address,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    '$state, $zipCode',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Client Name: $clientName',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Project/Claim: $policyNumber',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Date of Origin: $formattedDate',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Type of Inspection: $typeOfInspection',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the new header exactly as specified
  static pw.Widget _buildNewHeader({
    required String clientName,
    required String address,
    required String state,
    required String zipCode,
    required String policyNumber,
    required String dateOfOrigin,
    required String typeOfInspection,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      height: 120,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Row(
        children: [
          // Left side - Logo and title
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: pw.EdgeInsets.all(8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // pw.SizedBox(width: 15),
                  // Title
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Photo Report',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Container(
                        margin: pw.EdgeInsets.only(top: 5),
                        width: 150,
                        height: 2,
                        color: PdfColors.blue,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Safe Harbor Adjusting',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 14,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 5),

                      // Logo
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          image: _logoImage != null
                              ? pw.DecorationImage(
                                  image: pw.MemoryImage(_logoImage!),
                                  fit: pw.BoxFit.contain,
                                )
                              : null,
                        ),
                        child: _logoImage == null
                            ? pw.Center(
                                child: pw.Text(
                                  'SH',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 16,
                                    color: PdfColors.blue,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Right side - Property info
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: pw.EdgeInsets.only(left: 15, right: 15),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  // PROPERTY INFO header with line
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROPERTY INFO',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Container(
                        margin: pw.EdgeInsets.only(top: 2),
                        width: 100,
                        height: 2,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  // Client info
                  pw.Text(
                    clientName,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    address,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    '$state, $zipCode',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Second line separator
                  pw.Container(
                    width: 100,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  // Additional info
                  pw.Text(
                    'Project/Claim: $policyNumber',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Policy: $policyNumber',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Date of Origin: $dateOfOrigin',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Type of Inspection: $typeOfInspection',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Add optimized photo section with support for up to 10 images
  static void _addOptimizedPhotoSection(
      {required pw.Document pdf,
      required String title,
      required List<Uint8List> photos,
      required String clientName,
      required String address,
      required String state,
      required String zipCode,
      required String policyNumber,
      required pw.Font font,
      required pw.Font boldFont,
      required String dateOfOrigin}) {
    // Calculate number of pages needed (4 photos per page for better quality)
    const photosPerPage = 4;

    for (int i = 0; i < photos.length; i += photosPerPage) {
      final endIndex = (i + photosPerPage < photos.length)
          ? i + photosPerPage
          : photos.length;
      final pagePhotos = photos.sublist(i, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildOptimizedPhotoPage(
              title: title,
              photos: pagePhotos,
              clientName: clientName,
              address: address,
              state: state,
              zipCode: zipCode,
              policyNumber: policyNumber,
              font: font,
              boldFont: boldFont,
              dateOfOrigin: dateOfOrigin,
            );
          },
        ),
      );
    }
  }

  /// Build optimized photo page with new header
  static pw.Widget _buildOptimizedPhotoPage({
    required String title,
    required List<Uint8List> photos,
    required String clientName,
    required String address,
    required String state,
    required String zipCode,
    required String policyNumber,
    required pw.Font font,
    required pw.Font boldFont,
    required String dateOfOrigin,
  }) {
    return pw.Column(
      children: [
        // New header only on photo pages
        _buildNewHeader(
          clientName: clientName,
          address: address,
          state: state,
          zipCode: zipCode,
          policyNumber: policyNumber,
          font: font,
          boldFont: boldFont,
          dateOfOrigin: dateOfOrigin,
          typeOfInspection: 'UnderWriting',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          title,
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 20),
        pw.Expanded(
          child: _buildOptimizedPhotoGrid(photos, font, title),
        ),
      ],
    );
  }

  /// Build optimized photo grid with 2x2 layout
  static pw.Widget _buildOptimizedPhotoGrid(
      List<Uint8List> photos, pw.Font font, String sectionTitle) {
    List<pw.Widget> rows = [];

    for (int i = 0; i < photos.length; i += 2) {
      List<pw.Widget> rowPhotos = [];

      // Add first photo with caption
      rowPhotos.add(
        pw.Expanded(
          child: pw.Container(
            margin: pw.EdgeInsets.all(8),
            child: pw.Column(
              children: [
                pw.Container(
                  height: 180,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.ClipRRect(
                    child: pw.Image(
                      pw.MemoryImage(photos[i]),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: pw.EdgeInsets.all(6),
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Dwelling > Exterior > $sectionTitle',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.Text(
                        'Date taken: ${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().year}',
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Add second photo if exists
      if (i + 1 < photos.length) {
        rowPhotos.add(
          pw.Expanded(
            child: pw.Container(
              margin: pw.EdgeInsets.all(8),
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 180,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.ClipRRect(
                      child: pw.Image(
                        pw.MemoryImage(photos[i + 1]),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: pw.EdgeInsets.all(6),
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Dwelling > Exterior > $sectionTitle',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.Text(
                          'Date taken: ${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().year}',
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Add empty space if odd number of photos
        rowPhotos.add(pw.Expanded(child: pw.Container()));
      }

      rows.add(pw.Row(children: rowPhotos));
    }

    return pw.Column(children: rows);
  }

  // Other page builders without headers
  static pw.Widget _buildDetailsPage({
    required String clientName,
    required String address,
    required String state,
    required String zipCode,
    required String policyNumber,
    required String inspectionDate,
    required String inspectorName,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 30),
        pw.Text(
          'Inspection Details',
          style: pw.TextStyle(font: boldFont, fontSize: 18),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Insured:', clientName, font, boldFont),
              _buildDetailRow('Address:', address, font, boldFont),
              _buildDetailRow('State:', state, font, boldFont),
              _buildDetailRow('Zip Code:', zipCode, font, boldFont),
              _buildDetailRow('Policy Number:', policyNumber, font, boldFont),
              _buildDetailRow(
                  'Inspection Date:', inspectionDate, font, boldFont),
              _buildDetailRow('Inspector Name:', inspectorName, font, boldFont),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Dear Mercury Insurance,',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Please see below the underwriting inspection report outlining the overview of property at $address, $state, $zipCode. The Assignment was submitted to Safe Harbor with a request to complete a exterior underwriting inspection. Thank You for the opportunity to provide you with this report.',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildOverallRiskPage({
    required OverallRiskInfo overallRiskInfo,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Overall Risk Information',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        _buildTable([
          ['FIELD', 'VALUE'],
          ['NEIGHBORHOOD', overallRiskInfo.neighborhood],
          ['AREA ECONOMY', overallRiskInfo.areaEconomy],
          ['GATED COMMUNITY', overallRiskInfo.gatedCommunity ? 'Yes' : 'No'],
          ['PROPERTY VACANT', overallRiskInfo.propertyVacant ? 'Yes' : 'No'],
          ['NEAREST BODY OF WATER', overallRiskInfo.nearestBodyOfWater],
          ['RENTAL PROPERTY', overallRiskInfo.rentalProperty ? 'Yes' : 'No'],
          ['BUSINESS ON SITE', overallRiskInfo.businessOnSite ? 'Yes' : 'No'],
          ['SEASONAL HOME', overallRiskInfo.seasonalHome ? 'Yes' : 'No'],
          [
            'HISTORIC PROPERTY',
            overallRiskInfo.historicProperty ? 'Yes' : 'No'
          ],
          ['NEAREST DWELLING', '${overallRiskInfo.nearestDwelling} ft'],
        ], font, boldFont),
      ],
    );
  }

  static pw.Widget _buildElevationConditionPage({
    required ElevationCondition elevationCondition,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Overall Elevation Condition',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        _buildTable([
          ['FIELD', 'VALUE'],
          ['DWELLING TYPE', elevationCondition.dwellingType],
          ['YEAR BUILT', '${elevationCondition.yearBuilt}'],
          ['TYPE OF FOUNDATION', elevationCondition.foundationType],
          ['PRIMARY CONSTRUCTION', elevationCondition.primaryConstruction],
          ['NUMBER OF STORIES', '${elevationCondition.numberOfStories}'],
          ['LIVING AREA', '${elevationCondition.livingArea} sqft'],
          ['LOT SIZE', elevationCondition.lotSize],
          ['SIDING', elevationCondition.siding],
          ['HVAC', elevationCondition.hvac],
          ['NUMBER OF SYSTEMS', '${elevationCondition.numberOfSystems}'],
          ['HVAC SERIAL #', elevationCondition.hvacSerial],
          [
            'GUTTERS AND DOWNSPOUT',
            elevationCondition.guttersAndDownspout ? 'Yes' : 'No'
          ],
          ['FUEL TANK', elevationCondition.fuelTank ? 'Yes' : 'No'],
          ['SIDING DAMAGE', elevationCondition.sidingDamage ? 'Yes' : 'No'],
          ['PEELING PAINT', elevationCondition.peelingPaint ? 'Yes' : 'No'],
          ['MILDEW/MOSS', elevationCondition.mildewMoss ? 'Yes' : 'No'],
          ['WINDOW DAMAGE', elevationCondition.windowDamage ? 'Yes' : 'No'],
          [
            'FOUNDATION CRACKS',
            elevationCondition.foundationCracks ? 'Yes' : 'No'
          ],
          ['WALL CRACKS', elevationCondition.wallCracks ? 'Yes' : 'No'],
          ['CHIMNEY DAMAGE', elevationCondition.chimneyDamage],
          ['WATER DAMAGE', elevationCondition.waterDamage ? 'Yes' : 'No'],
          [
            'UNDER RENOVATION',
            elevationCondition.underRenovation ? 'Yes' : 'No'
          ],
          [
            'MAIN BREAKER PANEL',
            elevationCondition.mainBreakerPanel ? 'Yes' : 'No'
          ],
          [
            'WATER SPICKET DAMAGE',
            elevationCondition.waterSpicketDamage ? 'Yes' : 'No'
          ],
          ['DOOR DAMAGE', elevationCondition.doorDamage ? 'Yes' : 'No'],
        ], font, boldFont),
      ],
    );
  }

  static pw.Widget _buildRoofConditionPage({
    required RoofCondition roofCondition,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Overall Roof Condition',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        _buildTable([
          ['FIELD', 'VALUE'],
          ['ROOF MATERIAL', roofCondition.roofMaterial],
          ['ROOF COVERING', roofCondition.roofCovering],
          ['AGE OF ROOF', roofCondition.ageOfRoof],
          ['SHAPE OF ROOF', roofCondition.shapeOfRoof],
          ['TREE LIMBS ON ROOF', roofCondition.treeLimbsOnRoof ? 'Yes' : 'No'],
          ['DEBRIS ON ROOF', roofCondition.debrisOnRoof ? 'Yes' : 'No'],
          ['SOLAR PANEL', roofCondition.solarPanel ? 'Yes' : 'No'],
          ['EXPOSED FELT', roofCondition.exposedFelt ? 'Yes' : 'No'],
          [
            'MISSING SHINGLES/TILES',
            roofCondition.missingShingles ? 'Yes' : 'No'
          ],
          ['PRIOR REPAIRS', roofCondition.priorRepairs ? 'Yes' : 'No'],
          ['CURLING SHINGLES', roofCondition.curlingShingles ? 'Yes' : 'No'],
          ['ALGAE/MOSS', roofCondition.algaeMoss ? 'Yes' : 'No'],
          ['TARP ON ROOF', roofCondition.tarpOnRoof ? 'Yes' : 'No'],
          ['BROKEN OR CRACKED TILES', roofCondition.brokenCrackTiles],
          ['SATELLITE DISH', roofCondition.satelliteDish ? 'Yes' : 'No'],
          ['UNEVEN DECKING', roofCondition.unevenDecking ? 'Yes' : 'No'],
        ], font, boldFont),
      ],
    );
  }

  static pw.Widget _buildGarageConditionPage({
    required GarageCondition garageCondition,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Garage/Outbuilding Overall Condition',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        _buildTable([
          ['FIELD', 'VALUE'],
          ['GARAGE TYPE', garageCondition.garageType],
          ['OUTBUILDING', garageCondition.outbuilding ? 'Yes' : 'No'],
          ['OUTBUILDING TYPE', garageCondition.outbuildingType],
          ['FENCE', garageCondition.fence],
          ['GARAGE CONDITION', garageCondition.garageCondition],
          ['CARPORT OR AWNING', garageCondition.carportOrAwning ? 'Yes' : 'No'],
          ['CARPORT CONSTRUCTION', garageCondition.carportConstruction],
          ['FENCE CONDITION', garageCondition.fenceCondition],
        ], font, boldFont),
      ],
    );
  }

  static pw.Widget _buildDwellingHazardsPage({
    required DwellingHazards dwellingHazards,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Dwelling Hazards',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        _buildTable([
          ['FIELD', 'VALUE'],
          [
            'BOARDED DOORS/WINDOWS',
            dwellingHazards.boardedDoorsWindows ? 'Yes' : 'No'
          ],
          [
            'OVERGROWN VEGETATION',
            dwellingHazards.overgrownVegetation ? 'Yes' : 'No'
          ],
          [
            'ABANDONED VEHICLES',
            dwellingHazards.abandonedVehicles ? 'Yes' : 'No'
          ],
          ['MISSING/DAMAGE STEPS', dwellingHazards.missingSteps ? 'Yes' : 'No'],
          [
            'MISSING/DAMAGE RAILING',
            dwellingHazards.missingRailing ? 'Yes' : 'No'
          ],
          ['SIDING DAMAGE', dwellingHazards.sidingDamage ? 'Yes' : 'No'],
          [
            'HURRICANE SHUTTERS',
            dwellingHazards.hurricaneShutters ? 'Yes' : 'No'
          ],
          ['TREE/BRANCH', dwellingHazards.treeBranch ? 'Yes' : 'No'],
          [
            'CHIMNEY THROUGH ROOF',
            dwellingHazards.chimneyThroughRoof ? 'Yes' : 'No'
          ],
          [
            'FIREPLACE/PIT OUTSIDE',
            dwellingHazards.fireplacePit ? 'Yes' : 'No'
          ],
          ['SECURITY BARS', dwellingHazards.securityBars ? 'Yes' : 'No'],
          [
            'FACIA/SOFFIT DAMAGE',
            dwellingHazards.faciaSoffitDamage ? 'Yes' : 'No'
          ],
        ], font, boldFont),
      ],
    );
  }

  static pw.Widget _buildPossibleHazardsPage({
    required PossibleHazards possibleHazards,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Possible Hazards',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        _buildTable([
          ['FIELD', 'VALUE'],
          ['SWIMMING POOL', possibleHazards.swimmingPool ? 'Yes' : 'No'],
          ['DIVING BOARD OR SLIDE', possibleHazards.divingBoard ? 'Yes' : 'No'],
          ['POOL FENCED', possibleHazards.poolFenced ? 'Yes' : 'No'],
          ['TRAMPOLINE', possibleHazards.trampoline ? 'Yes' : 'No'],
          ['SWING SET', possibleHazards.swingSet ? 'Yes' : 'No'],
          ['BASKETBALL GOAL', possibleHazards.basketballGoal ? 'Yes' : 'No'],
          ['DOG', possibleHazards.dog ? 'Yes' : 'No'],
          ['DOG TYPE', possibleHazards.dogType],
          ['DOG SIGN', possibleHazards.dogSign ? 'Yes' : 'No'],
          [
            'SKATEBOARD OR BIKE RAMP',
            possibleHazards.skateboardRamp ? 'Yes' : 'No'
          ],
          ['TREE HOUSE', possibleHazards.treeHouse ? 'Yes' : 'No'],
          ['DEBRIS IN YARD', possibleHazards.debrisInYard ? 'Yes' : 'No'],
        ], font, boldFont),
      ],
    );
  }

  static pw.Widget _buildSummaryPage({
    required String summary,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 30),
        pw.Text(
          'Summary',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Text(
            summary,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
      List<List<String>> data, pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: [
        // Header Row with Styling
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: data[0]
              .map((header) => pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(
                          font: boldFont, fontSize: 12, color: PdfColors.black),
                    ),
                  ))
              .toList(),
        ),

        // Data Rows
        ...data.sublist(1).map((row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          cell,
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  static pw.Widget _buildDetailRow(
      String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: boldFont, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Data model classes (keep the same as original)
class OverallRiskInfo {
  final String neighborhood;
  final String areaEconomy;
  final bool gatedCommunity;
  final bool propertyVacant;
  final String nearestBodyOfWater;
  final bool rentalProperty;
  final bool businessOnSite;
  final bool seasonalHome;
  final bool historicProperty;
  final int nearestDwelling;

  OverallRiskInfo({
    required this.neighborhood,
    required this.areaEconomy,
    required this.gatedCommunity,
    required this.propertyVacant,
    required this.nearestBodyOfWater,
    required this.rentalProperty,
    required this.businessOnSite,
    required this.seasonalHome,
    required this.historicProperty,
    required this.nearestDwelling,
  });
}

class ElevationCondition {
  final String dwellingType;
  final int yearBuilt;
  final String foundationType;
  final String primaryConstruction;
  final int numberOfStories;
  final int livingArea;
  final String lotSize;
  final String siding;
  final String hvac;
  final int numberOfSystems;
  final String hvacSerial;
  final bool guttersAndDownspout;
  final bool fuelTank;
  final bool sidingDamage;
  final bool peelingPaint;
  final bool mildewMoss;
  final bool windowDamage;
  final bool foundationCracks;
  final bool wallCracks;
  final String chimneyDamage;
  final bool waterDamage;
  final bool underRenovation;
  final bool mainBreakerPanel;
  final bool waterSpicketDamage;
  final bool doorDamage;

  ElevationCondition({
    required this.dwellingType,
    required this.yearBuilt,
    required this.foundationType,
    required this.primaryConstruction,
    required this.numberOfStories,
    required this.livingArea,
    required this.lotSize,
    required this.siding,
    required this.hvac,
    required this.numberOfSystems,
    required this.hvacSerial,
    required this.guttersAndDownspout,
    required this.fuelTank,
    required this.sidingDamage,
    required this.peelingPaint,
    required this.mildewMoss,
    required this.windowDamage,
    required this.foundationCracks,
    required this.wallCracks,
    required this.chimneyDamage,
    required this.waterDamage,
    required this.underRenovation,
    required this.mainBreakerPanel,
    required this.waterSpicketDamage,
    required this.doorDamage,
  });
}

class RoofCondition {
  final String roofMaterial;
  final String roofCovering;
  final String ageOfRoof;
  final String shapeOfRoof;
  final bool treeLimbsOnRoof;
  final bool debrisOnRoof;
  final bool solarPanel;
  final bool exposedFelt;
  final bool missingShingles;
  final bool priorRepairs;
  final bool curlingShingles;
  final bool algaeMoss;
  final bool tarpOnRoof;
  final String brokenCrackTiles;
  final bool satelliteDish;
  final bool unevenDecking;

  RoofCondition({
    required this.roofMaterial,
    required this.roofCovering,
    required this.ageOfRoof,
    required this.shapeOfRoof,
    required this.treeLimbsOnRoof,
    required this.debrisOnRoof,
    required this.solarPanel,
    required this.exposedFelt,
    required this.missingShingles,
    required this.priorRepairs,
    required this.curlingShingles,
    required this.algaeMoss,
    required this.tarpOnRoof,
    required this.brokenCrackTiles,
    required this.satelliteDish,
    required this.unevenDecking,
  });
}

class GarageCondition {
  final String garageType;
  final bool outbuilding;
  final String outbuildingType;
  final String fence;
  final String garageCondition;
  final bool carportOrAwning;
  final String carportConstruction;
  final String fenceCondition;

  GarageCondition({
    required this.garageType,
    required this.outbuilding,
    required this.outbuildingType,
    required this.fence,
    required this.garageCondition,
    required this.carportOrAwning,
    required this.carportConstruction,
    required this.fenceCondition,
  });
}

class DwellingHazards {
  final bool boardedDoorsWindows;
  final bool overgrownVegetation;
  final bool abandonedVehicles;
  final bool missingSteps;
  final bool missingRailing;
  final bool sidingDamage;
  final bool hurricaneShutters;
  final bool treeBranch;
  final bool chimneyThroughRoof;
  final bool fireplacePit;
  final bool securityBars;
  final bool faciaSoffitDamage;

  DwellingHazards({
    required this.boardedDoorsWindows,
    required this.overgrownVegetation,
    required this.abandonedVehicles,
    required this.missingSteps,
    required this.missingRailing,
    required this.sidingDamage,
    required this.hurricaneShutters,
    required this.treeBranch,
    required this.chimneyThroughRoof,
    required this.fireplacePit,
    required this.securityBars,
    required this.faciaSoffitDamage,
  });
}

class PossibleHazards {
  final bool swimmingPool;
  final bool divingBoard;
  final bool poolFenced;
  final bool trampoline;
  final bool swingSet;
  final bool basketballGoal;
  final bool dog;
  final String dogType;
  final bool dogSign;
  final bool skateboardRamp;
  final bool treeHouse;
  final bool debrisInYard;

  PossibleHazards({
    required this.swimmingPool,
    required this.divingBoard,
    required this.poolFenced,
    required this.trampoline,
    required this.swingSet,
    required this.basketballGoal,
    required this.dog,
    required this.dogType,
    required this.dogSign,
    required this.skateboardRamp,
    required this.treeHouse,
    required this.debrisInYard,
  });
}
