import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_currency.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../utils/number_formatter.dart';

/// مولد فواتير PDF بتصميم فاتح خالٍ من الخلفيات السوداء/الداكنة لتوفير الحبر عند الطباعة.
/// كل العناصر تعتمد على حدود (borders) خفيفة ونص ملوّن بدلاً من التعبئة الكاملة الداكنة.
class PdfGenerator {
  static const _text     = PdfColor.fromInt(0xFF1C1C2E); // نص أساسي غامق (للقراءة فقط، ليس خلفية)
  static const _grey     = PdfColor.fromInt(0xFF8A8A8A);
  static const _lightBg  = PdfColor.fromInt(0xFFFAFAFA);
  static const _border   = PdfColor.fromInt(0xFFE0E0E0);
  static const _white    = PdfColors.white;
  static const _black    = PdfColors.black;

  static Future<Uint8List> generate({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Map<String, String> settings,
    String template = 'template1',
  }) async {
    final pdf = pw.Document();

    final accent = PdfColor.fromInt(int.tryParse(settings['invoice_accent_color'] ?? '') ?? 0xFFE65100);
    final primary = PdfColor.fromInt(int.tryParse(settings['primary_color'] ?? '') ?? 0xFFE65100);
    final showLogo    = (settings['invoice_show_logo']    ?? 'true') == 'true';
    final showPhone2  = (settings['invoice_show_phone2']  ?? 'true') == 'true';
    final showAddress = (settings['invoice_show_address'] ?? 'true') == 'true';
    final showWebsite = (settings['invoice_show_website'] ?? 'true') == 'true';
    final showEmail   = (settings['invoice_show_email']   ?? 'true') == 'true';
    final showNotes   = (settings['invoice_show_notes']   ?? 'true') == 'true';
    final headerText  = settings['invoice_header_text'] ?? '';
    final footerText  = (settings['invoice_footer_text'] ?? '').isNotEmpty
        ? settings['invoice_footer_text']!
        : 'شكراً لتعاملكم مع ${settings['company_name'] ?? 'مطبعة شمس للدعاية والإعلان'}';

    pw.Font? arabicFont;
    pw.Font? arabicFontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      arabicFont = pw.Font.ttf(fontData);
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      arabicFontBold = pw.Font.ttf(boldData);
    } catch (_) {
      arabicFont = pw.Font.helvetica();
      arabicFontBold = pw.Font.helveticaBold();
    }

