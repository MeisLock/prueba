





import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/services/auth/firebase_auth_service.dart';

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});