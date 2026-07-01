import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/purchase.dart';

class PurchaseProvider extends ChangeNotifier {
  List<Purchase> _purchases = [];
  bool _loading = false;
  String _query = '';
  double _totalAmount = 0;
  double _monthAmount = 0;

  List<Purchase> get purchases => _purchases;
  bool get loading => _loading;
  double get totalAmount => _totalAmount;
  double get monthAmount => _monthAmount;

  PurchaseProvider() { fetchAll(); }

  Future<void> fetchAll({String? q}) async {
    _loading = true;
    notifyListeners();
    _query = q ?? '';
    _purchases = await DatabaseHelper.instance.getPurchases(q: _query.isEmpty ? null : _query);
    _totalAmount = await DatabaseHelper.instance.getTotalPurchasesAmount();
    _monthAmount = await DatabaseHelper.instance.getTotalPurchasesAmount(thisMonthOnly: true);
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String q) => fetchAll(q: q);

  Future<bool> add(Purchase p) async {
    try {
      await DatabaseHelper.instance.insertPurchase(p);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(Purchase p) async {
    try {
      await DatabaseHelper.instance.updatePurchase(p);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await DatabaseHelper.instance.deletePurchase(id);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }
}
