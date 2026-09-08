import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/worker.dart';
import '../models/client.dart';

class PDFHelper {
  // ==================== تحميل الخطوط ====================

  static Future<pw.Font> _getArabicFont() async {
    try {
      // ✅ تحميل خط Noto Naskh Arabic من assets
      final byteData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      return pw.Font.ttf(byteData);
    } catch (e) {
      try {
        // ✅ محاولة استخدام خط Cairo
        final byteData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        return pw.Font.ttf(byteData);
      } catch (e2) {
        try {
          // ✅ محاولة استخدام خط Noto Sans Arabic
          final byteData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
          return pw.Font.ttf(byteData);
        } catch (e3) {
          // ✅ في حالة عدم وجود خط، استخدم Helvetica
          return pw.Font.helvetica();
        }
      }
    }
  }

  static Future<pw.Font> _getArabicBoldFont() async {
    try {
      final byteData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      return pw.Font.ttf(byteData);
    } catch (e) {
      try {
        final byteData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        return pw.Font.ttf(byteData);
      } catch (e2) {
        try {
          final byteData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
          return pw.Font.ttf(byteData);
        } catch (e3) {
          return pw.Font.helveticaBold();
        }
      }
    }
  }

  // ==================== طباعة كشف حساب العامل ====================

  static Future<void> printWorkerStatement(Map<String, dynamic> statementData) async {
    final pdf = pw.Document();
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();

    final worker = statementData['worker'] as Worker;
    final transactions = statementData['transactions'] as List;
    final startDate = statementData['startDate'] as DateTime;
    final endDate = statementData['endDate'] as DateTime;
    final openingBalance = (statementData['openingBalance'] ?? 0).toDouble();
    final closingBalance = (statementData['closingBalance'] ?? 0).toDouble();
    final totalProduction = (statementData['totalProduction'] ?? 0).toDouble();
    final totalExpenses = (statementData['totalExpenses'] ?? 0).toDouble();
    final netProfit = (statementData['netProfit'] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ✅ العنوان
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'كشف حساب العامل',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'الاسم: ${worker.name}',
                      style: pw.TextStyle(fontSize: 16, font: font),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'الهاتف: ${worker.phone} | العنوان: ${worker.address}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey, font: font),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey, font: font),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ✅ الملخص
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('الرصيد الافتتاحي', openingBalance, PdfColors.blue, font),
                    _buildSummaryItem('إجمالي الإنتاج', totalProduction, PdfColors.green, font),
                    _buildSummaryItem('إجمالي المصروفات', totalExpenses, PdfColors.red, font),
                    _buildSummaryItem('صافي الربح', netProfit, netProfit >= 0 ? PdfColors.green : PdfColors.red, font),
                    _buildSummaryItem('الرصيد النهائي', closingBalance, closingBalance >= 0 ? PdfColors.green : PdfColors.red, font),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ✅ جدول الحركات
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.5),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.5),
                },
                children: [
                  // ✅ رأس الجدول
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildHeaderCell('التاريخ', font),
                      _buildHeaderCell('البيان', font),
                      _buildHeaderCell('مدين', font),
                      _buildHeaderCell('دائن', font),
                      _buildHeaderCell('الرصيد', font),
                    ],
                  ),
                  // ✅ الحركات
                  ...transactions.map((item) {
                    final date = item['date'] as DateTime;
                    final description = item['description'] ?? '';
                    final debit = (item['debit'] ?? 0).toDouble();
                    final credit = (item['credit'] ?? 0).toDouble();
                    final balance = (item['balance'] ?? 0).toDouble();

                    // ✅ تنسيق الوصف
                    String displayDescription = description;
                    if (item['type'] == 'production') {
                      displayDescription = 'إنتاج ${item['quantity']} قطعة';
                    }

                    return pw.TableRow(
                      children: [
                        _buildCell(DateFormat('yyyy-MM-dd').format(date), font),
                        _buildCell(displayDescription, font),
                        _buildCell(debit > 0 ? NumberFormat('#,##0.00').format(debit) : '', font),
                        _buildCell(credit > 0 ? NumberFormat('#,##0.00').format(credit) : '', font),
                        _buildCell(NumberFormat('#,##0.00').format(balance), font),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // ✅ التذييل
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'تم الإنشاء بواسطة نظام إدارة العمال والعملاء',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: font),
              ),
              pw.Text(
                'تاريخ الطباعة: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: font),
              ),
              pw.SizedBox(height: 10),

              // ✅ التوقيع
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('توقيع العامل: __________________', style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 4),
                      pw.Text('الاسم: __________________', style: pw.TextStyle(font: font)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('توقيع المحاسب: __________________', style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 4),
                      pw.Text('الاسم: __________________', style: pw.TextStyle(font: font)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ==================== دوال مساعدة ====================

  static pw.Widget _buildSummaryItem(String label, double value, PdfColor color, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey, font: font)),
        pw.SizedBox(height: 2),
        pw.Text(
          NumberFormat('#,##0.00').format(value),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: font,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
          font: font,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, font: font),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ==================== دوال أخرى (للتوافق) ====================

  static Future<void> printWorkerReport(
      Worker worker,
      DateTime startDate,
      List<Map<String, dynamic>> data,
      ) async {
    // تنفيذ مبسط
    final pdf = pw.Document();
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'تقرير العامل',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.Text('اسم العامل: ${worker.name}', style: pw.TextStyle(font: font)),
              pw.Text('الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)}', style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text('تم إنشاء التقرير بنجاح', style: pw.TextStyle(font: font)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> printClientStatement(Map<String, dynamic> statementData) async {
    // تنفيذ مبسط
    final pdf = pw.Document();
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();

    final client = statementData['client'] as Client;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'كشف حساب العميل',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.Text('الاسم: ${client.name}', style: pw.TextStyle(font: font)),
              pw.Text('الهاتف: ${client.phone}', style: pw.TextStyle(font: font)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> printClientReport(
      Client client,
      List<dynamic> invoices,
      List<dynamic> payments,
      ) async {
    final pdf = pw.Document();
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'تقرير العميل',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.Text('الاسم: ${client.name}', style: pw.TextStyle(font: font)),
              pw.Text('تاريخ التقرير: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: pw.TextStyle(font: font)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}