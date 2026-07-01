import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;

  final _statuses = <String?>[null, 'pending', 'paid', 'partial', 'canceled'];
  final _statusLabels = <String>['الكل', 'معلقة', 'مدفوعة', 'جزئي', 'ملغاة'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InvoiceProvider>();
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
                Text(AppStrings.invoices,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                ElevatedButton.icon(
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.newInvoice),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => prov.search(v),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'بحث برقم الفاتورة أو اسم العميل...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); prov.search(''); })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  children: List.generate(_statuses.length, (i) {
                    final sel = _statusFilter == _statuses[i];
                    return FilterChip(
                      label: Text(_statusLabels[i], style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      selected: sel,
                      onSelected: (_) {
                        setState(() => _statusFilter = _statuses[i]);
                        prov.filterStatus(_statuses[i]);
                      },
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : prov.invoices.isEmpty
                      ? const _Empty()
                      : ListView.separated(
                          itemCount: prov.invoices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final inv = prov.invoices[i];
                            return _InvoiceCard(
                              invoice: inv,
                              onTap: () => _openDetail(context, inv),
                              onDelete: () async {
                                if (await showConfirmDialog(context)) {
                                  await prov.delete(inv.id!);
                                }
                              },
                              onStatusChange: (s) => prov.setStatus(inv.id!, s),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreate(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
  }

  void _openDetail(BuildContext ctx, Invoice inv) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: inv.id!)));
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String) onStatusChange;

  const _InvoiceCard({required this.invoice, required this.onTap, required this.onDelete, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(invoice.invoiceNumber, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: invoice.isWholesale ? AppColors.infoLight : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(invoice.isWholesale ? AppStrings.wholesale : AppStrings.retail,
                            style: TextStyle(color: invoice.isWholesale ? AppColors.info : primary, fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(invoice.customerName, style: const TextStyle(color: AppColors.textMedium, fontFamily: 'Cairo', fontSize: 12)),
                  Text(NumberFormatter.date(invoice.createdAt), style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(NumberFormatter.compact(invoice.total), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16, color: primary)),
                Text(AppCurrency.symbol(invoice.currency), style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                StatusBadge(invoice.status),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (v) { if (v == 'delete') onDelete(); else onStatusChange(v); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'paid', child: Text('تحديد: مدفوعة', style: TextStyle(fontFamily: 'Cairo'))),
                const PopupMenuItem(value: 'partial', child: Text('تحديد: جزئي', style: TextStyle(fontFamily: 'Cairo'))),
                const PopupMenuItem(value: 'pending', child: Text('تحديد: معلقة', style: TextStyle(fontFamily: 'Cairo'))),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red))),
              ],
            ),
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
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(AppStrings.noInvoices, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 15)),
        ],
      ),
    );
  }
}
