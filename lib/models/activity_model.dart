import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String name;
  final String image;
  final String description;
  final double price;
  final String city;
  final String category;

  ActivityModel({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.price,
    required this.city,
    required this.category,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      id: doc.id,
      name: d['name'] ?? '',
      image: d['image'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      city: d['city'] ?? '',
      category: d['category'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'image': image,
        'description': description,
        'price': price,
        'city': city,
        'category': category,
      };
}
