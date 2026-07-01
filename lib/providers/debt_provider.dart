import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/debt.dart';
import '../models/invoice.dart';

class DebtProvider extends ChangeNotifier {
  List<Debt> _debts = [];
  List<Invoice> _unpaidInvoices = [];
  bool _loading = false;
  String _query = '';
  double _totalDebts = 0;

  List<Debt> get debts => _debts;
  List<Invoice> get unpaidInvoices => _unpaidInvoices;
  bool get loading => _loading;
  double get totalDebts => _totalDebts;

  DebtProvider() { fetchAll(); }

  Future<void> fetchAll({String? q}) async {
    _loading = true;
    notifyListeners();
    _query = q ?? '';
    _debts = await DatabaseHelper.instance.getDebts(q: _query.isEmpty ? null : _query);
    _unpaidInvoices = await DatabaseHelper.instance.getUnpaidInvoices();
    _totalDebts = await DatabaseHelper.instance.getTotalDebts();
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String q) => fetchAll(q: q);

  Future<bool> add(Debt debt) async {
    try {
      await DatabaseHelper.instance.insertDebt(debt);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(Debt debt) async {
    try {
      await DatabaseHelper.instance.updateDebt(debt);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await DatabaseHelper.instance.deleteDebt(id);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<double> getCustomerDebt(int customerId) {
    return DatabaseHelper.instance.getCustomerTotalDebt(customerId);
  }

  /// تسجيل دفعة على فاتورة معينة (يحدّث الفاتورة نفسها، وليس سجل الديون اليدوي)
  Future<bool> payInvoice(int invoiceId, double paidAmount) async {
    try {
      await DatabaseHelper.instance.updateInvoicePayment(invoiceId, paidAmount);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }
}
