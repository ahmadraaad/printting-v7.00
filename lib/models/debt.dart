/// سجل دين أو دفعة يدوية على عميل، غير مرتبطة بفاتورة معينة.
/// type = 'debt'    => مبلغ مضاف على ذمة العميل (دين جديد)
/// type = 'payment' => دفعة من العميل تُخصم من إجمالي دينه
class Debt {
  final int? id;
  final int? customerId;
  final String customerName;
  final String type; // 'debt' | 'payment'
  final double amount;
  final String currency;
  final String? description;
  final String debtDate;
  final String createdAt;
  final String updatedAt;

  Debt({
    this.id,
    this.customerId,
    required this.customerName,
    this.type = 'debt',
    required this.amount,
    this.currency = 'IQD',
    this.description,
    String? debtDate,
    String? createdAt,
    String? updatedAt,
  })  : debtDate = debtDate ?? DateTime.now().toIso8601String(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isDebt    => type == 'debt';
  bool get isPayment => type == 'payment';

  /// الأثر على رصيد العميل: دين موجب (+) ودفعة سالبة (-)
  double get signedAmount => isPayment ? -amount : amount;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'customer_name': customerName,
        'type': type,
        'amount': amount,
        'currency': currency,
        'description': description ?? '',
        'debt_date': debtDate,
        'created_at': createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int?,
        customerName: map['customer_name'] as String,
        type: map['type'] as String? ?? 'debt',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'IQD',
        description: map['description'] as String?,
        debtDate: map['debt_date'] as String,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Debt copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? type,
    double? amount,
    String? currency,
    String? description,
    String? debtDate,
  }) =>
      Debt(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        description: description ?? this.description,
        debtDate: debtDate ?? this.debtDate,
        createdAt: createdAt,
      );
}
