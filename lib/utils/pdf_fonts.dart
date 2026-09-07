import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfFonts {
  static Future<pw.Font> getArabicFont() async {
    // ✅ استخدام خط يدعم اللغة العربية
    final font = await PdfGoogleFonts.cairoRegular();
    return font;
  }

  static Future<pw.Font> getArabicBoldFont() async {
    final font = await PdfGoogleFonts.cairoBold();
    return font;
  }

  static Future<pw.Font> getArabicLightFont() async {
    final font = await PdfGoogleFonts.cairoLight();
    return font;
  }
}