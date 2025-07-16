import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';
import 'package:safe_harbor_field_app/app/models/inspection_report_model.dart';
import 'package:safe_harbor_field_app/app/utils/pdf_template_optimized.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes;

class DynamicPDFGenerationService extends GetxService {
  final QuestionnaireService _questionnaireService =
      Get.find<QuestionnaireService>();

  // Cache for fonts and assets
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static Uint8List? _logoImage;
  static Uint8List? _coverImageBytes;

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

  /// Generate PDF from report data dynamically
  Future<Uint8List> generateDynamicPDF({
    required Map<String, dynamic> questionnaireResponses,
    required Map<String, List<String>> imageUrlsByCategory,
    String? summary,
  }) async {
    print('📝 Starting PDF generation...');
    await _initializeAssets();
    print('🔤 Fonts and images initialized.');

    final pdf = pw.Document();
    final font = _regularFont!;
    final boldFont = _boldFont!;

    // Extract basic info from questionnaire responses
    final basicInfo = _extractBasicInfo(questionnaireResponses);
    print('📋 Extracted basic info: ${basicInfo.toString()}');

    // Integrate styled cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildNewCoverPage(
            clientName: basicInfo['clientName'] ?? 'N/A',
            address: basicInfo['address'] ?? 'N/A',
            state: basicInfo['state'] ?? 'N/A',
            zipCode: basicInfo['zipCode'] ?? 'N/A',
            policyNumber: basicInfo['policyNumber'] ?? 'N/A',
            dateOfOrigin: basicInfo['inspectionDate'] ?? 'N/A',
            typeOfInspection: 'Under-Writing',
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );
    print('📄 Added cover page.');

    // Integrate styled photo pages
    await _addOptimizedPhotoPagesAsync(
        pdf, imageUrlsByCategory, basicInfo, font, boldFont);

    // Generate questionnaire sections with a styled table
    _addStyledQuestionnaireSections(
        pdf, questionnaireResponses, font, boldFont);
    print('📄 Added questionnaire sections.');

    // Styled summary page
    if (summary != null && summary.isNotEmpty) {
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
      print('📄 Added summary page.');
    }

