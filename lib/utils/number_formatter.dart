import 'package:intl/intl.dart';

class NumberFormatter {
  static final NumberFormat _currency = NumberFormat('#,##0.00', 'ar');
  static final NumberFormat _compact  = NumberFormat('#,##0.##', 'ar');

  static String currency(double v) => '${_currency.format(v)} ل.س';

  static String compact(double v) => _compact.format(v);

  static String date(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('yyyy/MM/dd', 'ar').format(d);
    } catch (_) {
      return iso;
    }
  }

  static String dateTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('yyyy/MM/dd – HH:mm', 'ar').format(d);
    } catch (_) {
      return iso;
    }
  }

  static String todayDate() =>
      DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());
}
