/// Rol de un miembro dentro del grupo.
enum MemberRole { owner, member }

/// Miembro de un grupo. Se guarda como mapa dentro del documento del grupo
/// en Firestore (`groups/{groupId}.members.{uid}`).
class Member {
  final String memberId; // uid de Firebase Auth
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime joinedAt;
  final MemberRole role;

  /// Alias para compatibilidad con código que use displayName.
  String get displayName => name;
  /// Alias para compatibilidad con código que use id.
  String get id => memberId;

  Member({
    required this.memberId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.joinedAt,
    this.role = MemberRole.member,
  });

  factory Member.fromMap(String memberId, Map<String, dynamic> map) => Member(
        memberId: memberId,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        joinedAt: map['joinedAt'] != null
            ? DateTime.parse(map['joinedAt'] as String)
            : DateTime.now(),
        role: MemberRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => MemberRole.member,
        ),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt.toIso8601String(),
        'role': role.name,
      };

  Member copyWith({MemberRole? role}) => Member(
        memberId: memberId,
        name: name,
        email: email,
        photoUrl: photoUrl,
        joinedAt: joinedAt,
        role: role ?? this.role,
      );
}
