import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';

class PurchaseForm extends StatefulWidget {
  final Purchase? purchase;
  const PurchaseForm({super.key, this.purchase});

  @override
  State<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<PurchaseForm> {
  late final TextEditingController _supplier;
  late final TextEditingController _itemName;
  late final TextEditingController _category;
  late final TextEditingController _qty;
  late final TextEditingController _unit;
  late final TextEditingController _unitPrice;
  late final TextEditingController _paid;
  late final TextEditingController _notes;
  late String _currency;
  bool _saving = false;

  bool get isEdit => widget.purchase != null;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _supplier   = TextEditingController(text: p?.supplierName ?? '');
    _itemName   = TextEditingController(text: p?.itemName ?? '');
    _category   = TextEditingController(text: p?.category ?? '');
    _qty        = TextEditingController(text: (p?.quantity ?? 1).toString());
    _unit       = TextEditingController(text: p?.unit ?? '');
    _unitPrice  = TextEditingController(text: p != null ? p.unitPrice.toString() : '');
    _paid       = TextEditingController(text: p != null ? p.paidAmount.toString() : '');
    _notes      = TextEditingController(text: p?.notes ?? '');
    _currency   = p?.currency ?? AppCurrency.iqd;
  }

  @override
  void dispose() {
    _supplier.dispose(); _itemName.dispose(); _category.dispose();
    _qty.dispose(); _unit.dispose(); _unitPrice.dispose();
    _paid.dispose(); _notes.dispose();
    super.dispose();
  }

  double get _total => (double.tryParse(_qty.text) ?? 1) * (double.tryParse(_unitPrice.text) ?? 0);

  Future<void> _save() async {
    if (_itemName.text.trim().isEmpty || (double.tryParse(_unitPrice.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اسم المادة وسعراً صحيحاً', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _saving = true);

    final purchase = Purchase(
      id: widget.purchase?.id,
      supplierName: _supplier.text.trim(),
      itemName: _itemName.text.trim(),
      category: _category.text.trim(),
      quantity: double.tryParse(_qty.text) ?? 1,
      unit: _unit.text.trim(),
      unitPrice: double.tryParse(_unitPrice.text) ?? 0,
      totalPrice: _total,
      paidAmount: double.tryParse(_paid.text) ?? 0,
      currency: _currency,
      purchaseDate: widget.purchase?.purchaseDate,
      notes: _notes.text.trim(),
    );

    final prov = context.read<PurchaseProvider>();
    final ok = isEdit ? await prov.update(purchase) : await prov.add(purchase);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? AppStrings.saveSuccess : AppStrings.errorOccurred, style: const TextStyle(fontFamily: 'Cairo')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? AppStrings.editPurchase : AppStrings.addPurchase, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _itemName,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: AppStrings.purchaseItemName, prefixIcon: Icon(Icons.inventory_2_rounded, size: 18)),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _supplier,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: AppStrings.supplierName, prefixIcon: Icon(Icons.local_shipping_rounded, size: 18)),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _category,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: AppStrings.purchaseCategory, prefixIcon: Icon(Icons.category_rounded, size: 18)),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: AppStrings.purchaseQuantity),
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _unit,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(labelText: AppStrings.purchaseUnit, hintText: 'كغم، رزمة...'),
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('العملة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: AppCurrency.all.map((c) {
                          final sel = _currency == c;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _currency = c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(AppCurrency.label(c),
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.black54)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unitPrice,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: '${AppStrings.purchaseUnitPrice} (${AppCurrency.symbol(_currency)})', prefixIcon: const Icon(Icons.payments_rounded, size: 18)),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _paid,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: '${AppStrings.purchasePaid} (${AppCurrency.symbol(_currency)})', prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18)),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: AppStrings.notes),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(AppStrings.purchaseTotal, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${_total.toStringAsFixed(0)} ${AppCurrency.symbol(_currency)}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo'))),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }
}
