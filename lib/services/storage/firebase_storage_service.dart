import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? firebaseStorage})
      : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseStorage _firebaseStorage;

  Future<String> uploadBoatImage({
    required String boatId,
    required XFile image,
  }) async {
    final file = File(image.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = _firebaseStorage.ref().child('boats/$boatId/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadLicenseDocument({
    required String uid,
    required XFile file,
  }) async {
    final fileToUpload = File(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _firebaseStorage.ref().child('licenses/$uid/$fileName');
    await ref.putFile(fileToUpload);
    return ref.getDownloadURL();
  }
}
