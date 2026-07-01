import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceProvider extends ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _loading = false;
  String _query = '';
  String? _statusFilter;

  List<Invoice> get invoices => _invoices;
  bool get loading => _loading;

  InvoiceProvider() { fetchAll(); }

  Future<void> fetchAll({String? q, String? status}) async {
    _loading = true;
    notifyListeners();
    _query = q ?? _query;
    _statusFilter = status;
    _invoices = await DatabaseHelper.instance.getInvoices(
      q: _query.isEmpty ? null : _query,
      status: _statusFilter,
    );
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String q) => fetchAll(q: q);
  Future<void> filterStatus(String? s) => fetchAll(status: s);

  Future<String> nextNumber() => DatabaseHelper.instance.nextInvoiceNumber();

  Future<int?> create(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final id = await DatabaseHelper.instance.insertInvoice(invoice, items);
      await fetchAll();
      return id;
    } catch (_) { return null; }
  }

  Future<bool> update(Invoice invoice, List<InvoiceItem> items) async {
    try {
      await DatabaseHelper.instance.updateInvoice(invoice, items);
      await fetchAll();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await DatabaseHelper.instance.deleteInvoice(id);
      await fetchAll();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> setStatus(int id, String status) async {
    try {
      await DatabaseHelper.instance.updateInvoiceStatus(id, status);
      await fetchAll();
      return true;
    } catch (_) { return false; }
  }

  /// تحديث المبلغ المدفوع لفاتورة (يحسب الحالة تلقائياً: معلقة/جزئي/مدفوعة)
  Future<bool> setPayment(int id, double paidAmount) async {
    try {
      await DatabaseHelper.instance.updateInvoicePayment(id, paidAmount);
      await fetchAll();
      return true;
    } catch (_) { return false; }
  }

  Future<Invoice?> getWithItems(int id) =>
      DatabaseHelper.instance.getInvoiceWithItems(id);
}