    pw.MemoryImage? logoImage;
    final logoPath = settings['logo_path'] ?? '';
    if (showLogo && logoPath.isNotEmpty) {
      try {
        final bytes = File(logoPath).readAsBytesSync();
        logoImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (ctx) => [
          _buildHeader(invoice, settings, logoImage, arabicFontBold!,
              accent: accent, primary: primary, showPhone2: showPhone2, showAddress: showAddress, showWebsite: showWebsite),
          if (headerText.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _white,
                border: pw.Border.all(color: accent, width: 0.6),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(headerText, style: pw.TextStyle(font: arabicFont, fontSize: 10, color: _text)),
            ),
          ],
          pw.SizedBox(height: 16),
          _buildCustomerInfo(invoice, arabicFont!, arabicFontBold, accent: accent, primary: primary),
          pw.SizedBox(height: 16),
          _buildItemsTable(items, arabicFont, arabicFontBold, primary: primary, invoiceCurrency: invoice.currency),
          pw.SizedBox(height: 12),
          _buildTotals(invoice, arabicFont, arabicFontBold, primary: primary, accent: accent, showEmail: showEmail),
          if (showNotes && (invoice.notes ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotes(invoice.notes!, arabicFont, accent: accent),
          ],
          pw.SizedBox(height: 20),
          _buildFooter(footerText, arabicFont, showEmail: showEmail, email: settings['email'] ?? ''),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Invoice inv, Map<String, String> s,
      pw.MemoryImage? logo, pw.Font boldFont,
      {required PdfColor accent, required PdfColor primary, required bool showPhone2, required bool showAddress, required bool showWebsite}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        border: pw.Border.all(color: primary, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  s['company_name'] ?? 'مطبعة شمس للدعاية والإعلان',
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: primary),
                ),
                pw.SizedBox(height: 6),
                if ((s['phone1'] ?? '').isNotEmpty) _infoRow('هاتف:', s['phone1']!, boldFont),
                if (showPhone2 && (s['phone2'] ?? '').isNotEmpty) _infoRow('هاتف:', s['phone2']!, boldFont),
                if (showAddress && (s['address'] ?? '').isNotEmpty) _infoRow('العنوان:', s['address']!, boldFont),
                if (showWebsite && (s['website'] ?? '').isNotEmpty) _infoRow('الموقع:', s['website']!, boldFont),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // الشعار دائري الشكل دائماً (سواء صورة المستخدم أو الحرف الافتراضي)
              if (logo != null)
                pw.ClipOval(
                  child: pw.Container(
                    width: 70,
                    height: 70,
                    color: _white,
                    child: pw.Image(logo, fit: pw.BoxFit.cover),
                  ),
                )
              else
                pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: primary, width: 1.5),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('شمس',
                      style: pw.TextStyle(font: boldFont, color: primary, fontSize: 15)),
                ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _white,
                  border: pw.Border.all(color: primary, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text('فاتورة',
                    style: pw.TextStyle(font: boldFont, color: primary, fontSize: 13)),
              ),
              pw.SizedBox(height: 6),
              pw.Text('# ${inv.invoiceNumber}',
                  style: pw.TextStyle(font: boldFont, color: accent, fontSize: 12)),
              pw.Text(NumberFormatter.date(inv.createdAt),
                  style: const pw.TextStyle(color: _grey, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String text, pw.Font bold) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3),
        child: pw.Text(
          '$label $text',
          style: const pw.TextStyle(color: _grey, fontSize: 9),
        ),
      );

