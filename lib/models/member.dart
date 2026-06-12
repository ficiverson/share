/// Miembro de un grupo. Se guarda como mapa dentro del documento del grupo
/// en Firestore (`groups/{groupId}.members.{uid}`).
class Member {
  final String memberId; // uid de Firebase Auth
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime joinedAt;

  Member({
    required this.memberId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.joinedAt,
  });

  factory Member.fromMap(String memberId, Map<String, dynamic> map) => Member(
        memberId: memberId,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        joinedAt: map['joinedAt'] != null
            ? DateTime.parse(map['joinedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt.toIso8601String(),
      };
}
