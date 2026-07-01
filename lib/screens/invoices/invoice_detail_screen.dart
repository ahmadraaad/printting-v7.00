import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/number_formatter.dart';
import '../../utils/pdf_generator.dart';
import '../../widgets/status_badge.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _loading = true;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inv = await context.read<InvoiceProvider>().getWithItems(widget.invoiceId);
    if (mounted) setState(() { _invoice = inv; _loading = false; });
  }

  Map<String, String> _getSettings() {
    final s = context.read<SettingsProvider>();
    return {
      'company_name': s.companyName,
      'phone1': s.phone1,
      'phone2': s.phone2,
      'address': s.address,
      'website': s.website,
      'email': s.email,
      'logo_path': s.logoPath,
      'invoice_accent_color': s.invoiceAccentColor,
      'invoice_header_text': s.invoiceHeaderText,
      'invoice_footer_text': s.invoiceFooterText,
      'invoice_show_phone2': s.invoiceShowPhone2.toString(),
      'invoice_show_address': s.invoiceShowAddress.toString(),
      'invoice_show_website': s.invoiceShowWebsite.toString(),
      'invoice_show_email': s.invoiceShowEmail.toString(),
      'invoice_show_logo': s.invoiceShowLogo.toString(),
      'invoice_show_notes': s.invoiceShowNotes.toString(),
    };
  }

  Future<void> _printInvoice() async {
    if (_invoice == null) return;
    setState(() => _pdfLoading = true);
    try {
      final bytes = await PdfGenerator.generate(invoice: _invoice!, items: _invoice!.items, settings: _getSettings());
      if (!mounted) return;
      setState(() => _pdfLoading = false);
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      if (mounted) {
        setState(() => _pdfLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذرت طباعة الفاتورة: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<String?> _savePdf() async {
    if (_invoice == null) return null;
    setState(() => _pdfLoading = true);
    try {
      final bytes = await PdfGenerator.generate(invoice: _invoice!, items: _invoice!.items, settings: _getSettings());
      final path = await PdfGenerator.saveToFile(bytes, 'invoice_${_invoice!.invoiceNumber}.pdf');
      if (mounted) setState(() => _pdfLoading = false);
      return path;
    } catch (e) {
      if (mounted) {
        setState(() => _pdfLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذر حفظ الفاتورة: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ));
      }
      return null;
    }
  }

  Future<void> _exportPdf() async {
    final path = await _savePdf();
    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم حفظ الفاتورة: $path', style: const TextStyle(fontFamily: 'Cairo')),
        action: SnackBarAction(label: 'فتح', onPressed: () => launchUrl(Uri.file(path))),
      ));
    }
  }

  Future<void> _sendWhatsapp() async {
    final path = await _savePdf();
    if (path == null) return;
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('فاتورة رقم ${_invoice!.invoiceNumber} من مطبعة شمس للدعاية والإعلان')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الملف:\n$path', style: const TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_invoice == null) {
      return const Scaffold(body: Center(child: Text('لم يتم العثور على الفاتورة', style: TextStyle(fontFamily: 'Cairo'))));
    }

    final inv = _invoice!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text('فاتورة # ${inv.invoiceNumber}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          if (_pdfLoading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: AppStrings.edit,
              onPressed: () async {
                final full = await context.read<InvoiceProvider>().getWithItems(inv.id!);
                if (!mounted) return;
                await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInvoiceScreen(invoice: full)));
                _load();
              },
            ),
            IconButton(icon: const Icon(Icons.print_rounded), tooltip: AppStrings.print, onPressed: _printInvoice),
            IconButton(icon: const Icon(Icons.picture_as_pdf_rounded), tooltip: AppStrings.exportPDF, onPressed: _exportPdf),
            IconButton(icon: const Icon(Icons.chat_rounded), tooltip: AppStrings.sendWhatsApp, onPressed: _sendWhatsapp),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: _InfoCard(inv)), const SizedBox(width: 20), _TotalsCard(inv)],
            ),
            const SizedBox(height: 20),
            _PaymentCard(invoice: inv, onChanged: _load),
            const SizedBox(height: 20),
            _ItemsTable(inv.items),
            if ((inv.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(inv.notes!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13), textDirection: TextDirection.rtl)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Invoice inv;
  const _InfoCard(this.inv);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('فاتورة رقم: ', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 12)),
              Text(inv.invoiceNumber, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16, color: primary)),
              const SizedBox(width: 12),
              StatusBadge(inv.status),
            ],
          ),
          const SizedBox(height: 12),
          _R('العميل', inv.customerName),
          if ((inv.customerPhone ?? '').isNotEmpty) _R('الهاتف', inv.customerPhone!),
          _R('نوع الحساب', inv.isWholesale ? AppStrings.wholesale : AppStrings.retail),
          _R('العملة', '${AppCurrency.label(inv.currency)} (${AppCurrency.symbol(inv.currency)})'),
          _R('التاريخ', NumberFormatter.date(inv.createdAt)),
        ],
      ),
    );
  }

  Widget _R(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text('$l: ', style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 12)),
            Flexible(child: Text(v, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          ],
        ),
      );
}

