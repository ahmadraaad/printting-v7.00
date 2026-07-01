import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/item.dart';
import '../../providers/item_provider.dart';

class ItemForm extends StatefulWidget {
  final Item? item;
  const ItemForm({super.key, this.item});

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _retail;
  late final TextEditingController _wholesale;
  late final TextEditingController _category;
  late String _unit;
  late String _currency;
  bool _loading = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name      = TextEditingController(text: i?.name          ?? '');
    _desc      = TextEditingController(text: i?.description   ?? '');
    _retail    = TextEditingController(text: i != null ? i.retailPrice.toString()    : '');
    _wholesale = TextEditingController(text: i != null ? i.wholesalePrice.toString() : '');
    _category  = TextEditingController(text: i?.category      ?? '');
    _unit      = i?.unit ?? Item.supportedUnits.first;
    _currency  = i?.currency ?? AppCurrency.iqd;
  }

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _retail.dispose();
    _wholesale.dispose(); _category.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final prov = context.read<ItemProvider>();
    final item = Item(
      id: widget.item?.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      unit: _unit,
      retailPrice: double.tryParse(_retail.text) ?? 0,
      wholesalePrice: double.tryParse(_wholesale.text) ?? 0,
      currency: _currency,
      category: _category.text.trim(),
    );
    final ok = isEdit ? await prov.update(item) : await prov.add(item);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? AppStrings.editItem : AppStrings.addItem,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 24),
                _field(_name, AppStrings.itemName, required: true),
                const SizedBox(height: 12),
                _field(_desc, AppStrings.itemDescription, maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _unit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: AppStrings.unit),
                  items: Item.supportedUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _unit = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('عملة السعر:', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.black87)),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(_retail, '${AppStrings.retailPrice} (${AppCurrency.symbol(_currency)})', required: true, keyboardType: TextInputType.number,
                          prefix: const Icon(Icons.attach_money, size: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_wholesale, '${AppStrings.wholesalePrice} (${AppCurrency.symbol(_currency)})', required: true, keyboardType: TextInputType.number,
                          prefix: const Icon(Icons.local_offer_rounded, size: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_category, AppStrings.category),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo'))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = false, TextInputType? keyboardType, int maxLines = 1, Widget? prefix}) {
    return TextFormField(
      controller: ctrl,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: prefix),
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return AppStrings.fieldRequired;
              if (keyboardType == TextInputType.number) {
                if (double.tryParse(v) == null) return AppStrings.invalidNumber;
              }
              return null;
            }
          : null,
    );
  }
}
