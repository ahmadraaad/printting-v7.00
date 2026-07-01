import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';

Future<bool> showConfirmDialog(BuildContext ctx, {String? message}) async {
  final result = await showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
        ],
      ),
      content: Text(message ?? AppStrings.deleteConfirm, style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(AppStrings.delete, style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}