class _TotalsCard extends StatelessWidget {
  final Invoice inv;
  const _TotalsCard(this.inv);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _TR(AppStrings.subtotal, '${NumberFormatter.compact(inv.subtotal)} ${AppCurrency.symbol(inv.currency)}'),
          if (inv.discountAmount > 0) ...[
            const Divider(height: 16),
            _TR('الخصم', '- ${NumberFormatter.compact(inv.discountAmount)} ${AppCurrency.symbol(inv.currency)}', vc: AppColors.primary),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(AppStrings.total, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${NumberFormatter.compact(inv.total)} ${AppCurrency.symbol(inv.currency)}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 18, color: primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _TR(String l, String v, {Color? vc}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 12)),
          Text(v, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13, color: vc)),
        ],
      );
}

class _PaymentCard extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback onChanged;
  const _PaymentCard({required this.invoice, required this.onChanged});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.invoice.paidAmount.toString());
  }

  @override
  void didUpdateWidget(covariant _PaymentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) _ctrl.text = widget.invoice.paidAmount.toString();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_ctrl.text) ?? 0;
    setState(() => _saving = true);
    await context.read<InvoiceProvider>().setPayment(widget.invoice.id!, amount);
    setState(() { _saving = false; _editing = false; });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullyPaid = inv.isFullyPaid;
    final color = inv.status == 'canceled'
        ? AppColors.statusCanceled
        : fullyPaid
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(fullyPaid ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.paidAmount, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                _editing
                    ? SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _ctrl,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          autofocus: true,
                          decoration: const InputDecoration(isDense: true),
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                        ),
                      )
                    : Text('${NumberFormatter.compact(inv.paidAmount)} ${AppCurrency.symbol(inv.currency)}',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.remainingAmount, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  fullyPaid ? AppStrings.fullyPaid : '${NumberFormatter.compact(inv.remainingAmount)} ${AppCurrency.symbol(inv.currency)}',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 16, color: color),
                ),
              ],
            ),
          ),
          if (inv.status != 'canceled')
            _editing
                ? Row(
                    children: [
                      if (_saving)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      else ...[
                        IconButton(icon: const Icon(Icons.check_rounded, color: AppColors.success), onPressed: _save),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.error),
                          onPressed: () => setState(() { _editing = false; _ctrl.text = inv.paidAmount.toString(); }),
                        ),
                      ],
                    ],
                  )
                : OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(AppStrings.registerPayment, style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  ),
        ],
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  final List<InvoiceItem> items;
  const _ItemsTable(this.items);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(AppStrings.invoiceItems, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.withOpacity(0.06),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _H('المادة / الخدمة')),
                Expanded(flex: 2, child: _H('الوحدة')),
                Expanded(flex: 2, child: _H('حجم الطباعة')),
                Expanded(flex: 1, child: _H('العدد')),
                Expanded(flex: 2, child: _H('السعر')),
                Expanded(flex: 2, child: _H('الإجمالي')),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final sizeLabel = (item.width != null && item.height != null)
                ? '${NumberFormatter.compact(item.width!)}×${NumberFormatter.compact(item.height!)}'
                : '-';
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: i.isOdd ? Colors.grey.withOpacity(0.03) : null,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(item.itemName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 2, child: Text(item.unit, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 12))),
                      Expanded(flex: 2, child: Text(sizeLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                      Expanded(flex: 1, child: Text(NumberFormatter.compact(item.quantity), style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text('${NumberFormatter.compact(item.unitPrice)} ${AppCurrency.symbol(item.currency)}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                      Expanded(
                        flex: 2,
                        child: Text('${NumberFormatter.compact(item.totalPrice)} ${AppCurrency.symbol(item.currency)}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13, color: primary)),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textMuted));
}
