import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _companyName;
  late final TextEditingController _phone1;
  late final TextEditingController _phone2;
  late final TextEditingController _address;
  late final TextEditingController _website;
  late final TextEditingController _email;
  late final TextEditingController _invoicePrefix;
  late final TextEditingController _headerText;
  late final TextEditingController _footerText;
  late final TextEditingController _exchangeRate;
  String _template = 'template1';
  late Color _accentColor;
  late bool _showPhone2;
  late bool _showAddress;
  late bool _showWebsite;
  late bool _showEmail;
  late bool _showLogo;
  late bool _showNotes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _companyName   = TextEditingController(text: s.companyName);
    _phone1        = TextEditingController(text: s.phone1);
    _phone2        = TextEditingController(text: s.phone2);
    _address       = TextEditingController(text: s.address);
    _website       = TextEditingController(text: s.website);
    _email         = TextEditingController(text: s.email);
    _invoicePrefix = TextEditingController(text: s.invoicePrefix);
    _headerText    = TextEditingController(text: s.invoiceHeaderText);
    _footerText    = TextEditingController(text: s.invoiceFooterText);
    _exchangeRate  = TextEditingController(text: s.exchangeRateUsdIqd.toStringAsFixed(0));
    _template      = s.invoiceTemplate;
    _accentColor   = Color(int.tryParse(s.invoiceAccentColor) ?? 0xFFE65100);
    _showPhone2    = s.invoiceShowPhone2;
    _showAddress   = s.invoiceShowAddress;
    _showWebsite   = s.invoiceShowWebsite;
    _showEmail     = s.invoiceShowEmail;
    _showLogo      = s.invoiceShowLogo;
    _showNotes     = s.invoiceShowNotes;
  }

  @override
  void dispose() {
    _companyName.dispose(); _phone1.dispose(); _phone2.dispose();
    _address.dispose(); _website.dispose(); _email.dispose();
    _invoicePrefix.dispose(); _headerText.dispose(); _footerText.dispose();
    _exchangeRate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<SettingsProvider>().save({
      'company_name'     : _companyName.text.trim(),
      'phone1'           : _phone1.text.trim(),
      'phone2'           : _phone2.text.trim(),
      'address'          : _address.text.trim(),
      'website'          : _website.text.trim(),
      'email'            : _email.text.trim(),
      'invoice_prefix'   : _invoicePrefix.text.trim(),
      'invoice_template' : _template,
      'invoice_accent_color' : '0x${_accentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      'invoice_header_text'  : _headerText.text.trim(),
      'invoice_footer_text'  : _footerText.text.trim(),
      'invoice_show_phone2'  : _showPhone2.toString(),
      'invoice_show_address' : _showAddress.toString(),
      'invoice_show_website' : _showWebsite.toString(),
      'invoice_show_email'   : _showEmail.toString(),
      'invoice_show_logo'    : _showLogo.toString(),
      'invoice_show_notes'   : _showNotes.toString(),
      'exchange_rate_usd_iqd': (double.tryParse(_exchangeRate.text) ?? 1500).toString(),
    });
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.saveSuccess, style: TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path!;
      await context.read<SettingsProvider>().save({'logo_path': path});
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.settings,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
                  label: const Text(AppStrings.save),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Card(
                    title: AppStrings.companyInfo,
                    icon: Icons.business_rounded,
                    children: [
                      _Field(_companyName, AppStrings.companyName, icon: Icons.storefront_rounded),
                      const SizedBox(height: 12),
                      _Field(_phone1, AppStrings.phone, icon: Icons.phone_rounded),
                      const SizedBox(height: 12),
                      _Field(_phone2, AppStrings.phone2, icon: Icons.phone_android_rounded),
                      const SizedBox(height: 12),
                      _Field(_address, AppStrings.address, icon: Icons.location_on_rounded, maxLines: 2),
                      const SizedBox(height: 12),
                      _Field(_website, AppStrings.website, icon: Icons.language_rounded),
                      const SizedBox(height: 12),
                      _Field(_email, AppStrings.email, icon: Icons.email_rounded),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      _Card(
                        title: AppStrings.logo,
                        icon: Icons.image_rounded,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.dividerLight),
                                  ),
                                  child: sp.logoPath.isNotEmpty && File(sp.logoPath).existsSync()
                                      ? ClipOval(child: Image.file(File(sp.logoPath), fit: BoxFit.cover))
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_rounded, size: 36, color: Colors.grey[400]),
                                            const SizedBox(height: 4),
                                            const Text('لا يوجد شعار', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.upload_rounded), label: const Text(AppStrings.uploadLogo)),
                                if (sp.logoPath.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: () async { await sp.save({'logo_path': ''}); setState(() {}); },
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                                    label: const Text('حذف الشعار', style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Card(
                        title: 'إعدادات الفاتورة',
                        icon: Icons.receipt_long_rounded,
                        children: [
                          _Field(_invoicePrefix, AppStrings.invoicePrefix, icon: Icons.tag_rounded),
                          const SizedBox(height: 16),
                          const Text(AppStrings.invoiceTemplate, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          ...[
                            ('template1', AppStrings.template1),
                            ('template2', AppStrings.template2),
                            ('template3', AppStrings.template3),
                          ].map((t) => RadioListTile<String>(
                                value: t.$1,
                                groupValue: _template,
                                title: Text(t.$2, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                                onChanged: (v) => setState(() => _template = v!),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Card(
                        title: 'المظهر',
                        icon: Icons.palette_rounded,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(AppStrings.darkMode, style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                              Switch(value: tp.isDark, onChanged: (_) => tp.toggleDark()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(AppStrings.primaryColor, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: _palette.map((c) {
                              final sel = tp.primary.value == c.value;
                              return GestureDetector(
                                onTap: () => tp.setColor(c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: sel ? Border.all(color: Colors.white, width: 3) : null,
                                    boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Card(
                        title: 'سعر الصرف اليومي',
                        icon: Icons.currency_exchange_rounded,
                        children: [
                          _Field(_exchangeRate, 'سعر صرف الدولار مقابل الدينار', icon: Icons.attach_money_rounded),
                          const SizedBox(height: 6),
                          const Text('مثال: إذا كان سعر الدولار 1500 دينار، أدخل 1500. يُستخدم هذا السعر لتحويل أسعار الأصناف بين العملتين تلقائياً عند الحاجة.',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Card(
                        title: 'تخصيص شكل الفاتورة',
                        icon: Icons.edit_document,
                        children: [
                          const Text('لون الفاتورة المميز', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: _palette.map((c) {
                              final sel = _accentColor.value == c.value;
                              return GestureDetector(
                                onTap: () => setState(() => _accentColor = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: sel ? Border.all(color: Colors.white, width: 3) : null,
                                    boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          _Field(_headerText, 'نص إضافي في رأس الفاتورة (اختياري)', icon: Icons.title_rounded, maxLines: 2),
                          const SizedBox(height: 12),
                          _Field(_footerText, 'نص تذييل الفاتورة', icon: Icons.short_text_rounded, maxLines: 2),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('الحقول الظاهرة في الفاتورة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textMuted)),
                          _ToggleRow(label: 'الشعار', value: _showLogo, onChanged: (v) => setState(() => _showLogo = v)),
                          _ToggleRow(label: 'رقم الهاتف الإضافي', value: _showPhone2, onChanged: (v) => setState(() => _showPhone2 = v)),
                          _ToggleRow(label: AppStrings.address, value: _showAddress, onChanged: (v) => setState(() => _showAddress = v)),
                          _ToggleRow(label: AppStrings.website, value: _showWebsite, onChanged: (v) => setState(() => _showWebsite = v)),
                          _ToggleRow(label: AppStrings.email, value: _showEmail, onChanged: (v) => setState(() => _showEmail = v)),
                          _ToggleRow(label: 'الملاحظات', value: _showNotes, onChanged: (v) => setState(() => _showNotes = v)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _palette = [
    Color(0xFFE65100),
    Color(0xFFD32F2F),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFF57F17),
    Color(0xFF37474F),
  ];
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({required this.title, required this.icon, required this.children});

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
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 0),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData? icon;
  final int maxLines;

  const _Field(this.ctrl, this.label, {this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, size: 18) : null),
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}
