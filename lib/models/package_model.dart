import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String name;
  final String city;
  final String country;
  final String image;
  final double basePrice;
  final int minDays;
  final int maxDays;
  final double rating;
  final int reviews;
  final String category;
  final String difficulty;
  final String description;
  final List<String> highlights;
  final List<String> hotelIds;
  final List<String> destinationIds;
  final List<String> activityIds;
  final DateTime createdAt;

  PackageModel({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.image,
    required this.basePrice,
    required this.minDays,
    required this.maxDays,
    required this.rating,
    required this.reviews,
    required this.category,
    required this.difficulty,
    required this.description,
    this.highlights = const [],
    this.hotelIds = const [],
    this.destinationIds = const [],
    this.activityIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: d['name'] ?? '',
      city: d['city'] ?? '',
      country: d['country'] ?? '',
      image: d['image'] ?? '',
      basePrice: (d['basePrice'] ?? 0).toDouble(),
      minDays: (d['minDays'] ?? 1).toInt(),
      maxDays: (d['maxDays'] ?? 14).toInt(),
      rating: (d['rating'] ?? 0).toDouble(),
      reviews: (d['reviews'] ?? 0).toInt(),
      category: d['category'] ?? 'Cultural',
      difficulty: d['difficulty'] ?? 'Easy',
      description: d['description'] ?? '',
      highlights: List<String>.from(d['highlights'] ?? []),
      hotelIds: List<String>.from(d['hotelIds'] ?? []),
      destinationIds: List<String>.from(d['destinationIds'] ?? []),
      activityIds: List<String>.from(d['activityIds'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'city': city,
    'country': country,
    'image': image,
    'basePrice': basePrice,
    'minDays': minDays,
    'maxDays': maxDays,
    'rating': rating,
    'reviews': reviews,
    'category': category,
    'difficulty': difficulty,
    'description': description,
    'highlights': highlights,
    'hotelIds': hotelIds,
    'destinationIds': destinationIds,
    'activityIds': activityIds,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  PackageModel copyWith({
    String? name, String? city, String? country, String? image,
    double? basePrice, int? minDays, int? maxDays, double? rating,
    int? reviews, String? category, String? difficulty, String? description,
    List<String>? highlights, List<String>? hotelIds,
    List<String>? destinationIds, List<String>? activityIds,
  }) => PackageModel(
    id: id,
    name: name ?? this.name,
    city: city ?? this.city,
    country: country ?? this.country,
    image: image ?? this.image,
    basePrice: basePrice ?? this.basePrice,
    minDays: minDays ?? this.minDays,
    maxDays: maxDays ?? this.maxDays,
    rating: rating ?? this.rating,
    reviews: reviews ?? this.reviews,
    category: category ?? this.category,
    difficulty: difficulty ?? this.difficulty,
    description: description ?? this.description,
    highlights: highlights ?? this.highlights,
    hotelIds: hotelIds ?? this.hotelIds,
    destinationIds: destinationIds ?? this.destinationIds,
    activityIds: activityIds ?? this.activityIds,
    createdAt: createdAt,
  );
}
