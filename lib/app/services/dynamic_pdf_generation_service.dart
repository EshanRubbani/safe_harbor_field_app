import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';
import 'package:safe_harbor_field_app/app/models/inspection_report_model.dart';

class DynamicPDFGenerationService extends GetxService {
  final QuestionnaireService _questionnaireService =
      Get.find<QuestionnaireService>();

  // Cache for fonts and assets
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static Uint8List? _logoImage;

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
  }

  /// Generate PDF from report data dynamically
  Future<Uint8List> generateDynamicPDF({
    required Map<String, dynamic> questionnaireResponses,
    required Map<String, List<String>> imageUrlsByCategory,
    String? summary,
  }) async {
    await _initializeAssets();

    final pdf = pw.Document();
    final font = _regularFont!;
    final boldFont = _boldFont!;

    // Extract basic info from questionnaire responses
    final basicInfo = _extractBasicInfo(questionnaireResponses);

    // Generate cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildDynamicCoverPage(
            basicInfo: basicInfo,
            font: font,
            boldFont: boldFont,
          );
        },
      ),
    );

    // Generate photo pages dynamically
    _addDynamicPhotoPages(pdf, imageUrlsByCategory, basicInfo, font, boldFont);

    // Generate questionnaire sections dynamically
    _addDynamicQuestionnaireSections(
        pdf, questionnaireResponses, font, boldFont);

    // Generate summary page if provided
    if (summary != null && summary.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildDynamicSummaryPage(
              responses: questionnaireResponses,
              summary: summary,
              font: font,
              boldFont: boldFont,
            );
          },
        ),
      );
    }

    return pdf.save();
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
      padding: const pw.EdgeInsets.all(40),
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

  /// Add dynamic questionnaire sections
  void _addDynamicQuestionnaireSections(
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

    // Generate pages for each section
    sectionMap.forEach((sectionName, questions) {
      if (questions.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return _buildQuestionnaireSectionPage(
                sectionName: sectionName,
                questions: questions,
                font: font,
                boldFont: boldFont,
              );
            },
          ),
        );
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
}
