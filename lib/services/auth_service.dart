import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import '../core/config/env_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: EnvConfig.googleAndroidClientId.isNotEmpty
          ? EnvConfig.googleAndroidClientId
          : null,
    );
  }
  final FirestoreService _firestoreService = FirestoreService();

  // Stream para cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Sign in con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      final User? user = result.user;

      // Crear documento de usuario en Firestore si no existe
      if (user != null) {
        await _createUserDocument(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException en Google Sign In: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('Error en Google Sign In: $e');
      rethrow;
    }
  }

  // Sign in con email y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      rethrow;
    }
  }

  // Registrarse con email
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await _createUserDocument(user);
      }

      return user;
    } catch (e) {
      print('Error al registrarse: $e');
      rethrow;
    }
  }

  // Crear documento de usuario en Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      final existingUser = await _firestoreService.getUser(user.uid);
      if (existingUser == null) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Usuario',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          plan: 'free',
          storageUsed: 0,
          maxStorage: 1073741824, // 1GB para free
        );
        await _firestoreService.createUser(newUser);
      }
    } catch (e) {
      print('Error creando documento de usuario: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Obtener datos del usuario
  Future<UserModel?> getUserData(String uid) async {
    return await _firestoreService.getUser(uid);
  }

  // Stream de datos del usuario
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestoreService.getUserStream(uid);
  }

  // Actualizar datos del usuario
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateUser(uid, data);
    } catch (e) {
      print('Error actualizando usuario: $e');
      rethrow;
    }
  }
}
