import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _loading = false;
  String _query = '';

  List<Customer> get customers => _customers;
  bool get loading => _loading;

  CustomerProvider() { fetchAll(); }

  Future<void> fetchAll({String? q}) async {
    _loading = true;
    notifyListeners();
    _query = q ?? '';
    _customers = await DatabaseHelper.instance.getCustomers(q: _query.isEmpty ? null : _query);
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String q) => fetchAll(q: q);

  Future<bool> add(Customer c) async {
    try {
      await DatabaseHelper.instance.insertCustomer(c);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(Customer c) async {
    try {
      await DatabaseHelper.instance.updateCustomer(c);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await DatabaseHelper.instance.deleteCustomer(id);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }
}
