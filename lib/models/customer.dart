class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone ?? '',
        'email': email ?? '',
        'address': address ?? '',
        'notes': notes ?? '',
        'created_at': createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        address: map['address'] as String?,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  @override
  String toString() => name;
}
