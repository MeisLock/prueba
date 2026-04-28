class Boat {
  final String id;
  final String name;
  final String type;
  final int capacity;
  final double pricePerDay;
  final String description;
  final String imageUrl;

  const Boat({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.pricePerDay,
    required this.description,
    required this.imageUrl,
  });

  factory Boat.fromMap(Map<String, dynamic> map, String documentId) {
    return Boat(
      id: documentId,
      name: (map['name'] ?? '') as String,
      type: (map['category'] ?? '') as String,
      capacity: (map['capacity'] ?? 0) as int,
      pricePerDay: (map['price_per_day'] ?? 0).toDouble(),
      description: (map['description'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'capacity': capacity,
      'price_per_day': pricePerDay,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
