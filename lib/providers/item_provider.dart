import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/item.dart';

class ItemProvider extends ChangeNotifier {
  List<Item> _items = [];
  bool _loading = false;
  String _query = '';

  List<Item> get items => _items;
  bool get loading => _loading;

  ItemProvider() { fetchAll(); }

  Future<void> fetchAll({String? q}) async {
    _loading = true;
    notifyListeners();
    _query = q ?? '';
    _items = await DatabaseHelper.instance.getItems(q: _query.isEmpty ? null : _query);
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String q) => fetchAll(q: q);

  Future<bool> add(Item item) async {
    try {
      await DatabaseHelper.instance.insertItem(item);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(Item item) async {
    try {
      await DatabaseHelper.instance.updateItem(item);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await DatabaseHelper.instance.deleteItem(id);
      await fetchAll(q: _query.isEmpty ? null : _query);
      return true;
    } catch (_) { return false; }
  }
}
