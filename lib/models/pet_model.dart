import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String? id;
  final String name;
  final String breed;
  final String color;
  final String location;
  final String imageUrl;
  final String status; // "lost" or "found"
  final DateTime timestamp;
  final String userId;
  final double latitude;
  final double longitude;
  final String? description;
  final List<String>? tags;

  PetModel({
    this.id,
    required this.name,
    required this.breed,
    required this.color,
    required this.location,
    required this.imageUrl,
    required this.status,
    required this.timestamp,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.description,
    this.tags,
  });

  factory PetModel.fromMap(Map<String, dynamic> map, String id) {
    return PetModel(
      id: id,
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      color: map['color'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? 'lost',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      description: map['description'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'color': color,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'timestamp': timestamp,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'tags': tags,
    };
  }
}
      