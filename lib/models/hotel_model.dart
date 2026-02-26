import 'package:cloud_firestore/cloud_firestore.dart';

class HotelModel {
  final String id;
  final String name;
  final String city;
  final String image;
  final int stars;
  final double pricePerNight;
  final double rating;
  final String description;
  final List<String> amenities;

  HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.image,
    required this.stars,
    required this.pricePerNight,
    required this.rating,
    required this.description,
    this.amenities = const [],
  });

  factory HotelModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HotelModel(
      id: doc.id,
      name: d['name'] ?? '',
      city: d['city'] ?? '',
      image: d['image'] ?? '',
      stars: (d['stars'] ?? 3).toInt(),
      pricePerNight: (d['pricePerNight'] ?? 0).toDouble(),
      rating: (d['rating'] ?? 0).toDouble(),
      description: d['description'] ?? '',
      amenities: List<String>.from(d['amenities'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'city': city,
    'image': image,
    'stars': stars,
    'pricePerNight': pricePerNight,
    'rating': rating,
    'description': description,
    'amenities': amenities,
  };
}
