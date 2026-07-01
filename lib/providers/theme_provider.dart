import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  Color _primary = const Color(0xFFE65100);

  bool  get isDark   => _isDark;
  Color get primary  => _primary;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    _isDark  = (await DatabaseHelper.instance.getSetting('dark_mode')) == 'true';
    final c  = await DatabaseHelper.instance.getSetting('primary_color');
    if (c != null && c.isNotEmpty) {
      try { _primary = Color(int.parse(c)); } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    await DatabaseHelper.instance.setSetting('dark_mode', _isDark.toString());
    notifyListeners();
  }

  Future<void> setColor(Color c) async {
    _primary = c;
    await DatabaseHelper.instance.setSetting(
        'primary_color', '0x${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    notifyListeners();
  }
}
