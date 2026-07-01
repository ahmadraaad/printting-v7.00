import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import 'purchase_form.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PurchaseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.purchasesTitle,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addPurchase),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(label: AppStrings.totalPurchasesLabel, amount: prov.totalAmount, color: AppColors.warning)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(label: AppStrings.monthPurchasesLabel, amount: prov.monthAmount, color: AppColors.info)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => prov.search(v),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث باسم المورد أو المادة...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); prov.search(''); })
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : prov.purchases.isEmpty
                      ? const _Empty()
                      : ListView.separated(
                          itemCount: prov.purchases.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final p = prov.purchases[i];
                            return _PurchaseCard(
                              purchase: p,
                              onEdit: () => _openForm(context, purchase: p),
                              onDelete: () async {
                                if (await showConfirmDialog(context)) {
                                  await prov.delete(p.id!);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext ctx, {Purchase? purchase}) {
    showDialog(context: ctx, builder: (_) => PurchaseForm(purchase: purchase));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _StatCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.shopping_cart_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text('${NumberFormatter.compact(amount)} د.ع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 16, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PurchaseCard({required this.purchase, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.inventory_2_rounded, color: primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(purchase.itemName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  if (purchase.supplierName.isNotEmpty)
                    Text('المورد: ${purchase.supplierName}', style: const TextStyle(color: AppColors.textMedium, fontFamily: 'Cairo', fontSize: 12)),
                  Text(NumberFormatter.date(purchase.purchaseDate), style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${NumberFormatter.compact(purchase.totalPrice)} ${AppCurrency.symbol(purchase.currency)}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15, color: primary)),
                const SizedBox(height: 4),
                if (!purchase.isFullyPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text('متبقي ${NumberFormatter.compact(purchase.remainingAmount)} ${AppCurrency.symbol(purchase.currency)}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Text('مدفوع', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.delete_rounded), color: AppColors.error, onPressed: onDelete, tooltip: AppStrings.delete),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(AppStrings.noPurchases, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 15)),
        ],
      ),
    );
  }
}
