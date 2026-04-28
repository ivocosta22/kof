class ShopDiscount {
  final int id;
  final String title;
  final String description;
  final int percentageOff;
  final int amountOffCents;
  final String code;
  final String validFrom;
  final String validUntil;
  final bool isActive;

  const ShopDiscount({
    required this.id,
    required this.title,
    required this.description,
    required this.percentageOff,
    required this.amountOffCents,
    required this.code,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
  });

  factory ShopDiscount.fromJson(Map<String, dynamic> json) {
    return ShopDiscount(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      percentageOff: (json['percentage_off'] as num?)?.toInt() ?? 0,
      amountOffCents: (json['amount_off_cents'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      validFrom: json['valid_from'] as String? ?? '',
      validUntil: json['valid_until'] as String? ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
