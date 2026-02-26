import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final bool isAdmin;
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.isAdmin = false,
    DateTime? createdAt,
    this.photoUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: d['email'] ?? '',
      name: d['name'] ?? '',
      isAdmin: d['isAdmin'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: d['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'isAdmin': isAdmin,
        'createdAt': Timestamp.fromDate(createdAt),
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  UserModel copyWith({
    String? name,
    String? photoUrl,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        isAdmin: isAdmin,
        createdAt: createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
