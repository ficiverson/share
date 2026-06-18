import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_app/data/datasource/auth_remote_datasource_contract.dart';
import 'package:share_app/models/user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  Future<AppUser> signInWithApple() async {
    final fb.UserCredential userCredential;

    if (kIsWeb) {
      // En web Firebase gestiona el popup directamente.
      final provider = fb.OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      userCredential = await _firebaseAuth.signInWithPopup(provider);
    } else {
      // En móvil usamos sign_in_with_apple para obtener el idToken con nonce.
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
    }

    final user = userCredential.user;
    if (user == null) throw Exception('No se pudo obtener el usuario de Firebase');
    return AppUser.fromFirebaseUser(user);
  }

  /// Genera un nonce aleatorio de 32 bytes en Base64 URL-safe.
  String _generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
