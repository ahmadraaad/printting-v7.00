import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/confirm_dialog.dart';
import 'customer_form.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CustomerProvider>();
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
                Text(AppStrings.customers,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addCustomer),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => prov.search(v),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث باسم العميل أو الهاتف...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); prov.search(''); })
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : prov.customers.isEmpty
                      ? const _Empty()
                      : ListView.separated(
                          itemCount: prov.customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final c = prov.customers[i];
                            return _CustomerCard(
                              customer: c,
                              onEdit: () => _openForm(context, customer: c),
                              onDelete: () async {
                                if (await showConfirmDialog(context)) {
                                  await prov.delete(c.id!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text(AppStrings.deleteSuccess, style: TextStyle(fontFamily: 'Cairo'))),
                                    );
                                  }
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

  void _openForm(BuildContext ctx, {Customer? customer}) {
    showDialog(context: ctx, builder: (_) => CustomerForm(customer: customer));
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({required this.customer, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: Text(customer.name.isNotEmpty ? customer.name[0] : '؟',
                  style: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14)),
                if ((customer.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(customer.phone!, style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 12)),
                    ],
                  ),
                ],
                if ((customer.address ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(customer.address!,
                            style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit_rounded), color: AppColors.info, onPressed: onEdit, tooltip: AppStrings.edit),
              IconButton(icon: const Icon(Icons.delete_rounded), color: AppColors.error, onPressed: onDelete, tooltip: AppStrings.delete),
            ],
          ),
        ],
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
          Icon(Icons.people_outline_rounded, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(AppStrings.noCustomers, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 15)),
        ],
      ),
    );
  }
}
