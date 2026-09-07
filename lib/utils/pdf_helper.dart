import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import '../models/worker.dart';
import '../models/client.dart';

class PDFHelper {
  // ==================== تحميل الخطوط ====================

  static Future<pw.Font> _getArabicFont() async {
    try {
      // ✅ استخدام خط Noto Sans Arabic (مفتوح المصدر)
      final byteData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      return pw.Font.ttf(byteData);
    } catch (e) {
      try {
        // ✅ استخدام خط Cairo كبديل
        final byteData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        return pw.Font.ttf(byteData);
      } catch (e2) {
        try {
          // ✅ استخدام خط Noto Naskh Arabic
          final byteData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
          return pw.Font.ttf(byteData);
        } catch (e3) {
          // ✅ استخدام خط Ubuntu (يدعم العربية جزئياً)
          try {
            final byteData = await rootBundle.load('assets/fonts/Ubuntu-R.ttf');
            return pw.Font.ttf(byteData);
          } catch (e4) {
            // ✅ في حالة عدم وجود أي خط، استخدم Helvetica
            return pw.Font.helvetica();
          }
        }
      }
    }
  }

  static Future<pw.Font> _getArabicBoldFont() async {
    try {
      final byteData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
      return pw.Font.ttf(byteData);
    } catch (e) {
      try {
        final byteData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        return pw.Font.ttf(byteData);
      } catch (e2) {
        try {
          final byteData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
          return pw.Font.ttf(byteData);
        } catch (e3) {
          try {
            final byteData = await rootBundle.load('assets/fonts/Ubuntu-B.ttf');
            return pw.Font.ttf(byteData);
          } catch (e4) {
            return pw.Font.helveticaBold();
          }
        }
      }
    }
  }

  // ==================== طباعة تقرير العامل ====================

