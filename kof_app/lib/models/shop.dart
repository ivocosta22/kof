import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final List<String> tags;
  final double? rating;
  final String? phone;
  final String? country;
  final String? serverUrl;

  const Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.tags = const [],
    this.rating,
    this.phone,
    this.country,
    this.serverUrl,
  });

  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final geo = data['location'];
    double lat = 0;
    double lng = 0;
    if (geo is GeoPoint) {
      lat = geo.latitude;
      lng = geo.longitude;
    } else if (geo is Map) {
      lat = (geo['lat'] as num?)?.toDouble() ?? 0;
      lng = (geo['lng'] as num?)?.toDouble() ?? 0;
    }
    return Shop(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      latitude: lat,
      longitude: lng,
      photoUrl: data['photoUrl'] as String?,
      tags: ((data['tags'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      rating: (data['rating'] as num?)?.toDouble(),
      phone: data['phone'] as String?,
      country: data['country'] as String?,
      serverUrl: data['serverUrl'] as String?,
    );
  }
}
