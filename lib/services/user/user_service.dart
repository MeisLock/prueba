import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_rent/models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<UserModel> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String surname,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'name': name,
      'surname': surname,
    });
  }

  Future<void> updateNauticalLicense({
    required String uid,
    required String type,
    required String documentUrl,
    required String status,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'nautical_license.type': type,
      'nautical_license.document_url': documentUrl,
      'nautical_license.status': status,
    });
  }
}

