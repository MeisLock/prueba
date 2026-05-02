import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequest {
  final String id;
  final String boatId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;

  RentalRequest({
    required this.id,
    required this.boatId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  // Convierte el objeto RentalRequest en un Map para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'boatId': boatId,
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Crea un objeto RentalRequest a partir de un documento leído desde Firestore
  factory RentalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RentalRequest(
      id: doc.id,
      boatId: data['boatId'] ?? '',
      userId: data['userId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}