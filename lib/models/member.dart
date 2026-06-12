/// Miembro de un grupo. Corresponde a una fila de la hoja "Members".
class Member {
  final String memberId;
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

  factory Member.fromRow(List<dynamic> row) => Member(
        memberId: row.isNotEmpty ? row[0].toString() : '',
        name: row.length > 1 ? row[1].toString() : '',
        email: row.length > 2 ? row[2].toString() : '',
        photoUrl: row.length > 3 && row[3].toString().isNotEmpty
            ? row[3].toString()
            : null,
        joinedAt: row.length > 4 && row[4].toString().isNotEmpty
            ? DateTime.parse(row[4].toString())
            : DateTime.now(),
      );

  List<dynamic> toRow() => [
        memberId,
        name,
        email,
        photoUrl ?? '',
        joinedAt.toIso8601String(),
      ];
}
