class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isGuest;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isGuest = false,
  });

  factory User.guest() => const User(
        id: 'guest',
        name: 'Guest',
        email: '',
        isGuest: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        'isGuest': isGuest,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        isGuest: json['isGuest'] as bool? ?? false,
      );
}
