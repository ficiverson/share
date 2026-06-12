import 'member.dart';

/// Grupo de amigos. Cada grupo = 1 Spreadsheet de Google Sheets.
/// `spreadsheetId` es el id del archivo en Drive y actúa como `group_id`.
class Group {
  final String spreadsheetId;
  final String name;
  final String currency;
  final String createdBy;
  final DateTime createdAt;
  final List<Member> members;

  Group({
    required this.spreadsheetId,
    required this.name,
    required this.currency,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
  });

  /// Fila de la hoja "Info": group_id | name | currency | created_by | created_at
  List<dynamic> toInfoRow() => [
        spreadsheetId,
        name,
        currency,
        createdBy,
        createdAt.toIso8601String(),
      ];

  factory Group.fromInfoRow(List<dynamic> row, {List<Member> members = const []}) =>
      Group(
        spreadsheetId: row.isNotEmpty ? row[0].toString() : '',
        name: row.length > 1 ? row[1].toString() : '',
        currency: row.length > 2 ? row[2].toString() : 'EUR',
        createdBy: row.length > 3 ? row[3].toString() : '',
        createdAt: row.length > 4 && row[4].toString().isNotEmpty
            ? DateTime.parse(row[4].toString())
            : DateTime.now(),
        members: members,
      );

  Group copyWith({List<Member>? members}) => Group(
        spreadsheetId: spreadsheetId,
        name: name,
        currency: currency,
        createdBy: createdBy,
        createdAt: createdAt,
        members: members ?? this.members,
      );
}
