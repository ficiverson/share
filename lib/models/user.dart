import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Usuario autenticado (Firebase Auth, vía Google o email/contraseña).
class AppUser {
  final String id; // Firebase Auth uid
  final String email;
  final String displayName;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromFirebaseUser(fb.User user) => AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: (user.displayName?.isNotEmpty ?? false) ? user.displayName! : (user.email ?? ''),
        photoUrl: user.photoURL,
      );

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };
}
