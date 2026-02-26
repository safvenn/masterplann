import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationModel {
  final String id;
  final String name;
  final String city;
  final String image;
  final String description;
  final double ticketPrice;
  final String timeToVisit;
  final String transport;
  final double transportPrice;

  DestinationModel({
    required this.id,
    required this.name,
    required this.city,
    required this.image,
    required this.description,
    required this.ticketPrice,
    required this.timeToVisit,
    required this.transport,
    required this.transportPrice,
  });

  factory DestinationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DestinationModel(
      id: doc.id,
      name: d['name'] ?? '',
      city: d['city'] ?? '',
      image: d['image'] ?? '',
      description: d['description'] ?? '',
      ticketPrice: (d['ticketPrice'] ?? 0).toDouble(),
      timeToVisit: d['timeToVisit'] ?? '',
      transport: d['transport'] ?? '',
      transportPrice: (d['transportPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'city': city,
    'image': image,
    'description': description,
    'ticketPrice': ticketPrice,
    'timeToVisit': timeToVisit,
    'transport': transport,
    'transportPrice': transportPrice,
  };
}
