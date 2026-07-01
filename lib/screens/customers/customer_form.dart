import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';

class CustomerForm extends StatefulWidget {
  final Customer? customer;
  const CustomerForm({super.key, this.customer});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  bool _loading = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name    = TextEditingController(text: c?.name    ?? '');
    _phone   = TextEditingController(text: c?.phone   ?? '');
    _email   = TextEditingController(text: c?.email   ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _notes   = TextEditingController(text: c?.notes   ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _email.dispose();
    _address.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final prov = context.read<CustomerProvider>();
    final customer = Customer(
      id: widget.customer?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      notes: _notes.text.trim(),
    );
    final ok = isEdit ? await prov.update(customer) : await prov.add(customer);
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
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? AppStrings.editCustomer : AppStrings.addCustomer,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 24),
                _field(_name, AppStrings.customerName, required: true, icon: Icons.person_rounded),
                const SizedBox(height: 12),
                _field(_phone, AppStrings.customerPhone, icon: Icons.phone_rounded),
                const SizedBox(height: 12),
                _field(_email, AppStrings.customerEmail, icon: Icons.email_rounded),
                const SizedBox(height: 12),
                _field(_address, AppStrings.customerAddress, icon: Icons.location_on_rounded),
                const SizedBox(height: 12),
                _field(_notes, AppStrings.notes, icon: Icons.notes_rounded, maxLines: 3),
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

  Widget _field(TextEditingController ctrl, String label, {bool required = false, IconData? icon, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, size: 18) : null),
      validator: required ? (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null : null,
    );
  }
}
