import 'member.dart';

/// Grupo de amigos. Cada grupo = 1 documento en la colección `groups` de
/// Firestore. `groupId` es el id del documento.
class Group {
  final String groupId;
  final String name;
  final String currency;
  final String createdBy; // uid del creador
  final DateTime createdAt;

  /// uids de todos los miembros del grupo (incluye al creador). Se usa para
  /// las reglas de seguridad de Firestore (`request.auth.uid in memberIds`).
  final List<String> memberIds;

  /// Datos de cada miembro, indexados por uid.
  final List<Member> members;

  Group({
    required this.groupId,
    required this.name,
    required this.currency,
    required this.createdBy,
    required this.createdAt,
    this.memberIds = const [],
    this.members = const [],
  });

  /// Documento `groups/{groupId}`.
  Map<String, dynamic> toMap() => {
        'name': name,
        'currency': currency,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'memberIds': memberIds,
        'members': {for (final m in members) m.memberId: m.toMap()},
      };

  factory Group.fromMap(String groupId, Map<String, dynamic> map) {
    final membersMap = (map['members'] as Map<String, dynamic>?) ?? {};
    return Group(
      groupId: groupId,
      name: map['name'] as String? ?? '',
      currency: map['currency'] as String? ?? 'EUR',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
      members: membersMap.entries
          .map((e) => Member.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList(),
    );
  }

  Group copyWith({List<Member>? members, List<String>? memberIds}) => Group(
        groupId: groupId,
        name: name,
        currency: currency,
        createdBy: createdBy,
        createdAt: createdAt,
        memberIds: memberIds ?? this.memberIds,
        members: members ?? this.members,
      );
}
