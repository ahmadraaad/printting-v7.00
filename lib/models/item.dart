class Item {
  final int? id;
  final String name;
  final String? description;
  final String unit;
  final double retailPrice;
  final double wholesalePrice;
  final String currency;
  final String? category;
  final String createdAt;
  final String updatedAt;

  static const List<String> supportedUnits = [
    'عدد',
    'متر مربع (m²)',
    'متر (m)',
    'سم (cm)',
    'ملم (mm)',
    'ورقة',
    'رول',
  ];

  Item({
    this.id,
    required this.name,
    this.description,
    required this.unit,
    required this.retailPrice,
    required this.wholesalePrice,
    this.currency = 'IQD',
    this.category,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get needsDimensions =>
      unit == 'متر مربع (m²)' ||
      unit == 'متر (m)' ||
      unit == 'سم (cm)' ||
      unit == 'ملم (mm)';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description ?? '',
        'unit': unit,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'currency': currency,
        'category': category ?? '',
        'created_at': createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        unit: map['unit'] as String? ?? 'عدد',
        retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'IQD',
        category: map['category'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Item copyWith({
    int? id,
    String? name,
    String? description,
    String? unit,
    double? retailPrice,
    double? wholesalePrice,
    String? currency,
    String? category,
  }) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        unit: unit ?? this.unit,
        retailPrice: retailPrice ?? this.retailPrice,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        createdAt: createdAt,
      );

  @override
  String toString() => name;
}
