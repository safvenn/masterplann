import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final bool isVendor;
  final bool isAdmin;
  final DateTime createdAt;
  final String? photoUrl;

  // Vendor specific details
  final String? businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? description;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.isVendor = false,
    this.isAdmin = false,
    DateTime? createdAt,
    this.photoUrl,
    this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.description,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: d['email'] ?? '',
      name: d['name'] ?? '',
      isVendor: d['isVendor'] ?? false,
      isAdmin: d['isAdmin'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: d['photoUrl'],
      businessName: d['businessName'],
      businessAddress: d['businessAddress'],
      businessPhone: d['businessPhone'],
      description: d['description'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'isVendor': isVendor,
        'isAdmin': isAdmin,
        'createdAt': Timestamp.fromDate(createdAt),
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (businessName != null) 'businessName': businessName,
        if (businessAddress != null) 'businessAddress': businessAddress,
        if (businessPhone != null) 'businessPhone': businessPhone,
        if (description != null) 'description': description,
      };

  UserModel copyWith({
    String? name,
    String? photoUrl,
    bool? isVendor,
    bool? isAdmin,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? description,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        isVendor: isVendor ?? this.isVendor,
        isAdmin: isAdmin ?? this.isAdmin,
        createdAt: createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        businessName: businessName ?? this.businessName,
        businessAddress: businessAddress ?? this.businessAddress,
        businessPhone: businessPhone ?? this.businessPhone,
        description: description ?? this.description,
      );
}
