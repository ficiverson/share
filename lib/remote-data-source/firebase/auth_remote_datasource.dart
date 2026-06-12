import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_app/data/datasource/auth_remote_datasource_contract.dart';
import 'package:share_app/models/user.dart';

/// Implementación de [AuthRemoteDataSourceContract] sobre Firebase Auth.
/// Para Google, usa `google_sign_in` solo para obtener el `idToken`/
/// `accessToken` y crear una [fb.GoogleAuthProvider] credential.
class AuthRemoteDataSource implements AuthRemoteDataSourceContract {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email', 'profile']);

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Inicio de sesión cancelado por el usuario');
    }
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('No se pudo obtener el usuario de Firebase');
    }
    return AppUser.fromFirebaseUser(user);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user == null) {
      throw Exception('No se pudo obtener el usuario de Firebase');
    }
    return AppUser.fromFirebaseUser(user);
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password, String displayName) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user == null) {
      throw Exception('No se pudo crear el usuario de Firebase');
    }
    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    return AppUser.fromFirebaseUser(user);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  AppUser? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AppUser.fromFirebaseUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser.fromFirebaseUser(user);
    });
  }
}
