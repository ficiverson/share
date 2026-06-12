/// Usuario autenticado con Google.
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

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