  static pw.Widget _buildCustomerInfo(Invoice inv, pw.Font font, pw.Font boldFont, {required PdfColor accent, required PdfColor primary}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: accent, width: 0.6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('العميل:',
                    style: pw.TextStyle(font: boldFont, color: _text, fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(inv.customerName,
                    style: pw.TextStyle(font: boldFont, color: primary, fontSize: 14)),
                if ((inv.customerPhone ?? '').isNotEmpty)
                  pw.Text(inv.customerPhone!,
                      style: const pw.TextStyle(color: _grey, fontSize: 9)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _badge(inv.invoiceType == 'wholesale' ? 'حساب جملة' : 'حساب مفرد',
                  inv.invoiceType == 'wholesale' ? primary : accent, boldFont),
              pw.SizedBox(height: 6),
              _badge(_statusLabel(inv.status), _statusColor(inv.status), boldFont),
            ],
          ),
        ],
      ),
    );
  }

  /// شارة بحدود ملونة ونص ملوّن بدل التعبئة الكاملة، توفيراً للحبر عند الطباعة
  static pw.Widget _badge(String label, PdfColor color, pw.Font bold) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _white,
          border: pw.Border.all(color: color, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        ),
        child: pw.Text(label,
            style: pw.TextStyle(font: bold, color: color, fontSize: 9)),
      );

  static pw.Widget _buildItemsTable(List<InvoiceItem> items, pw.Font font, pw.Font boldFont, {required PdfColor primary, required String invoiceCurrency}) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.6),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.3),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightBg, border: pw.Border(bottom: pw.BorderSide(color: primary, width: 1.2))),
          children: ['#', 'المادة / الخدمة', 'حجم الطباعة', 'العدد', 'سعر الوحدة', 'الإجمالي']
              .map((h) => _cell(h, boldFont, color: _text, isHeader: true))
              .toList(),
        ),
        ...items.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final symbol = AppCurrency.symbol(item.currency);
          final sizeLabel = (item.width != null && item.height != null)
              ? '${NumberFormatter.compact(item.width!)}×${NumberFormatter.compact(item.height!)}'
              : '-';
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: idx.isOdd ? _lightBg : _white),
            children: [
              _cell('${idx + 1}', font),
              _cell(item.itemName, boldFont, align: pw.Alignment.centerRight),
              _cell(sizeLabel, font),
              _cell(NumberFormatter.compact(item.quantity), font),
              _cell('${NumberFormatter.compact(item.unitPrice)} $symbol', font),
              _cell('${NumberFormatter.compact(item.totalPrice)} $symbol', boldFont, color: primary),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String t, pw.Font font,
      {PdfColor? color, bool isHeader = false, pw.Alignment? align}) {
    return pw.Container(
      alignment: align ?? pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        t,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 9, color: color ?? _black),
      ),
    );
  }

  static pw.Widget _buildTotals(Invoice inv, pw.Font font, pw.Font boldFont,
      {required PdfColor primary, required PdfColor accent, required bool showEmail}) {
    final symbol = AppCurrency.symbol(inv.currency);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            children: [
              _totalRow('المجموع الفرعي', '${NumberFormatter.compact(inv.subtotal)} $symbol', font, boldFont),
              if (inv.discountAmount > 0) ...[
                pw.Divider(color: _border),
                _totalRow(
                  inv.discountPercent > 0
                      ? 'خصم (${NumberFormatter.compact(inv.discountPercent)}%)'
                      : 'خصم',
                  '- ${NumberFormatter.compact(inv.discountAmount)} $symbol',
                  font,
                  boldFont,
                  valueColor: primary,
                ),
              ],
              if (inv.paidAmount > 0) ...[
                pw.Divider(color: _border),
                _totalRow('المدفوع', '${NumberFormatter.compact(inv.paidAmount)} $symbol', font, boldFont, valueColor: const PdfColor.fromInt(0xFF2E7D32)),
                if (inv.remainingAmount > 0)
                  _totalRow('المتبقي', '${NumberFormatter.compact(inv.remainingAmount)} $symbol', font, boldFont, valueColor: const PdfColor.fromInt(0xFFD32F2F)),
              ],
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _white,
                  border: pw.Border.all(color: primary, width: 1.2),
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(8),
                    bottomRight: pw.Radius.circular(8),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الإجمالي',
                        style: pw.TextStyle(font: boldFont, color: _text, fontSize: 12)),
                    pw.Text('${NumberFormatter.compact(inv.total)} $symbol',
                        style: pw.TextStyle(font: boldFont, color: primary, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, pw.Font font, pw.Font boldFont,
      {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
          pw.Text(value,
              style: pw.TextStyle(font: boldFont, fontSize: 10, color: valueColor ?? _text)),
        ],
      ),
    );
  }

  static pw.Widget _buildNotes(String notes, pw.Font font, {required PdfColor accent}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: accent, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ملاحظات:',
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
          pw.SizedBox(height: 4),
          pw.Text(notes,
              style: pw.TextStyle(font: font, fontSize: 10, color: _text)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String footerText, pw.Font font, {required bool showEmail, required String email}) {
    return pw.Column(
      children: [
        pw.Divider(color: _border),
        pw.SizedBox(height: 6),
        pw.Text(
          footerText,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
        ),
        if (showEmail && email.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(email, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 8, color: _grey)),
        ],
      ],
    );
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'paid':     return 'مدفوعة';
      case 'partial':  return 'مدفوعة جزئياً';
      case 'canceled': return 'ملغاة';
      default:         return 'معلقة';
    }
  }

  static PdfColor _statusColor(String s) {
    switch (s) {
      case 'paid':     return const PdfColor.fromInt(0xFF2E7D32);
      case 'partial':  return const PdfColor.fromInt(0xFF0277BD);
      case 'canceled': return const PdfColor.fromInt(0xFFC62828);
      default:         return const PdfColor.fromInt(0xFFE65100);
    }
  }

  static Future<String> saveToFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'ShamsPrinting', 'PDFs'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final file = File(p.join(folder.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