  static Future<void> printWorkerReport(
      Worker worker,
      DateTime startDate,
      List<Map<String, dynamic>> data,
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
              _buildHeader(
                font,
                boldFont,
                'تقرير العامل',
                'اسم العامل: ${worker.name}',
                'الهاتف: ${worker.phone} | العنوان: ${worker.address}',
                'الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(startDate.add(const Duration(days: 6)))}',
              ),
              pw.SizedBox(height: 20),
              _buildSummaryRow([
                _buildSummaryItem('إجمالي الإنتاج', data[1]['totalProduction'] ?? 0, PdfColors.green, font),
                _buildSummaryItem('إجمالي المصروفات', data[1]['totalExpenses'] ?? 0, PdfColors.red, font),
                _buildSummaryItem('الصافي', data[1]['net'] ?? 0, PdfColors.blue, font),
              ], font),
              pw.SizedBox(height: 20),
              _buildTable(
                font,
                headers: ['التاريخ', 'النوع', 'البيان', 'المبلغ'],
                rows: _buildReportRows(data),
              ),
              pw.SizedBox(height: 20),
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ==================== طباعة كشف حساب العميل ====================

  static Future<void> printClientStatement(Map<String, dynamic> statementData) async {
    final pdf = pw.Document();
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();

    final client = statementData['client'] as Client;
    final transactions = statementData['transactions'] as List;
    final startDate = statementData['startDate'] as DateTime;
    final endDate = statementData['endDate'] as DateTime;
    final openingBalance = (statementData['openingBalance'] ?? 0).toDouble();
    final closingBalance = (statementData['closingBalance'] ?? 0).toDouble();
    final totalInvoices = (statementData['totalInvoices'] ?? 0).toDouble();
    final totalPayments = (statementData['totalPayments'] ?? 0).toDouble();
    final netChange = (statementData['netChange'] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                font,
                boldFont,
                'كشف حساب العميل',
                'الاسم: ${client.name}',
                'الهاتف: ${client.phone} | العنوان: ${client.address} | ${client.isSupplier ? 'مورد' : 'عميل'}',
                'الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}',
              ),
              pw.SizedBox(height: 16),
              _buildSummaryRow([
                _buildSummaryItem('الرصيد الافتتاحي', openingBalance, PdfColors.blue, font),
                _buildSummaryItem('إجمالي الفواتير', totalInvoices, PdfColors.orange, font),
                _buildSummaryItem('إجمالي المدفوعات', totalPayments, PdfColors.green, font),
                _buildSummaryItem('صافي الحركة', netChange, netChange >= 0 ? PdfColors.green : PdfColors.red, font),
                _buildSummaryItem('الرصيد النهائي', closingBalance, closingBalance >= 0 ? PdfColors.green : PdfColors.red, font),
              ], font),
              pw.SizedBox(height: 16),
              _buildTable(
                font,
                headers: ['التاريخ', 'البيان', 'مدين', 'دائن', 'الرصيد'],
                rows: _buildStatementRows(transactions),
              ),
              pw.SizedBox(height: 20),
              _buildFooter(font),
              pw.SizedBox(height: 10),
              _buildSignature(font),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
              _buildHeader(
                font,
                boldFont,
                'كشف حساب العامل',
                'الاسم: ${worker.name}',
                'الهاتف: ${worker.phone} | العنوان: ${worker.address}',
                'الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}',
              ),
              pw.SizedBox(height: 16),
              _buildSummaryRow([
                _buildSummaryItem('الرصيد الافتتاحي', openingBalance, PdfColors.blue, font),
                _buildSummaryItem('إجمالي الإنتاج', totalProduction, PdfColors.green, font),
                _buildSummaryItem('إجمالي المصروفات', totalExpenses, PdfColors.red, font),
                _buildSummaryItem('صافي الربح', netProfit, netProfit >= 0 ? PdfColors.green : PdfColors.red, font),
                _buildSummaryItem('الرصيد النهائي', closingBalance, closingBalance >= 0 ? PdfColors.green : PdfColors.red, font),
              ], font),
              pw.SizedBox(height: 16),
              _buildTable(
                font,
                headers: ['التاريخ', 'البيان', 'مدين', 'دائن', 'الرصيد'],
                rows: _buildWorkerStatementRows(transactions),
              ),
              pw.SizedBox(height: 20),
              _buildFooter(font),
              pw.SizedBox(height: 10),
              _buildSignature(font),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ==================== دوال بناء PDF ====================

  static pw.Widget _buildHeader(
      pw.Font font,
      pw.Font boldFont,
      String title,
      String subTitle1,
      String subTitle2,
      String period,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(subTitle1, style: pw.TextStyle(fontSize: 14, font: font)),
          pw.Text(subTitle2, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey, font: font)),
          pw.Text(period, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey, font: font)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(List<pw.Widget> items, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: items,
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value, PdfColor color, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: font)),
        pw.SizedBox(height: 4),
        pw.Text(
          NumberFormat('#,##0.00').format(value),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: font,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
      pw.Font font, {
        required List<String> headers,
        required List<List<String>> rows,
      }) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: pw.FlexColumnWidth(1)
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((header) {
            return _buildTableCell(header, isHeader: true, font: font);
          }).toList(),
        ),
        ...rows.map((row) {
          return pw.TableRow(
            children: row.map((cell) {
              return _buildTableCell(cell, font: font);
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.Font? font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: font,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static List<List<String>> _buildReportRows(List<Map<String, dynamic>> data) {
    final productions = data[0]['productions'] as List? ?? [];
    final expenses = data[0]['expenses'] as List? ?? [];
    List<List<String>> rows = [];

    for (var prod in productions) {
      rows.add([
        prod['date'] ?? '',
        'إنتاج',
        prod['productName'] ?? '',
        NumberFormat('#,##0.00').format((prod['quantity'] ?? 0) * (prod['price'] ?? 0)),
      ]);
    }

    for (var exp in expenses) {
      rows.add([
        exp['date'] ?? '',
        'مصروف',
        exp['description'] ?? '',
        NumberFormat('#,##0.00').format(exp['amount'] ?? 0),
      ]);
    }

    return rows;
  }

  static List<List<String>> _buildStatementRows(List transactions) {
    List<List<String>> rows = [];

    for (var item in transactions) {
      final date = item['date'] as DateTime;
      final description = item['description'] ?? '';
      final debit = (item['debit'] ?? 0).toDouble();
      final credit = (item['credit'] ?? 0).toDouble();
      final balance = (item['balance'] ?? 0).toDouble();

      rows.add([
        DateFormat('yyyy-MM-dd').format(date),
        description,
        debit > 0 ? NumberFormat('#,##0.00').format(debit) : '',
        credit > 0 ? NumberFormat('#,##0.00').format(credit) : '',
        NumberFormat('#,##0.00').format(balance),
      ]);
    }

    return rows;
  }

  static List<List<String>> _buildWorkerStatementRows(List transactions) {
    List<List<String>> rows = [];

    for (var item in transactions) {
      final date = item['date'] as DateTime;
      final description = item['description'] ?? '';
      final debit = (item['debit'] ?? 0).toDouble();
      final credit = (item['credit'] ?? 0).toDouble();
      final balance = (item['balance'] ?? 0).toDouble();

      String displayDescription = description;
      if (item['type'] == 'production') {
        displayDescription = 'إنتاج ${item['quantity']} قطعة';
      }

      rows.add([
        DateFormat('yyyy-MM-dd').format(date),
        displayDescription,
        debit > 0 ? NumberFormat('#,##0.00').format(debit) : '',
        credit > 0 ? NumberFormat('#,##0.00').format(credit) : '',
        NumberFormat('#,##0.00').format(balance),
      ]);
    }

    return rows;
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  static pw.Widget _buildSignature(pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('توقيع العميل: __________________', style: pw.TextStyle(font: font)),
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
    );
  }

  // ==================== طباعة تقرير العميل ====================

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
              _buildHeader(
                font,
                boldFont,
                'تقرير العميل',
                'الاسم: ${client.name}',
                'الهاتف: ${client.phone} | العنوان: ${client.address}',
                'تاريخ التقرير: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Text('الفواتير:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: font)),
              pw.SizedBox(height: 10),
              if (invoices.isEmpty)
                pw.Text('لا توجد فواتير', style: pw.TextStyle(color: PdfColors.grey, font: font)),
              pw.SizedBox(height: 20),
              pw.Text('المدفوعات:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: font)),
              pw.SizedBox(height: 10),
              if (payments.isEmpty)
                pw.Text('لا توجد مدفوعات', style: pw.TextStyle(color: PdfColors.grey, font: font)),
              pw.SizedBox(height: 20),
              _buildFooter(font),
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