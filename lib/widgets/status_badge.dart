import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final info = _info(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withOpacity(0.3)),
      ),
      child: Text(info.label, style: TextStyle(color: info.color, fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  _StatusInfo _info(String s) {
    switch (s) {
      case 'paid':     return _StatusInfo('مدفوعة', AppColors.statusPaid);
      case 'partial':  return _StatusInfo('مدفوعة جزئياً', AppColors.statusPartial);
      case 'canceled': return _StatusInfo('ملغاة', AppColors.statusCanceled);
      default:         return _StatusInfo('معلقة', AppColors.statusPending);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}
