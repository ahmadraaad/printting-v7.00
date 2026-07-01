/// سجل مشترى من مورد (خامات، حبر، ورق، إلخ) - مصاريف المحل
class Purchase {
  final int? id;
  final String supplierName;
  final String itemName;
  final String? category;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double totalPrice;
  final double paidAmount;
  final String currency;
  final String purchaseDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Purchase({
    this.id,
    this.supplierName = '',
    required this.itemName,
    this.category,
    this.quantity = 1,
    this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.paidAmount = 0,
    this.currency = 'IQD',
    String? purchaseDate,
    this.notes,
    String? createdAt,
    String? updatedAt,
  })  : purchaseDate = purchaseDate ?? DateTime.now().toIso8601String(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  double get remainingAmount {
    final r = totalPrice - paidAmount;
    return r < 0 ? 0 : r;
  }

  bool get isFullyPaid => remainingAmount <= 0.001;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'supplier_name': supplierName,
        'item_name': itemName,
        'category': category ?? '',
        'quantity': quantity,
        'unit': unit ?? '',
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'paid_amount': paidAmount,
        'currency': currency,
        'purchase_date': purchaseDate,
        'notes': notes ?? '',
        'created_at': createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
        id: map['id'] as int?,
        supplierName: map['supplier_name'] as String? ?? '',
        itemName: map['item_name'] as String,
        category: map['category'] as String?,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: map['unit'] as String?,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'IQD',
        purchaseDate: map['purchase_date'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Purchase copyWith({
    int? id,
    String? supplierName,
    String? itemName,
    String? category,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    double? paidAmount,
    String? currency,
    String? purchaseDate,
    String? notes,
  }) =>
      Purchase(
        id: id ?? this.id,
        supplierName: supplierName ?? this.supplierName,
        itemName: itemName ?? this.itemName,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        unitPrice: unitPrice ?? this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
        paidAmount: paidAmount ?? this.paidAmount,
        currency: currency ?? this.currency,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
