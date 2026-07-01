import 'invoice_item.dart';

class Invoice {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final String customerName;
  final String? customerPhone;
  final String invoiceType;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double total;
  final double paidAmount;
  final String currency;
  final double exchangeRate;
  final String? notes;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.invoiceType,
    required this.subtotal,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.total,
    this.paidAmount = 0,
    this.currency = 'IQD',
    this.exchangeRate = 1,
    this.notes,
    this.status = 'pending',
    String? createdAt,
    String? updatedAt,
    this.items = const [],
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isRetail    => invoiceType == 'retail';
  bool get isWholesale => invoiceType == 'wholesale';

  /// المبلغ المتبقي (الدين) على هذه الفاتورة، بعملة الفاتورة نفسها
  double get remainingAmount {
    final r = total - paidAmount;
    return r < 0 ? 0 : r;
  }

  /// هل الفاتورة مدفوعة بالكامل (بناءً على المبالغ الفعلية)
  bool get isFullyPaid => status != 'canceled' && remainingAmount <= 0.001;

  /// هل عليها مبلغ متبقٍ (دين) - الفواتير الملغاة لا تُحسب ديناً
  bool get hasOutstandingDebt => status != 'canceled' && remainingAmount > 0.001;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone ?? '',
        'invoice_type': invoiceType,
        'subtotal': subtotal,
        'discount_percent': discountPercent,
        'discount_amount': discountAmount,
        'total': total,
        'paid_amount': paidAmount,
        'currency': currency,
        'exchange_rate': exchangeRate,
        'notes': notes ?? '',
        'status': status,
        'created_at': createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
        id: map['id'] as int?,
        invoiceNumber: map['invoice_number'] as String,
        customerId: map['customer_id'] as int?,
        customerName: map['customer_name'] as String,
        customerPhone: map['customer_phone'] as String?,
        invoiceType: map['invoice_type'] as String? ?? 'retail',
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'IQD',
        exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
        notes: map['notes'] as String?,
        status: map['status'] as String? ?? 'pending',
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? invoiceType,
    double? subtotal,
    double? discountPercent,
    double? discountAmount,
    double? total,
    double? paidAmount,
    String? currency,
    double? exchangeRate,
    String? notes,
    String? status,
    List<InvoiceItem>? items,
  }) =>
      Invoice(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        invoiceType: invoiceType ?? this.invoiceType,
        subtotal: subtotal ?? this.subtotal,
        discountPercent: discountPercent ?? this.discountPercent,
        discountAmount: discountAmount ?? this.discountAmount,
        total: total ?? this.total,
        paidAmount: paidAmount ?? this.paidAmount,
        currency: currency ?? this.currency,
        exchangeRate: exchangeRate ?? this.exchangeRate,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt,
        items: items ?? this.items,
      );
}
