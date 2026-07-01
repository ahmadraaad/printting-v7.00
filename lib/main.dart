import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'providers/customer_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/item_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/items/items_screen.dart';
import 'screens/invoices/invoices_screen.dart';
import 'screens/debts/debts_screen.dart';
import 'screens/purchases/purchases_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/app_sidebar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize SQLite FFI for Windows desktop ─────────────────────────
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // ── Initialize window manager (Windows desktop sizing) ────────────────
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(1100, 700),
    center: true,
    title: AppStrings.appName,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ShamsApp());
}

class ShamsApp extends StatelessWidget {
  const ShamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(tp.primary),
            darkTheme: AppTheme.dark(tp.primary),
            themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

/// Main application shell: sidebar + content area
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _navigate(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeScreen(onNavigate: _navigate),
      const CustomersScreen(),
      const ItemsScreen(),
      const InvoicesScreen(),
      const DebtsScreen(),
      const PurchasesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Container(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            AppSidebar(selectedIndex: _selectedIndex, onTap: _navigate),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
