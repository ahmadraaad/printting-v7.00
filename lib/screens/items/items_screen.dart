import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_strings.dart';
import '../../models/item.dart';
import '../../providers/item_provider.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import 'item_form.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
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
                Text(AppStrings.items,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? Colors.white : AppColors.textDark)),
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addItem),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => prov.search(v),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث في المواد والخدمات...',
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
                  : prov.items.isEmpty
                      ? const _Empty()
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: prov.items.length,
                          itemBuilder: (ctx, i) {
                            final item = prov.items[i];
                            return _ItemCard(
                              item: item,
                              onEdit: () => _openForm(context, item: item),
                              onDelete: () async {
                                if (await showConfirmDialog(context)) {
                                  await prov.delete(item.id!);
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

  void _openForm(BuildContext ctx, {Item? item}) {
    showDialog(context: ctx, builder: (_) => ItemForm(item: item));
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({required this.item, required this.onEdit, required this.onDelete});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(item.name,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit_rounded, size: 16), color: AppColors.info, onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.delete_rounded, size: 16), color: AppColors.error, onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(item.unit, style: TextStyle(color: primary, fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.currency == AppCurrency.usd ? AppColors.warning.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(AppCurrency.label(item.currency),
                    style: TextStyle(
                        color: item.currency == AppCurrency.usd ? AppColors.warning : AppColors.success,
                        fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceChip(label: 'مفرد', value: '${NumberFormatter.compact(item.retailPrice)} ${AppCurrency.symbol(item.currency)}', color: AppColors.success),
              _PriceChip(label: 'جملة', value: '${NumberFormatter.compact(item.wholesalePrice)} ${AppCurrency.symbol(item.currency)}', color: AppColors.info),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
      ],
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
          Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(AppStrings.noItems, style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 15)),
        ],
      ),
    );
  }
}
