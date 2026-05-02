import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/services/auth/firebase_auth_service.dart';

// Repositorio de autenticación que interactúa con FirebaseAuthService y Firestore para gestionar usuarios
class AuthRepository {
  AuthRepository(this._firebaseAuthService);

  final FirebaseAuthService _firebaseAuthService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  // Implementación de inicio de sesión con correo electrónico y contraseña, obteniendo el perfil completo
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return await _fetchUserModel(credential.user!.uid);
  }

  // Implementación de registro de usuario con información adicional
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String surname,
    required DateTime birthDate,
  }) async {
    final credential = await _firebaseAuthService
        .createUserWithEmailAndPassword(email: email, password: password);

    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      name: name,
      surname: surname,
      birthDate: birthDate,
      role: UserRole.customer,
      nauticalLicense: const NauticalLicense(
        type: 'none',
        documentUrl: '',
        status: 'verified',
      ),
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());

    return user;
  }

  // Implementación de inicio de sesión con Google, creando un perfil si es la primera vez
  Future<UserModel> signInWithGoogle() async {
    final credential = await _firebaseAuthService.signInWithGoogle();
    final uid = credential.user!.uid;

    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      final user = UserModel(
        uid: uid,
        email: credential.user!.email ?? '',
        name: credential.user!.displayName ?? '',
        surname: '',
        birthDate: null,
        role: UserRole.customer,
        nauticalLicense: const NauticalLicense(
          type: 'none',
          documentUrl: '',
          status: 'verified',
        ),
      );
      await _db.collection('users').doc(uid).set(user.toMap());
      return user;
    }

    return UserModel.fromMap(doc.data()!, uid);
  }

  // Implementación de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuthService.sendPasswordResetEmail(email: email);
  }

  // Implementación de obtención del usuario actual con perfil completo
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuthService.currentUser;
    if (firebaseUser == null) return null;
    return await _fetchUserModel(firebaseUser.uid);
  }

  // Implementación de cierre de sesión
  Future<void> signOut() => _firebaseAuthService.signOut();

  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Perfil no encontrado en Firestore.');
    return UserModel.fromMap(doc.data()!, uid);
  }
}
