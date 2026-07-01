import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/item.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/number_formatter.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;
  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late final TextEditingController _notes;
  late final TextEditingController _discountPct;
  late final TextEditingController _discountAmt;

  Customer? _customer;
  String _invoiceType = 'retail';
  // عملة الفاتورة دائماً دينار عراقي ثابتة - أي صنف بعملة دولار يتحول تلقائياً لها
  final String _invoiceCurrency = AppCurrency.iqd;
  String _invoiceNumber = '';
  final List<_LineState> _lines = [];
  bool _loading = false;

  bool get isEdit => widget.invoice != null;

  double get _exchangeRate => context.read<SettingsProvider>().exchangeRateUsdIqd;

  @override
  void initState() {
    super.initState();
    _notes       = TextEditingController(text: widget.invoice?.notes ?? '');
    _discountPct = TextEditingController(text: (widget.invoice?.discountPercent ?? 0) == 0 ? '' : widget.invoice!.discountPercent.toString());
    _discountAmt = TextEditingController(text: (widget.invoice?.discountAmount  ?? 0) == 0 ? '' : widget.invoice!.discountAmount.toString());

    if (isEdit) {
      _invoiceType     = widget.invoice!.invoiceType;
      _invoiceNumber   = widget.invoice!.invoiceNumber;
      for (final i in widget.invoice!.items) {
        _lines.add(_LineState.fromInvoiceItem(i));
      }
      // نبحث عن العميل المرتبط بالفاتورة (عبر معرّفه) لنعرضه في القائمة بدلاً من "عميل عابر"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final custId = widget.invoice!.customerId;
        if (custId != null) {
          final customers = context.read<CustomerProvider>().customers;
          Customer? match;
          for (final c in customers) {
            if (c.id == custId) { match = c; break; }
          }
          if (match != null) setState(() => _customer = match);
        }
      });
    }
    _generateNumber();
  }

  Future<void> _generateNumber() async {
    if (isEdit) return;
    final n = await context.read<InvoiceProvider>().nextNumber();
    if (mounted) setState(() => _invoiceNumber = n);
  }

  @override
  void dispose() {
    _notes.dispose(); _discountPct.dispose(); _discountAmt.dispose();
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  /// إجمالي كل بند محوّلاً لعملة الفاتورة الحالية
  double _lineTotalInInvoiceCurrency(_LineState l) =>
      AppCurrency.convert(l.totalPrice, l.currency, _invoiceCurrency, _exchangeRate);

  double get _subtotal => _lines.fold(0, (s, l) => s + _lineTotalInInvoiceCurrency(l));

  double get _discountAmount {
    final a = double.tryParse(_discountAmt.text) ?? 0;
    if (a > 0) return a;
    final p = double.tryParse(_discountPct.text) ?? 0;
    return p > 0 ? _subtotal * p / 100 : 0;
  }

  double get _total => _subtotal - _discountAmount;

  Future<void> _submit() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف بنداً واحداً على الأقل', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _loading = true);

    final prov = context.read<InvoiceProvider>();
    final discPct = double.tryParse(_discountPct.text) ?? 0;

    // إذا كنا نعدّل فاتورة موجودة ولم يتم اختيار عميل جديد بشكل صريح من القائمة،
    // نحافظ على اسم/رقم هاتف العميل الأصليين بدلاً من استبدالهما بـ "عميل عابر"
    final String resolvedName = _customer?.name ??
        (isEdit ? widget.invoice!.customerName : AppStrings.walkInCustomer);
    final String? resolvedPhone = _customer?.phone ??
        (isEdit ? widget.invoice!.customerPhone : null);
    final int? resolvedCustomerId = _customer?.id ??
        (isEdit ? widget.invoice!.customerId : null);

    final invoice = Invoice(
      id: widget.invoice?.id,
      invoiceNumber: _invoiceNumber,
      customerId: resolvedCustomerId,
      customerName: resolvedName,
      customerPhone: resolvedPhone,
      invoiceType: _invoiceType,
      subtotal: _subtotal,
      discountPercent: discPct,
      discountAmount: _discountAmount,
      total: _total,
      paidAmount: widget.invoice?.paidAmount ?? 0,
      currency: _invoiceCurrency,
      exchangeRate: _exchangeRate,
      notes: _notes.text.trim(),
      status: widget.invoice?.status ?? 'pending',
    );

    // البنود تُحفظ بقيمها الأصلية (totalPrice/unitPrice بعملتها الأصلية) مع تسجيل تلك العملة،
    // لكن مجموع الفاتورة (subtotal/total) محسوب بعملة الفاتورة الموحّدة.
    final items = _lines.map((l) => l.toInvoiceItem()).toList();

    bool ok;
    if (isEdit) {
      ok = await prov.update(invoice, items);
    } else {
      ok = await prov.create(invoice, items) != null;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? AppStrings.saveSuccess : AppStrings.errorOccurred, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: ok ? null : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل الفاتورة' : AppStrings.newInvoice, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
              label: const Text(AppStrings.save),
            ),
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'معلومات الفاتورة',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: AppStrings.invoiceNumber,
                              child: TextFormField(
                                initialValue: _invoiceNumber,
                                readOnly: true,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: primary),
                                decoration: const InputDecoration(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LabeledField(
                              label: AppStrings.invoiceDate,
                              child: TextFormField(
                                initialValue: NumberFormatter.todayDate(),
                                readOnly: true,
                                decoration: const InputDecoration(),
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _LabeledField(
                            label: AppStrings.invoiceType,
                            child: _TypeToggle(value: _invoiceType, onChanged: (v) => setState(() => _invoiceType = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CustomerSelector(selected: _customer, onChanged: (c) => setState(() => _customer = c)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: AppStrings.invoiceItems,
                    trailing: ElevatedButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(AppStrings.addInvoiceItem),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    ),
                    children: [
                      if (_lines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('اضغط "+ إضافة بند" لإضافة عناصر للفاتورة', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo')),
                          ),
                        )
                      else ...[
                        _ItemsTableHeader(invoiceCurrency: _invoiceCurrency),
                        const Divider(height: 16),
                        ...List.generate(_lines.length, (i) => Column(
                              children: [
                                _InvoiceLineRow(
                                  line: _lines[i],
                                  invoiceType: _invoiceType,
                                  invoiceCurrency: _invoiceCurrency,
                                  exchangeRate: _exchangeRate,
                                  onChanged: () => setState(() {}),
                                  onDelete: () => setState(() => _lines.removeAt(i)),
                                ),
                                if (i < _lines.length - 1) const Divider(height: 8),
                              ],
                            )),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: AppStrings.notes,
                    children: [
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(hintText: 'ملاحظات إضافية للفاتورة...'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 280,
            height: double.infinity,
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ملخص الفاتورة',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('العملة: ${AppCurrency.label(_invoiceCurrency)} (${AppCurrency.symbol(_invoiceCurrency)})',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 20),
                  _TotalRow(label: AppStrings.subtotal, value: '${NumberFormatter.compact(_subtotal)} ${AppCurrency.symbol(_invoiceCurrency)}'),
                  const SizedBox(height: 16),
                  const Text(AppStrings.discountPercent, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _discountPct,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(suffixText: '%', isDense: true),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 12),
                  const Text(AppStrings.discountAmount, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _discountAmt,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(isDense: true),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 12),
                    _TotalRow(label: 'الخصم', value: '- ${NumberFormatter.compact(_discountAmount)} ${AppCurrency.symbol(_invoiceCurrency)}', valueColor: AppColors.primary),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.total, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
                        Text('${NumberFormatter.compact(_total)} ${AppCurrency.symbol(_invoiceCurrency)}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 18, color: primary)),
                      ],
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

  void _addLine() => setState(() => _lines.add(_LineState(defaultCurrency: _invoiceCurrency)));
}

class _LineState {
  Item? item;
  final TextEditingController nameCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  String unit;
  String currency;

  _LineState({String defaultCurrency = 'IQD'})
      : nameCtrl  = TextEditingController(),
        widthCtrl = TextEditingController(),
        heightCtrl= TextEditingController(),
        qtyCtrl   = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(),
        unit      = 'عدد',
        currency  = defaultCurrency;

  factory _LineState.fromInvoiceItem(InvoiceItem i) {
    final l = _LineState(defaultCurrency: i.currency);
    l.nameCtrl.text   = i.itemName;
    l.widthCtrl.text  = i.width?.toString()    ?? '';
    l.heightCtrl.text = i.height?.toString()   ?? '';
    l.qtyCtrl.text    = i.quantity.toString();
    l.priceCtrl.text  = i.unitPrice.toString();
    l.unit = i.unit;
    return l;
  }

  double get width    => double.tryParse(widthCtrl.text)  ?? 0;
  double get height   => double.tryParse(heightCtrl.text) ?? 0;
  double get quantity => double.tryParse(qtyCtrl.text)    ?? 1;
  double get unitPrice=> double.tryParse(priceCtrl.text)  ?? 0;

  bool get needsDimensions => unit == 'متر مربع (m²)' || unit == 'متر (m)' || unit == 'سم (cm)' || unit == 'ملم (mm)';

  double? get areaSqm => needsDimensions ? InvoiceItem.calcArea(width, height, unit) : null;

  /// الإجمالي بعملة البند نفسه (قبل أي تحويل لعملة الفاتورة)
  double get totalPrice => InvoiceItem.calcTotal(
        unit: unit,
        width: needsDimensions ? width : null,
        height: needsDimensions ? height : null,
        quantity: quantity,
        unitPrice: unitPrice,
      );

  void applyItem(Item i, bool isWholesale) {
    item = i;
    nameCtrl.text  = i.name;
    priceCtrl.text = (isWholesale ? i.wholesalePrice : i.retailPrice).toString();
    unit           = i.unit;
    currency       = i.currency;
  }

  InvoiceItem toInvoiceItem() => InvoiceItem(
        itemId: item?.id,
        itemName: nameCtrl.text.trim(),
        unit: unit,
        width: needsDimensions ? width : null,
        height: needsDimensions ? height : null,
        quantity: quantity,
        areaSqm: areaSqm,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        currency: currency,
      );

  void dispose() {
    nameCtrl.dispose(); widthCtrl.dispose(); heightCtrl.dispose();
    qtyCtrl.dispose(); priceCtrl.dispose();
  }
}

class _InvoiceLineRow extends StatefulWidget {
  final _LineState line;
  final String invoiceType;
  final String invoiceCurrency;
  final double exchangeRate;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _InvoiceLineRow({
    required this.line,
    required this.invoiceType,
    required this.invoiceCurrency,
    required this.exchangeRate,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_InvoiceLineRow> createState() => _InvoiceLineRowState();
}

class _InvoiceLineRowState extends State<_InvoiceLineRow> {
  void _rebuild() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    final items = context.read<ItemProvider>().items;
    final primary = Theme.of(context).colorScheme.primary;
    final convertedTotal = AppCurrency.convert(l.totalPrice, l.currency, widget.invoiceCurrency, widget.exchangeRate);
    final differentCurrency = l.currency != widget.invoiceCurrency;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<Item>(
              initialValue: TextEditingValue(text: l.nameCtrl.text),
              displayStringForOption: (i) => i.name,
              optionsBuilder: (v) {
                if (v.text.isEmpty) return items;
                return items.where((i) => i.name.contains(v.text));
              },
              onSelected: (i) {
                l.applyItem(i, widget.invoiceType == 'wholesale');
                _rebuild();
              },
              fieldViewBuilder: (ctx, ctrl, fn, onSubmit) {
                l.nameCtrl.text = ctrl.text;
                return TextField(
                  controller: ctrl,
                  focusNode: fn,
                  textDirection: TextDirection.rtl,
                  onChanged: (_) => _rebuild(),
                  decoration: const InputDecoration(hintText: 'اسم المادة...', isDense: true),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: DropdownButtonFormField<String>(
              value: Item.supportedUnits.contains(l.unit) ? l.unit : Item.supportedUnits.first,
              isExpanded: true,
              isDense: true,
              decoration: const InputDecoration(),
              items: Item.supportedUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)))).toList(),
              onChanged: (v) { setState(() => l.unit = v!); _rebuild(); },
            ),
          ),
          const SizedBox(width: 10),
          if (l.needsDimensions) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حجم الطباعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: l.widthCtrl,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          onChanged: (_) => _rebuild(),
                          decoration: const InputDecoration(hintText: 'عرض', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('×', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      ),
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: l.heightCtrl,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          onChanged: (_) => _rebuild(),
                          decoration: const InputDecoration(hintText: 'طول', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('العدد', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: l.qtyCtrl,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  onChanged: (_) => _rebuild(),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: TextField(
              controller: l.priceCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              onChanged: (_) => _rebuild(),
              decoration: const InputDecoration(hintText: 'السعر', isDense: true),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 46,
            child: GestureDetector(
              onTap: () { setState(() => l.currency = l.currency == AppCurrency.usd ? AppCurrency.iqd : AppCurrency.usd); _rebuild(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: l.currency == AppCurrency.usd ? AppColors.warning.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(AppCurrency.symbol(l.currency),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700,
                        color: l.currency == AppCurrency.usd ? AppColors.warning : AppColors.success)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  NumberFormatter.compact(convertedTotal),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13, color: primary),
                ),
                if (differentCurrency)
                  Text(
                    '(${NumberFormatter.compact(l.totalPrice)} ${AppCurrency.symbol(l.currency)})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.remove_circle_rounded, color: AppColors.error, size: 18), onPressed: widget.onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}

class _ItemsTableHeader extends StatelessWidget {
  final String invoiceCurrency;
  const _ItemsTableHeader({required this.invoiceCurrency});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 3, child: _Th('المادة / الخدمة')),
        const SizedBox(width: 8),
        const SizedBox(width: 110, child: _Th('الوحدة')),
        const SizedBox(width: 10),
        const SizedBox(width: 130, child: _Th('حجم الطباعة')),
        const SizedBox(width: 18),
        const SizedBox(width: 60,  child: _Th('العدد')),
        const SizedBox(width: 8),
        const SizedBox(width: 78,  child: _Th('السعر')),
        const SizedBox(width: 4),
        const SizedBox(width: 46,  child: _Th('عملة')),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: _Th('الإجمالي (${AppCurrency.symbol(invoiceCurrency)})')),
        const SizedBox(width: 32),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);
  @override
  Widget build(BuildContext context) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textMuted));
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({required this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          child,
        ],
      );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _TotalRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textMuted)),
          Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14, color: valueColor)),
        ],
      );
}

class _TypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(label: AppStrings.retail, selected: value == 'retail', color: primary, onTap: () => onChanged('retail')),
          _ToggleBtn(label: AppStrings.wholesale, selected: value == 'wholesale', color: AppColors.info, onTap: () => onChanged('wholesale')),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: selected ? color : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}

class _CustomerSelector extends StatelessWidget {
  final Customer? selected;
  final void Function(Customer?) onChanged;
  const _CustomerSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    return DropdownButtonFormField<Customer?>(
      value: selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: AppStrings.customer, prefixIcon: Icon(Icons.person_rounded, size: 18)),
      items: [
        const DropdownMenuItem<Customer?>(value: null, child: Text(AppStrings.walkInCustomer, style: TextStyle(fontFamily: 'Cairo', fontSize: 13))),
        ...customers.map((c) => DropdownMenuItem<Customer?>(value: c, child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)))),
      ],
      onChanged: onChanged,
    );
  }
}
