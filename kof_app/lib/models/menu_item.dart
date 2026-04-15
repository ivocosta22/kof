class MenuItem {
  final int id;
  final String name;
  final String description;
  final int priceCents;
  final String availability;
  final int? maxMakeableUnits;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.availability,
    this.maxMakeableUnits,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      priceCents: json['price_cents'] as int,
      availability: json['availability'] as String? ?? 'available',
      maxMakeableUnits: json['max_makeable_units'] as int?,
    );
  }

  bool get isOrderable =>
      availability == 'available' ||
      availability == 'low' ||
      availability == 'no_recipe';
}
