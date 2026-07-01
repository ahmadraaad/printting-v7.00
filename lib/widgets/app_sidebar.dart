import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/theme_provider.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const AppSidebar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDark;

    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('شمس',
                        style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مطبعة شمس',
                          style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('للدعاية والإعلان',
                          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: AppStrings.home, selected: selectedIndex == 0, onTap: () => onTap(0)),
                _NavItem(icon: Icons.people_alt_rounded, label: AppStrings.customers, selected: selectedIndex == 1, onTap: () => onTap(1)),
                _NavItem(icon: Icons.inventory_2_rounded, label: AppStrings.items, selected: selectedIndex == 2, onTap: () => onTap(2)),
                _NavItem(icon: Icons.receipt_long_rounded, label: AppStrings.invoices, selected: selectedIndex == 3, onTap: () => onTap(3)),
                _NavItem(icon: Icons.account_balance_wallet_rounded, label: AppStrings.debts, selected: selectedIndex == 4, onTap: () => onTap(4)),
                _NavItem(icon: Icons.shopping_cart_rounded, label: AppStrings.purchases, selected: selectedIndex == 5, onTap: () => onTap(5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Column(
              children: [
                _NavItem(icon: Icons.settings_rounded, label: AppStrings.settings, selected: selectedIndex == 6, onTap: () => onTap(6)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => tp.toggleDark(),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Text(isDark ? 'وضع النهار' : 'الوضع الليلي',
                            style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.sidebarHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textMuted,
                    fontFamily: 'Cairo',
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
