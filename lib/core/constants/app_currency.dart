/// أدوات مساعدة للتعامل مع العملتين المدعومتين في النظام: الدينار العراقي والدولار الأمريكي
class AppCurrency {
  static const String usd = 'USD';
  static const String iqd = 'IQD';

  static const List<String> all = [iqd, usd];

  static String label(String code) => code == usd ? 'دولار' : 'دينار';
  static String symbol(String code) => code == usd ? '\$' : 'د.ع';

  /// يحول مبلغاً من عملة [from] إلى عملة [to] باستخدام سعر الصرف (دينار لكل دولار واحد)
  static double convert(double amount, String from, String to, double usdToIqdRate) {
    if (from == to) return amount;
    if (from == usd && to == iqd) return amount * usdToIqdRate;
    if (from == iqd && to == usd) {
      if (usdToIqdRate <= 0) return 0;
      return amount / usdToIqdRate;
    }
    return amount;
  }
}
