import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/customer.dart';
import '../../models/item.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/debt.dart';
import '../../models/purchase.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final appDoc = await getApplicationDocumentsDirectory();
    final dir = Directory(join(appDoc.path, 'ShamsPrinting'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = join(dir.path, 'shams_printing.db');

    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createTables,
        onUpgrade: _upgradeDB,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }

  Future<void> _upgradeDB(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      // إضافة حقول الدفع للفواتير
      await db.execute("ALTER TABLE invoices ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0");

      // أي فاتورة كانت 'paid' سابقاً تعتبر مدفوعة بالكامل
      await db.execute("UPDATE invoices SET paid_amount = total WHERE status = 'paid'");

      await db.execute('''
        CREATE TABLE debts (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id  INTEGER,
          customer_name TEXT   NOT NULL,
          type         TEXT    NOT NULL DEFAULT 'debt',
          amount       REAL    NOT NULL DEFAULT 0,
          description  TEXT    DEFAULT '',
          debt_date    TEXT    NOT NULL,
          created_at   TEXT    NOT NULL,
          updated_at   TEXT    NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE purchases (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_name TEXT    NOT NULL DEFAULT '',
          item_name     TEXT    NOT NULL,
          category      TEXT    DEFAULT '',
          quantity      REAL    NOT NULL DEFAULT 1,
          unit          TEXT    DEFAULT '',
          unit_price    REAL    NOT NULL DEFAULT 0,
          total_price   REAL    NOT NULL DEFAULT 0,
          paid_amount   REAL    NOT NULL DEFAULT 0,
          purchase_date TEXT    NOT NULL,
          notes         TEXT    DEFAULT '',
          created_at    TEXT    NOT NULL,
          updated_at    TEXT    NOT NULL
        )
      ''');

      // إعدادات تخصيص الفاتورة الجديدة
      final invoiceCustomizationDefaults = {
        'invoice_accent_color'   : '0xFFE65100',
        'invoice_header_text'    : '',
        'invoice_footer_text'    : 'شكراً لتعاملكم معنا',
        'invoice_show_phone2'    : 'true',
        'invoice_show_address'   : 'true',
        'invoice_show_website'   : 'true',
        'invoice_show_email'     : 'true',
        'invoice_show_logo'      : 'true',
        'invoice_show_notes'     : 'true',
        'invoice_show_qr'        : 'false',
        'invoice_paper_size'     : 'a4',
      };
      final batch = db.batch();
      for (final e in invoiceCustomizationDefaults.entries) {
        batch.insert('settings', {'key': e.key, 'value': e.value},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    if (oldV < 3) {
      // عملة كل صنف (USD أو IQD) - الأسعار الموجودة تبقى كما هي وتُعتبر افتراضياً دينار
      await db.execute("ALTER TABLE items ADD COLUMN currency TEXT NOT NULL DEFAULT 'IQD'");

      // عملة الفاتورة (العملة المعروضة في الإجمالي)، وسعر الصرف وقت إنشاء الفاتورة
      await db.execute("ALTER TABLE invoices ADD COLUMN currency TEXT NOT NULL DEFAULT 'IQD'");
      await db.execute("ALTER TABLE invoices ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1");

      // عملة كل بند ضمن الفاتورة (يحتفظ بعملته الأصلية وقيمته بعملة الفاتورة بعد التحويل)
      await db.execute("ALTER TABLE invoice_items ADD COLUMN currency TEXT NOT NULL DEFAULT 'IQD'");

      // عملة الديون والمشتريات
      await db.execute("ALTER TABLE debts ADD COLUMN currency TEXT NOT NULL DEFAULT 'IQD'");
      await db.execute("ALTER TABLE purchases ADD COLUMN currency TEXT NOT NULL DEFAULT 'IQD'");

      await db.insert('settings', {'key': 'exchange_rate_usd_iqd', 'value': '1500'},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('settings', {'key': 'default_currency', 'value': 'IQD'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _createTables(Database db, int v) async {
    await db.execute('''
      CREATE TABLE customers (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT    NOT NULL,
        phone        TEXT    DEFAULT '',
        email        TEXT    DEFAULT '',
        address      TEXT    DEFAULT '',
        notes        TEXT    DEFAULT '',
        created_at   TEXT    NOT NULL,
        updated_at   TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL,
        description      TEXT    DEFAULT '',
        unit             TEXT    NOT NULL DEFAULT 'عدد',
        retail_price     REAL    NOT NULL DEFAULT 0,
        wholesale_price  REAL    NOT NULL DEFAULT 0,
        currency         TEXT    NOT NULL DEFAULT 'IQD',
        category         TEXT    DEFAULT '',
        created_at       TEXT    NOT NULL,
        updated_at       TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number   TEXT    NOT NULL UNIQUE,
        customer_id      INTEGER,
        customer_name    TEXT    NOT NULL,
        customer_phone   TEXT    DEFAULT '',
        invoice_type     TEXT    NOT NULL DEFAULT 'retail',
        subtotal         REAL    NOT NULL DEFAULT 0,
        discount_percent REAL    DEFAULT 0,
        discount_amount  REAL    DEFAULT 0,
        total            REAL    NOT NULL DEFAULT 0,
        paid_amount      REAL    NOT NULL DEFAULT 0,
        currency         TEXT    NOT NULL DEFAULT 'IQD',
        exchange_rate    REAL    NOT NULL DEFAULT 1,
        notes            TEXT    DEFAULT '',
        status           TEXT    NOT NULL DEFAULT 'pending',
        created_at       TEXT    NOT NULL,
        updated_at       TEXT    NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id   INTEGER NOT NULL,
        item_id      INTEGER,
        item_name    TEXT    NOT NULL,
        unit         TEXT    NOT NULL DEFAULT 'عدد',
        width        REAL,
        height       REAL,
        quantity     REAL    NOT NULL DEFAULT 1,
        area_sqm     REAL,
        unit_price   REAL    NOT NULL DEFAULT 0,
        total_price  REAL    NOT NULL DEFAULT 0,
        currency     TEXT    NOT NULL DEFAULT 'IQD',
        notes        TEXT    DEFAULT '',
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id)    REFERENCES items(id)    ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id  INTEGER,
        customer_name TEXT   NOT NULL,
        type         TEXT    NOT NULL DEFAULT 'debt',
        amount       REAL    NOT NULL DEFAULT 0,
        currency     TEXT    NOT NULL DEFAULT 'IQD',
        description  TEXT    DEFAULT '',
        debt_date    TEXT    NOT NULL,
        created_at   TEXT    NOT NULL,
        updated_at   TEXT    NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_name TEXT    NOT NULL DEFAULT '',
        item_name     TEXT    NOT NULL,
        category      TEXT    DEFAULT '',
        quantity      REAL    NOT NULL DEFAULT 1,
        unit          TEXT    DEFAULT '',
        unit_price    REAL    NOT NULL DEFAULT 0,
        total_price   REAL    NOT NULL DEFAULT 0,
        paid_amount   REAL    NOT NULL DEFAULT 0,
        currency      TEXT    NOT NULL DEFAULT 'IQD',
        purchase_date TEXT    NOT NULL,
        notes         TEXT    DEFAULT '',
        created_at    TEXT    NOT NULL,
        updated_at    TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT DEFAULT ''
      )
    ''');

    final batch = db.batch();
    final defaults = {
      'company_name'     : 'مطبعة شمس للدعاية والإعلان',
      'phone1'           : '',
      'phone2'           : '',
      'address'          : '',
      'website'          : '',
      'email'            : '',
      'invoice_prefix'   : 'SH',
      'invoice_counter'  : '1',
      'dark_mode'        : 'false',
      'invoice_template' : 'template1',
      'primary_color'    : '0xFFE65100',
      'logo_path'        : '',
      'invoice_accent_color' : '0xFFE65100',
      'invoice_header_text'  : '',
      'invoice_footer_text'  : 'شكراً لتعاملكم معنا',
      'invoice_show_phone2'  : 'true',
      'invoice_show_address' : 'true',
      'invoice_show_website' : 'true',
      'invoice_show_email'   : 'true',
      'invoice_show_logo'    : 'true',
      'invoice_show_notes'   : 'true',
      'invoice_show_qr'      : 'false',
      'invoice_paper_size'   : 'a4',
      'exchange_rate_usd_iqd': '1500',
      'default_currency'     : 'IQD',
    };
    for (final e in defaults.entries) {
      batch.insert('settings', {'key': e.key, 'value': e.value});
    }
    await batch.commit(noResult: true);
  }

  // ═══ CUSTOMERS ═══
  Future<int> insertCustomer(Customer c) async {
    final db = await database;
    return db.insert('customers', c.toMap());
  }

  Future<int> updateCustomer(Customer c) async {
    final db = await database;
    return db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getCustomers({String? q}) async {
    final db = await database;
    final rows = q != null && q.isNotEmpty
        ? await db.query('customers',
            where: 'name LIKE ? OR phone LIKE ?',
            whereArgs: ['%$q%', '%$q%'],
            orderBy: 'name ASC')
        : await db.query('customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  // ═══ ITEMS ═══
  Future<int> insertItem(Item item) async {
    final db = await database;
    return db.insert('items', item.toMap());
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Item>> getItems({String? q}) async {
    final db = await database;
    final rows = q != null && q.isNotEmpty
        ? await db.query('items',
            where: 'name LIKE ? OR category LIKE ?',
            whereArgs: ['%$q%', '%$q%'],
            orderBy: 'name ASC')
        : await db.query('items', orderBy: 'name ASC');
    return rows.map(Item.fromMap).toList();
  }

  // ═══ INVOICES ═══
  Future<String> nextInvoiceNumber() async {
    final db = await database;
    final pr = await db.query('settings', where: 'key=?', whereArgs: ['invoice_prefix']);
    final cr = await db.query('settings', where: 'key=?', whereArgs: ['invoice_counter']);
    final prefix  = pr.first['value'] as String? ?? 'SH';
    final counter = int.tryParse(cr.first['value'] as String? ?? '1') ?? 1;
    final now = DateTime.now();
    final num = '$prefix${now.year.toString().substring(2)}${now.month.toString().padLeft(2,'0')}${counter.toString().padLeft(4,'0')}';
    await db.update('settings', {'value': (counter + 1).toString()},
        where: 'key=?', whereArgs: ['invoice_counter']);
    return num;
  }

  Future<int> insertInvoice(Invoice invoice, List<InvoiceItem> items) async {
    final db = await database;
    return db.transaction((txn) async {
      final invId = await txn.insert('invoices', invoice.toMap());
      for (final item in items) {
        await txn.insert('invoice_items', item.copyWith(invoiceId: invId).toMap());
      }
      return invId;
    });
  }

  Future<void> updateInvoice(Invoice invoice, List<InvoiceItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('invoices', invoice.toMap(), where: 'id=?', whereArgs: [invoice.id]);
      await txn.delete('invoice_items', where: 'invoice_id=?', whereArgs: [invoice.id]);
      for (final item in items) {
        await txn.insert('invoice_items', item.copyWith(invoiceId: invoice.id).toMap());
      }
    });
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return db.delete('invoices', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateInvoiceStatus(int id, String status) async {
    final db = await database;
    return db.update('invoices', {'status': status, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id=?', whereArgs: [id]);
  }

  /// تحديث المبلغ المدفوع لفاتورة معينة، ويحدّث الحالة تلقائياً (مدفوعة/جزئي/معلقة)
  Future<int> updateInvoicePayment(int id, double paidAmount) async {
    final db = await database;
    final rows = await db.query('invoices', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) return 0;
    final total = (rows.first['total'] as num).toDouble();
    final currentStatus = rows.first['status'] as String? ?? 'pending';
    String newStatus = currentStatus;
    if (currentStatus != 'canceled') {
      if (paidAmount <= 0) {
        newStatus = 'pending';
      } else if (paidAmount >= total - 0.001) {
        newStatus = 'paid';
      } else {
        newStatus = 'partial';
      }
    }
    return db.update(
      'invoices',
      {
        'paid_amount': paidAmount < 0 ? 0 : paidAmount,
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<List<Invoice>> getInvoices({String? q, String? status}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (q != null && q.isNotEmpty) {
      conditions.add('(invoice_number LIKE ? OR customer_name LIKE ?)');
      args.addAll(['%$q%', '%$q%']);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }

    final rows = await db.query(
      'invoices',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  /// كل الفواتير التي عليها مبلغ متبقٍ (دين) لعرضها في خانة الديون
  Future<List<Invoice>> getUnpaidInvoices({int? customerId}) async {
    final db = await database;
    final conditions = <String>["status != 'canceled'", 'total > paid_amount'];
    final args = <dynamic>[];
    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
    }
    final rows = await db.query(
      'invoices',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  Future<Invoice?> getInvoiceWithItems(int id) async {
    final db = await database;
    final rows = await db.query('invoices', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final invoice = Invoice.fromMap(rows.first);
    final itemRows = await db.query('invoice_items', where: 'invoice_id=?', whereArgs: [id]);
    return invoice.copyWith(items: itemRows.map(InvoiceItem.fromMap).toList());
  }

  // ═══ DEBTS (سجل ديون ودفعات يدوية عامة) ═══
  Future<int> insertDebt(Debt d) async {
    final db = await database;
    return db.insert('debts', d.toMap());
  }

  Future<int> updateDebt(Debt d) async {
    final db = await database;
    return db.update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Debt>> getDebts({int? customerId, String? q}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
    }
    if (q != null && q.isNotEmpty) {
      conditions.add('customer_name LIKE ?');
      args.add('%$q%');
    }
    final rows = await db.query(
      'debts',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'debt_date DESC',
    );
    return rows.map(Debt.fromMap).toList();
  }

  /// إجمالي الدين الكلي على عميل بالدينار = ديون الفواتير غير المدفوعة + الديون اليدوية - الدفعات اليدوية
  /// (يتم تحويل أي مبلغ بالدولار للدينار باستخدام سعر الصرف المعطى لتفادي خلط العملتين)
  Future<double> getCustomerTotalDebt(int customerId, {double? exchangeRate}) async {
    final db = await database;
    final rate = exchangeRate ?? double.tryParse(await getSetting('exchange_rate_usd_iqd') ?? '') ?? 1500;

    double toIqd(double amount, String currency) =>
        currency == 'USD' ? amount * rate : amount;

    final invRows = await db.query(
      'invoices',
      where: "customer_id = ? AND status != 'canceled' AND total > paid_amount",
      whereArgs: [customerId],
    );
    double invoiceDebt = 0;
    for (final r in invRows) {
      final total = (r['total'] as num?)?.toDouble() ?? 0;
      final paid = (r['paid_amount'] as num?)?.toDouble() ?? 0;
      final currency = r['currency'] as String? ?? 'IQD';
      invoiceDebt += toIqd(total - paid, currency);
    }

    final debtRows = await db.query('debts', where: 'customer_id = ?', whereArgs: [customerId]);
    double manualDebt = 0;
    for (final r in debtRows) {
      final amount = (r['amount'] as num?)?.toDouble() ?? 0;
      final currency = r['currency'] as String? ?? 'IQD';
      final type = r['type'] as String? ?? 'debt';
      final signed = type == 'payment' ? -amount : amount;
      manualDebt += toIqd(signed, currency);
    }

    final result = invoiceDebt + manualDebt;
    return result < 0 ? 0 : result;
  }

  /// إجمالي الديون على كل العملاء بالدينار (للوحة التحكم وشاشة الديون)
  Future<double> getTotalDebts({double? exchangeRate}) async {
    final db = await database;
    final rate = exchangeRate ?? double.tryParse(await getSetting('exchange_rate_usd_iqd') ?? '') ?? 1500;

    double toIqd(double amount, String currency) =>
        currency == 'USD' ? amount * rate : amount;

    final invRows = await db.query(
      'invoices',
      where: "status != 'canceled' AND total > paid_amount",
    );
    double invoiceDebt = 0;
    for (final r in invRows) {
      final total = (r['total'] as num?)?.toDouble() ?? 0;
      final paid = (r['paid_amount'] as num?)?.toDouble() ?? 0;
      final currency = r['currency'] as String? ?? 'IQD';
      invoiceDebt += toIqd(total - paid, currency);
    }

    final debtRows = await db.query('debts');
    double manualDebt = 0;
    for (final r in debtRows) {
      final amount = (r['amount'] as num?)?.toDouble() ?? 0;
      final currency = r['currency'] as String? ?? 'IQD';
      final type = r['type'] as String? ?? 'debt';
      final signed = type == 'payment' ? -amount : amount;
      manualDebt += toIqd(signed, currency);
    }

    final result = invoiceDebt + manualDebt;
    return result < 0 ? 0 : result;
  }

  // ═══ PURCHASES (مشتريات المطبعة من الموردين) ═══
  Future<int> insertPurchase(Purchase p) async {
    final db = await database;
    return db.insert('purchases', p.toMap());
  }

  Future<int> updatePurchase(Purchase p) async {
    final db = await database;
    return db.update('purchases', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    return db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Purchase>> getPurchases({String? q}) async {
    final db = await database;
    final rows = q != null && q.isNotEmpty
        ? await db.query('purchases',
            where: 'supplier_name LIKE ? OR item_name LIKE ? OR category LIKE ?',
            whereArgs: ['%$q%', '%$q%', '%$q%'],
            orderBy: 'purchase_date DESC')
        : await db.query('purchases', orderBy: 'purchase_date DESC');
    return rows.map(Purchase.fromMap).toList();
  }

  /// إجمالي المشتريات بالدينار (يحوّل أي مشترى بالدولار للدينار حسب سعر الصرف الحالي)
  Future<double> getTotalPurchasesAmount({bool thisMonthOnly = false, double? exchangeRate}) async {
    final db = await database;
    final rate = exchangeRate ?? double.tryParse(await getSetting('exchange_rate_usd_iqd') ?? '') ?? 1500;
    final rows = thisMonthOnly
        ? await db.query('purchases', where: "strftime('%Y-%m',purchase_date)=strftime('%Y-%m','now')")
        : await db.query('purchases');
    double total = 0;
    for (final r in rows) {
      final amount = (r['total_price'] as num?)?.toDouble() ?? 0;
      final currency = r['currency'] as String? ?? 'IQD';
      total += currency == 'USD' ? amount * rate : amount;
    }
    return total;
  }

  // ═══ SETTINGS ═══
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key=?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String? ?? ''};
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setSettings(Map<String, String> map) async {
    final db = await database;
    final batch = db.batch();
    for (final e in map.entries) {
      batch.insert('settings', {'key': e.key, 'value': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ═══ STATS ═══
  static int _firstIntValue(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return 0;
    final value = rows.first.values.first;
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final customerCount =
        _firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers'));
    final invoiceCount =
        _firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices'));

    final totRow = await db.rawQuery('SELECT COALESCE(SUM(total),0) AS t FROM invoices');
    final monRow = await db.rawQuery(
        "SELECT COALESCE(SUM(total),0) AS t FROM invoices WHERE strftime('%Y-%m',created_at)=strftime('%Y-%m','now')");

    final totalDebts = await getTotalDebts();
    final totalPurchases = await getTotalPurchasesAmount();
    final monthPurchases = await getTotalPurchasesAmount(thisMonthOnly: true);

    return {
      'customerCount'   : customerCount,
      'invoiceCount'    : invoiceCount,
      'totalRevenue'    : (totRow.first['t'] as num).toDouble(),
      'monthRevenue'    : (monRow.first['t'] as num).toDouble(),
      'totalDebts'      : totalDebts,
      'totalPurchases'  : totalPurchases,
      'monthPurchases'  : monthPurchases,
    };
  }
}
