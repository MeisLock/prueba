import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'boat_model.g.dart';

@HiveType(typeId: 0)

class BoatModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final int capacity;
  @HiveField(4)
  final double pricePerDay;
  @HiveField(5)
  final String description;
  @HiveField(6)
  final String imageUrl;
  @HiveField(7)
  final double depositAmount;
  @HiveField(8)
  final bool isAvailable;
  @HiveField(9)
  final String portName;
  @HiveField(10)
  final double ratingAvg;
  @HiveField(11)
  final int ratingCount;
  @HiveField(12)
  final String requiredLicense;
  
  final GeoPoint? location;



  const BoatModel({
    required this.id,
    required this.name,
    required this.category,
    required this.capacity,
    required this.pricePerDay,
    required this.description,
    required this.imageUrl, 
    required this.depositAmount, 
    required this.isAvailable, 
    required this.portName, 
    required this.ratingAvg, 
    required this.ratingCount, 
    required this.requiredLicense, 
    this.location,
  });

  factory BoatModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BoatModel(
      id: documentId,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      capacity: (map['capacity'] ?? 0) as int,
      pricePerDay: (map['price_per_day'] ?? 0).toDouble(),
      description: (map['description'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String, 
      depositAmount: (map['deposit_amount'] ?? 0).toDouble(), 
      isAvailable: (map['is_available'] ?? false) as bool,  
      portName: (map['port_name'] ?? '') as String, 
      ratingAvg: (map['rating_avg'] ?? 0).toDouble(), 
      ratingCount: (map['rating_count'] ?? 0) as int, 
      requiredLicense: (map['required_license'] ?? 'Indeterminado') as String, 
      location: map['location'] != null ? map['location'] as GeoPoint : null,
    );
  }

  Map<String, dynamic> toMap() {
  return {
    'name': name,
    'category': category,
    'capacity': capacity,
    'price_per_day': pricePerDay,
    'description': description,
    'imageUrl': imageUrl,
    'deposit_amount': depositAmount,
    'is_available': isAvailable,
    'port_name': portName,
    'rating_avg': ratingAvg,
    'rating_count': ratingCount,
    'required_license': requiredLicense,
    'location': location,
  };
  }
}
