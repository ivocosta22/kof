class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final bool isGuest;
  final bool emailVerified;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.isGuest = false,
    this.emailVerified = false,
  });

  factory User.guest() => const User(
        id: 'guest',
        name: 'Guest',
        email: '',
        isGuest: true,
      );

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    bool? emailVerified,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        isGuest: isGuest,
        emailVerified: emailVerified ?? this.emailVerified,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'isGuest': isGuest,
        'emailVerified': emailVerified,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        photoUrl: json['photoUrl'] as String?,
        isGuest: json['isGuest'] as bool? ?? false,
        emailVerified: json['emailVerified'] as bool? ?? false,
      );
}
