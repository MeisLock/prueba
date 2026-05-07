import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_rent/models/rental_request.dart';
import 'package:ocean_rent/models/boat_model.dart';

class RentalRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // guarda una solicitud de alquiler en la colección rental_requests.
  Future<void> createRentalRequest(RentalRequest request) async {
    await _firestore.collection('rental_requests').add(request.toMap());
  }

  // obtiene todas las solicitudes de alquiler en tiempo real
  Stream<List<RentalRequest>> getRentalRequests() {
    return _firestore
        .collection('rental_requests')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RentalRequest.fromFirestore(doc))
              .toList(),
        );
  }

  // Consulta los barcos disponibles en un rango de fechas.
  Future<List<BoatModel>> getAvailableBoatsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final boatsSnapshot = await _firestore.collection('boats').get();

    final rentalRequestsSnapshot = await _firestore
        .collection('rental_requests')
        .where('status', whereIn: ['pending', 'accepted'])
        .get();

    final unavailableBoatIds = rentalRequestsSnapshot.docs
        .map((doc) => RentalRequest.fromFirestore(doc))
        .where((request) {
          final hasDateOverlap =
              startDate.isBefore(request.endDate) &&
              endDate.isAfter(request.startDate);

          return hasDateOverlap;
        })
        .map((request) => request.boatId)
        .toSet();

    return boatsSnapshot.docs
        .map((doc) => BoatModel.fromMap(doc.data(), doc.id))
        .where((boat) => boat.isAvailable)
        .where((boat) => !unavailableBoatIds.contains(boat.id))
        .toList();
  }
}
