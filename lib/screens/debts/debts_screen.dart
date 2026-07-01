import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/customer.dart';
import '../../models/debt.dart';
import '../../models/invoice.dart';
import '../../providers/customer_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../invoices/invoice_detail_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DebtProvider>();
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
                Text(AppStrings.debtsTitle,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addDebt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TotalDebtCard(amount: prov.totalDebts),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              tabs: const [
                Tab(text: AppStrings.unpaidInvoicesTab),
                Tab(text: AppStrings.customerDebtTab),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _UnpaidInvoicesTab(invoices: prov.unpaidInvoices, loading: prov.loading),
                  _ManualDebtsTab(
                    debts: prov.debts,
                    loading: prov.loading,
                    searchCtrl: _searchCtrl,
                    onSearch: (v) => prov.search(v),
                    onDelete: (d) async {
                      if (await showConfirmDialog(context)) {
                        await prov.delete(d.id!);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => const DebtForm());
  }
}

class _TotalDebtCard extends StatelessWidget {
  final double amount;
  const _TotalDebtCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.totalDebtsLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 1),
              const Text('(محوّل بالكامل لدينار)', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(NumberFormatter.compact(amount),
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.error)),
              const Text('د.ع', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnpaidInvoicesTab extends StatelessWidget {
  final List<Invoice> invoices;
  final bool loading;
  const _UnpaidInvoicesTab({required this.invoices, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('لا توجد فواتير عليها مبالغ متبقية', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo')),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final inv = invoices[i];
        return _UnpaidInvoiceCard(invoice: inv);
      },
    );
  }
}

class _UnpaidInvoiceCard extends StatelessWidget {
  final Invoice invoice;
  const _UnpaidInvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id!))),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long_rounded, color: primary, size: 20),
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
                      StatusBadge(invoice.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(invoice.customerName, style: const TextStyle(color: AppColors.textMedium, fontFamily: 'Cairo', fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('الإجمالي: ${NumberFormatter.compact(invoice.total)} ${AppCurrency.symbol(invoice.currency)}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text('المتبقي: ${NumberFormatter.compact(invoice.remainingAmount)} ${AppCurrency.symbol(invoice.currency)}',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualDebtsTab extends StatelessWidget {
  final List<Debt> debts;
  final bool loading;
  final TextEditingController searchCtrl;
  final void Function(String) onSearch;
  final void Function(Debt) onDelete;

  const _ManualDebtsTab({
    required this.debts,
    required this.loading,
    required this.searchCtrl,
    required this.onSearch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: onSearch,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'بحث باسم العميل...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchCtrl.clear(); onSearch(''); })
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : debts.isEmpty
                  ? const Center(child: Text(AppStrings.noDebts, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo')))
                  : ListView.separated(
                      itemCount: debts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final d = debts[i];
                        return _DebtCard(debt: d, onDelete: () => onDelete(d));
                      },
                    ),
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onDelete;
  const _DebtCard({required this.debt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = debt.isPayment ? AppColors.success : AppColors.error;

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(debt.isPayment ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.customerName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
                if ((debt.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(debt.description!, style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 11)),
                ],
                const SizedBox(height: 2),
                Text(NumberFormatter.date(debt.debtDate), style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 10)),
              ],
            ),
          ),
          Text(
            '${debt.isPayment ? '-' : '+'} ${NumberFormatter.compact(debt.amount)} ${AppCurrency.symbol(debt.currency)}',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14, color: color),
          ),
          IconButton(icon: const Icon(Icons.delete_rounded, size: 18), color: AppColors.error, onPressed: onDelete),
        ],
      ),
    );
  }
}

class DebtForm extends StatefulWidget {
  const DebtForm({super.key});

  @override
  State<DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends State<DebtForm> {
  Customer? _customer;
  String _type = 'debt';
  String _currency = AppCurrency.iqd;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_customer == null || (double.tryParse(_amountCtrl.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر العميل وأدخل مبلغاً صحيحاً', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _saving = true);
    final debt = Debt(
      customerId: _customer!.id,
      customerName: _customer!.name,
      type: _type,
      amount: double.parse(_amountCtrl.text),
      currency: _currency,
      description: _descCtrl.text.trim(),
    );
    final ok = await context.read<DebtProvider>().add(debt);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? AppStrings.saveSuccess : AppStrings.errorOccurred, style: const TextStyle(fontFamily: 'Cairo')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    return AlertDialog(
      title: const Text(AppStrings.addDebt, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Customer>(
              value: _customer,
              isExpanded: true,
              decoration: const InputDecoration(labelText: AppStrings.selectCustomer, prefixIcon: Icon(Icons.person_rounded, size: 18)),
              items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _customer = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(label: AppStrings.debtTypeDebt, selected: _type == 'debt', color: AppColors.error, onTap: () => setState(() => _type = 'debt')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeChip(label: AppStrings.debtTypePayment, selected: _type == 'payment', color: AppColors.success, onTap: () => setState(() => _type = 'payment')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('العملة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: AppCurrency.all.map((c) {
                        final sel = _currency == c;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currency = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(AppCurrency.label(c),
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.black54)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: '${AppStrings.debtAmount} (${AppCurrency.symbol(_currency)})', prefixIcon: const Icon(Icons.payments_rounded, size: 18)),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: AppStrings.debtDescription),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo'))),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          border: Border.all(color: selected ? color : AppColors.dividerLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 12, color: selected ? color : AppColors.textMuted)),
      ),
    );
  }
}
