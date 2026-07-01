import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/database_helper.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await DatabaseHelper.instance.getStats();
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoices = context.watch<InvoiceProvider>().invoices.take(6).toList();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مرحباً بك 👋',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white : AppColors.textDark,
                              )),
                          Text(NumberFormatter.todayDate(),
                              style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(3),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(AppStrings.newInvoice),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(title: AppStrings.totalInvoices, value: '${_stats['invoiceCount'] ?? 0}', icon: Icons.receipt_long_rounded, color: primary),
                      StatCard(title: AppStrings.totalCustomers, value: '${_stats['customerCount'] ?? 0}', icon: Icons.people_alt_rounded, color: AppColors.info),
                      StatCard(
                        title: AppStrings.monthRevenue,
                        value: NumberFormatter.compact((_stats['monthRevenue'] as double?) ?? 0),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        subtitle: 'هذا الشهر',
                      ),
                      StatCard(
                        title: AppStrings.totalRevenue,
                        value: NumberFormatter.compact((_stats['totalRevenue'] as double?) ?? 0),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3,
                    children: [
                      StatCard(
                        title: AppStrings.totalDebtsLabel,
                        value: NumberFormatter.compact((_stats['totalDebts'] as double?) ?? 0),
                        icon: Icons.money_off_csred_rounded,
                        color: AppColors.error,
                        onTap: () => widget.onNavigate(4),
                      ),
                      StatCard(
                        title: AppStrings.monthPurchasesLabel,
                        value: NumberFormatter.compact((_stats['monthPurchases'] as double?) ?? 0),
                        icon: Icons.shopping_cart_rounded,
                        color: AppColors.warning,
                        onTap: () => widget.onNavigate(5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(AppStrings.quickActions,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickBtn(icon: Icons.receipt_long_rounded, label: 'فاتورة جديدة', color: primary, onTap: () => widget.onNavigate(3)),
                      const SizedBox(width: 12),
                      _QuickBtn(icon: Icons.person_add_rounded, label: 'إضافة عميل', color: AppColors.info, onTap: () => widget.onNavigate(1)),
                      const SizedBox(width: 12),
                      _QuickBtn(icon: Icons.add_box_rounded, label: 'إضافة مادة', color: AppColors.success, onTap: () => widget.onNavigate(2)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.recentInvoices,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                      TextButton(onPressed: () => widget.onNavigate(3), child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (invoices.isEmpty)
                    const _EmptyState()
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
                      ),
                      child: Column(
                        children: invoices.asMap().entries.map((e) {
                          final i = e.key;
                          final inv = e.value;
                          return Column(
                            children: [
                              _InvoiceRow(inv),
                              if (i < invoices.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice inv;
  const _InvoiceRow(this.inv);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.customerName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13)),
                Text(inv.invoiceNumber, style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(NumberFormatter.compact(inv.total),
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 4),
              StatusBadge(inv.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(AppStrings.noInvoices, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 14)),
        ],
      ),
    );
  }
}
