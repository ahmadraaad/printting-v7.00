class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? itemId;
  final String itemName;
  final String unit;
  final double? width;
  final double? height;
  final double quantity;
  final double? areaSqm;
  final double unitPrice;
  final double totalPrice;
  final String currency;
  final String? notes;

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.itemId,
    required this.itemName,
    required this.unit,
    this.width,
    this.height,
    required this.quantity,
    this.areaSqm,
    required this.unitPrice,
    required this.totalPrice,
    this.currency = 'IQD',
    this.notes,
  });

  static double? calcArea(double? w, double? h, String unit) {
    if (w == null || h == null) return null;
    switch (unit) {
      case 'ملم (mm)':
        return (w / 1000) * (h / 1000);
      case 'سم (cm)':
        return (w / 100) * (h / 100);
      case 'متر (m)':
        return w * h;
      case 'متر مربع (m²)':
        return w * h;
      default:
        return null;
    }
  }

  static double calcTotal({
    required String unit,
    double? width,
    double? height,
    required double quantity,
    required double unitPrice,
  }) {
    final area = calcArea(width, height, unit);
    if (area != null) {
      return area * quantity * unitPrice;
    }
    return quantity * unitPrice;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (invoiceId != null) 'invoice_id': invoiceId,
        'item_id': itemId,
        'item_name': itemName,
        'unit': unit,
        'width': width,
        'height': height,
        'quantity': quantity,
        'area_sqm': areaSqm,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'currency': currency,
        'notes': notes ?? '',
      };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
        id: map['id'] as int?,
        invoiceId: map['invoice_id'] as int?,
        itemId: map['item_id'] as int?,
        itemName: map['item_name'] as String,
        unit: map['unit'] as String? ?? 'عدد',
        width: (map['width'] as num?)?.toDouble(),
        height: (map['height'] as num?)?.toDouble(),
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
        areaSqm: (map['area_sqm'] as num?)?.toDouble(),
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'IQD',
        notes: map['notes'] as String?,
      );

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    String? itemName,
    String? unit,
    double? width,
    double? height,
    double? quantity,
    double? areaSqm,
    double? unitPrice,
    double? totalPrice,
    String? currency,
    String? notes,
  }) =>
      InvoiceItem(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        itemId: itemId ?? this.itemId,
        itemName: itemName ?? this.itemName,
        unit: unit ?? this.unit,
        width: width ?? this.width,
        height: height ?? this.height,
        quantity: quantity ?? this.quantity,
        areaSqm: areaSqm ?? this.areaSqm,
        unitPrice: unitPrice ?? this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
        currency: currency ?? this.currency,
        notes: notes ?? this.notes,
      );
}
