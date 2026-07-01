import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  Map<String, String> _settings = {};

  String get companyName    => _settings['company_name']    ?? 'مطبعة شمس للدعاية والإعلان';
  String get phone1         => _settings['phone1']          ?? '';
  String get phone2         => _settings['phone2']          ?? '';
  String get address        => _settings['address']         ?? '';
  String get website        => _settings['website']         ?? '';
  String get email          => _settings['email']           ?? '';
  String get logoPath       => _settings['logo_path']       ?? '';
  String get invoicePrefix  => _settings['invoice_prefix']  ?? 'SH';
  String get invoiceTemplate=> _settings['invoice_template']?? 'template1';

  // ── تخصيص الفاتورة ──
  String get invoiceAccentColor => _settings['invoice_accent_color'] ?? '0xFFE65100';
  String get invoiceHeaderText  => _settings['invoice_header_text']  ?? '';
  String get invoiceFooterText  => _settings['invoice_footer_text']  ?? 'شكراً لتعاملكم معنا';
  bool get invoiceShowPhone2    => (_settings['invoice_show_phone2'] ?? 'true') == 'true';
  bool get invoiceShowAddress   => (_settings['invoice_show_address'] ?? 'true') == 'true';
  bool get invoiceShowWebsite   => (_settings['invoice_show_website'] ?? 'true') == 'true';
  bool get invoiceShowEmail     => (_settings['invoice_show_email'] ?? 'true') == 'true';
  bool get invoiceShowLogo      => (_settings['invoice_show_logo'] ?? 'true') == 'true';
  bool get invoiceShowNotes     => (_settings['invoice_show_notes'] ?? 'true') == 'true';

  // ── العملة وسعر الصرف ──
  double get exchangeRateUsdIqd => double.tryParse(_settings['exchange_rate_usd_iqd'] ?? '') ?? 1500;
  String get defaultCurrency    => _settings['default_currency'] ?? 'IQD';

  SettingsProvider() { _load(); }

  Future<void> _load() async {
    _settings = await DatabaseHelper.instance.getAllSettings();
    notifyListeners();
  }

  Future<void> save(Map<String, String> updates) async {
    await DatabaseHelper.instance.setSettings(updates);
    _settings.addAll(updates);
    notifyListeners();
  }

  Future<void> reload() => _load();
}