    print('✅ PDF generation complete!');
    return pdf.save();
  }

  /// Generate PDF from inspection report model
  Future<Uint8List> generatePDFFromInspectionReport({
    required InspectionReportModel report,
    String? summary,
  }) async {
    return generateDynamicPDF(
      questionnaireResponses: report.questionnaireResponses,
      imageUrlsByCategory: report.images,
      summary: summary ?? 'Inspection completed successfully.',
    );
  }

  /// Extract basic information from questionnaire responses
  Map<String, String> _extractBasicInfo(Map<String, dynamic> responses) {
    final basicInfo = <String, String>{};

    // Define patterns for common fields
    final fieldPatterns = {
      'clientName': ['client_name', 'insured_name', 'property_owner', 'name'],
      'address': [
        'address',
        'street_address',
        'property_address',
        'insured_address'
      ],
      'state': ['state', 'property_state', 'insured_state'],
      'zipCode': ['zip_code', 'postal_code', 'zip', 'insured_zip'],
      'policyNumber': ['policy_number', 'policy_no', 'policy_num'],
      'inspectorName': ['inspector_name', 'inspector', 'surveyor_name'],
      'inspectionDate': [
        'inspection_date',
        'date_of_inspection',
        'survey_date'
      ],
      'reportDate': ['report_date', 'date_of_report', 'completion_date'],
    };

    // Extract values using flexible pattern matching
    fieldPatterns.forEach((key, patterns) {
      basicInfo[key] = _findValueByPatterns(responses, patterns);
    });

    return basicInfo;
  }

  /// Find value by matching patterns in questionnaire responses
  String _findValueByPatterns(
      Map<String, dynamic> responses, List<String> patterns) {
    // Try to match field keys and question texts using the enhanced structure
    for (final pattern in patterns) {
      for (final entry in responses.entries) {
        final fieldKey = entry.key;
        final fieldData = entry.value;

        // Handle enhanced structure with metadata
        if (fieldData is Map<String, dynamic>) {
          final questionText = fieldData['question_text'] as String? ?? '';
          final value = fieldData['value'];

          // Check if pattern matches field key or question text
          if (fieldKey.toLowerCase() == pattern ||
              _convertQuestionToFieldKey(questionText).toLowerCase() ==
                  pattern ||
              questionText
                  .toLowerCase()
                  .contains(pattern.replaceAll('_', ' '))) {
            if (value != null && value.toString().trim().isNotEmpty) {
              return value.toString();
            }
          }
        } else {
          // Handle simple key-value pairs
          if (fieldKey.toLowerCase() == pattern) {
            if (fieldData != null && fieldData.toString().trim().isNotEmpty) {
              return fieldData.toString();
            }
          }
        }
      }
    }

    return 'N/A';
  }

  /// Convert question text to field key
  String _convertQuestionToFieldKey(String questionText) {
    return questionText
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Build dynamic cover page
  pw.Widget _buildDynamicCoverPage({
    required Map<String, String> basicInfo,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo

          if (_logoImage != null)
            pw.Container(
              height: 60,
              child: pw.Image(pw.MemoryImage(_logoImage!)),
            ),

          pw.SizedBox(height: 40),

          // Title
          pw.Text(
            'INSPECTION REPORT',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 28,
              color: PdfColors.blue800,
            ),
          ),

          pw.SizedBox(height: 30),

          // Dynamic basic information
          ...basicInfo.entries.map((entry) {
            if (entry.value != 'N/A' && entry.value.isNotEmpty) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 120,
                      child: pw.Text(
                        _formatFieldLabel(entry.key),
                        style: pw.TextStyle(font: boldFont, fontSize: 12),
                      ),
                    ),
                    pw.Text(
                      ': ',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        entry.value,
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }
            return pw.SizedBox();
          }),

          pw.Spacer(),

          // Footer
          pw.Text(
            'Generated on ${DateFormat('MM/dd/yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Add dynamic photo pages
  void _addDynamicPhotoPages(
    pw.Document pdf,
    Map<String, List<String>> imageUrlsByCategory,
    Map<String, String> basicInfo,
    pw.Font font,
    pw.Font boldFont,
  ) {
    imageUrlsByCategory.forEach((category, imageUrls) {
      if (imageUrls.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return _buildPhotoPage(
                title: _formatFieldLabel(category),
                imageUrls: imageUrls,
                font: font,
                boldFont: boldFont,
              );
            },
          ),
        );
      }
    });
  }

  /// Add styled questionnaire sections
  void _addStyledQuestionnaireSections(
    pw.Document pdf,
    Map<String, dynamic> responses,
    pw.Font font,
    pw.Font boldFont,
  ) {
    // Group responses by section
    final sectionMap = <String, List<Map<String, dynamic>>>{};

    responses.forEach((fieldKey, fieldData) {
      if (fieldData is Map<String, dynamic>) {
        final section = fieldData['section'] as String? ?? 'General';
        final questionText = fieldData['question_text'] as String? ?? fieldKey;
        final value = fieldData['value'];

        if (value != null && value.toString().trim().isNotEmpty) {
          if (!sectionMap.containsKey(section)) {
            sectionMap[section] = [];
          }
          sectionMap[section]!.add({
            'question_text': questionText,
            'value': value,
            'field_key': fieldKey,
          });
        }
      }
    });

    // Generate pages for each section, paginating if too many questions
    const int maxRowsPerPage = 18;
    sectionMap.forEach((sectionName, questions) {
      if (questions.isNotEmpty) {
        for (int i = 0; i < questions.length; i += maxRowsPerPage) {
          final chunk = questions.sublist(
            i,
            (i + maxRowsPerPage < questions.length)
                ? i + maxRowsPerPage
                : questions.length,
          );
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text(
                      sectionName.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildTable(
                      [
                        ['QUESTION', 'ANSWER'],
                        ...chunk.map(
                            (q) => [q['question_text'], q['value'].toString()])
                      ],
                      font,
                      boldFont,
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
    });
  }

  /// Build questionnaire section page
  pw.Widget _buildQuestionnaireSectionPage({
    required String sectionName,
    required List<Map<String, dynamic>> questions,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section title
          pw.Text(
            sectionName.toUpperCase(),
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.blue800,
            ),
          ),

          pw.SizedBox(height: 20),

          // Questions and answers
          ...questions.map((questionData) {
            final questionText =
                questionData['question_text'] as String? ?? 'Unknown Question';
            final value = questionData['value'];

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 15),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    questionText,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    value.toString(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build photo page
  pw.Widget _buildPhotoPage({
    required String title,
    required List<String> imageUrls,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.blue800,
            ),
          ),

          pw.SizedBox(height: 20),

          // Photo grid (placeholder - you'd need to implement actual image loading)
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                '${imageUrls.length} photo(s) available',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build dynamic summary page
  pw.Widget _buildDynamicSummaryPage({
    required Map<String, dynamic> responses,
    required String summary,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    // Calculate statistics
    final totalQuestions = responses.length;
    final answeredQuestions = responses.values.where((fieldData) {
      if (fieldData is Map<String, dynamic>) {
        final value = fieldData['value'];
        return value != null && value.toString().trim().isNotEmpty;
      }
      return fieldData != null && fieldData.toString().trim().isNotEmpty;
    }).length;
    final completionRate = totalQuestions > 0
        ? (answeredQuestions / totalQuestions * 100).round()
        : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INSPECTION SUMMARY',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.blue800,
            ),
          ),

          pw.SizedBox(height: 20),

          // Statistics
          pw.Text(
            'Total Questions: $totalQuestions',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.Text(
            'Answered Questions: $answeredQuestions',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.Text(
            'Completion Rate: $completionRate%',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),

          pw.SizedBox(height: 20),

          // Custom summary text
          if (summary.isNotEmpty) ...[
            pw.Text(
              'Summary:',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 14,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              summary,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.SizedBox(height: 20),
          ],

          // Section breakdown
          pw.Text(
            'SECTION BREAKDOWN',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.blue800,
            ),
          ),

          pw.SizedBox(height: 15),

          // Dynamic section statistics
          ..._getDynamicSectionStatistics(responses, font, boldFont),
        ],
      ),
    );
  }

  /// Get dynamic section statistics
  List<pw.Widget> _getDynamicSectionStatistics(
    Map<String, dynamic> responses,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final sectionStats = <String, Map<String, int>>{};

    responses.forEach((fieldKey, fieldData) {
      if (fieldData is Map<String, dynamic>) {
        final section = fieldData['section'] as String? ?? 'General';
        final value = fieldData['value'];

        if (!sectionStats.containsKey(section)) {
          sectionStats[section] = {'total': 0, 'answered': 0};
        }
        sectionStats[section]!['total'] = sectionStats[section]!['total']! + 1;
        if (value != null && value.toString().trim().isNotEmpty) {
          sectionStats[section]!['answered'] =
              sectionStats[section]!['answered']! + 1;
        }
      }
    });

    return sectionStats.entries.map((entry) {
      final section = entry.key;
      final stats = entry.value;
      final total = stats['total']!;
      final answered = stats['answered']!;
      final percentage = total > 0 ? (answered / total * 100).round() : 0;

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 200,
              child: pw.Text(
                section,
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ),
            pw.Text(
              '$answered/$total ($percentage%)',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Format field label for display
  String _formatFieldLabel(String fieldKey) {
    return fieldKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  /// Build the styled cover page from optimized template
  pw.Widget _buildNewCoverPage({
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
          if (_coverImageBytes != null)
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

  /// Add optimized photo pages (async version for await in generateDynamicPDF)
  Future<void> _addOptimizedPhotoPagesAsync(
    pw.Document pdf,
    Map<String, List<String>> imageUrlsByCategory,
    Map<String, String> basicInfo,
    pw.Font font,
    pw.Font boldFont,
  ) async {
    print('🖨️ (Async) Starting to add optimized photo pages...');
    for (final entry in imageUrlsByCategory.entries) {
      final category = entry.key;
      final imageUrls = entry.value;
      print(
          '📂 (Async) Processing category: $category with ${imageUrls.length} image(s)');
      if (imageUrls.isNotEmpty) {
        final photos = <Uint8List>[];
        for (final url in imageUrls) {
          try {
            if (url.startsWith('http') || url.startsWith('https')) {
              print('🌐 (Async) Downloading image from URL: $url');
              final httpClient = HttpClient();
              final request = await httpClient.getUrl(Uri.parse(url));
              final response = await request.close();
              if (response.statusCode == 200) {
                final bytes =
                    await consolidateHttpClientResponseBytes(response);
                photos.add(bytes);
                print('✅ (Async) Downloaded image from $url');
              } else {
                print(
                    '❌ (Async) Failed to download image from $url (Status: ${response.statusCode})');
              }
            } else {
              print('📁 (Async) Reading local image file: $url');
              final file = File(url);
              if (file.existsSync()) {
                photos.add(file.readAsBytesSync());
                print('✅ (Async) Loaded local image: $url');
              } else {
                print('❌ (Async) Local image file does not exist: $url');
              }
            }
          } catch (e) {
            print('⚠️ (Async) Error loading image: $url, error: $e');
          }
        }

        if (photos.isNotEmpty) {
          print(
              '🖼️ (Async) Adding ${photos.length} photo(s) for category "$category" to PDF...');
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
                    title: _formatFieldLabel(category),
                    photos: pagePhotos,
                    clientName: basicInfo['clientName'] ?? 'N/A',
                    address: basicInfo['address'] ?? 'N/A',
                    state: basicInfo['state'] ?? 'N/A',
                    zipCode: basicInfo['zipCode'] ?? 'N/A',
                    policyNumber: basicInfo['policyNumber'] ?? 'N/A',
                    font: font,
                    boldFont: boldFont,
                    dateOfOrigin: basicInfo['inspectionDate'] ?? 'N/A',
                  );
                },
              ),
            );
            print(
                '📄 (Async) Added photo page for "$category" (${i + 1} - $endIndex)');
          }
        } else {
          print(
              '⚠️ (Async) No valid images found for category "$category". Skipping photo pages.');
        }
      }
    }
    print('✅ (Async) Finished adding optimized photo pages.');
  }

  /// Build optimized photo page with new header
  pw.Widget _buildOptimizedPhotoPage({
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
          typeOfInspection: 'Under-Writing',
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

  /// Build the new header for photo pages
  pw.Widget _buildNewHeader({
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

  /// Build optimized photo grid with 2x2 layout
  pw.Widget _buildOptimizedPhotoGrid(
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

  /// Build styled table from optimized template
  pw.Widget _buildTable(
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

  /// Build styled summary page from optimized template
  pw.Widget _buildSummaryPage({
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
}
