/// Cómo se divide un gasto entre un miembro. Se guarda como elemento del
/// array `splits` dentro del documento de gasto en Firestore.
enum ShareType { equal, exact, percentage }

class Split {
  final String memberId;
  final double shareAmount;
  final ShareType shareType;

  Split({
    required this.memberId,
    required this.shareAmount,
    this.shareType = ShareType.equal,
  });

  factory Split.fromMap(Map<String, dynamic> map) => Split(
        memberId: map['memberId'] as String? ?? '',
        shareAmount: (map['shareAmount'] as num?)?.toDouble() ?? 0,
        shareType: ShareType.values.firstWhere(
          (e) => e.name == map['shareType'],
          orElse: () => ShareType.equal,
        ),
      );

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'shareAmount': shareAmount,
        'shareType': shareType.name,
      };
}
