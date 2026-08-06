import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';

/// Convierte un campo Firestore que puede ser `Timestamp` o `String` (ISO) a
/// `String` ISO, para que los modelos puedan hacer `DateTime.parse()` de forma
/// segura independientemente de cómo se almacenó el dato.
String? _toIsoString(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is String) return value;
  return null;
}

/// Normaliza los campos de fecha de un mapa de documento Firestore.
Map<String, dynamic> _normalizeExpenseMap(Map<String, dynamic> data) {
  final result = Map<String, dynamic>.from(data);
  result['date'] = _toIsoString(result['date']);
  result['createdAt'] = _toIsoString(result['createdAt']);
  return result;
}

Map<String, dynamic> _normalizeGroupMap(Map<String, dynamic> data) {
  final result = Map<String, dynamic>.from(data);
  result['createdAt'] = _toIsoString(result['createdAt']);
  // Normalizar fechas anidadas en members.<uid>.joinedAt
  final members = result['members'];
  if (members is Map) {
    // Construir explícitamente Map<String, dynamic> para que Group.fromMap
    // pueda castearlo sin TypeError.
    final normalized = <String, dynamic>{};
    for (final entry in members.entries) {
      final m = Map<String, dynamic>.from(entry.value as Map);
      m['joinedAt'] = _toIsoString(m['joinedAt']);
      normalized[entry.key.toString()] = m;
    }
    result['members'] = normalized;
  }
  return result;
}

/// Implementación de [FirestoreRemoteDataSourceContract] sobre Cloud
/// Firestore. Fase 2: grupos. Las operaciones de gastos/liquidaciones se
/// implementarán en las Fases 3-4.
class FirestoreRemoteDataSource implements FirestoreRemoteDataSourceContract {
  final FirebaseFirestore _firestore;

  FirestoreRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  }

  CollectionReference<Map<String, dynamic>> get _groups => _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> _expenses(String groupId) =>
      _groups.doc(groupId).collection('expenses');

  CollectionReference<Map<String, dynamic>> _settlements(String groupId) =>
      _groups.doc(groupId).collection('settlements');

  // --- groups ---

  @override
  Stream<List<Group>> watchGroups(String uid) {
    return _groups
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.id, _normalizeGroupMap(doc.data())))
            .toList());
  }

  @override
  Future<List<Group>> getGroups(String uid) async {
    final snapshot = await _groups.where('memberIds', arrayContains: uid).get();
    return snapshot.docs
        .map((doc) => Group.fromMap(doc.id, _normalizeGroupMap(doc.data())))
        .toList();
  }

  @override
  Stream<Group> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        throw Exception('El grupo $groupId no existe');
      }
      return Group.fromMap(doc.id, _normalizeGroupMap(data));
    });
  }

  @override
  Future<Group> createGroup(Group group) async {
    final docRef = _groups.doc();
    final newGroup = Group(
      groupId: docRef.id,
      name: group.name,
      currency: group.currency,
      createdBy: group.createdBy,
      createdAt: group.createdAt,
      memberIds: group.memberIds,
      members: group.members,
    );
    await docRef.set(newGroup.toMap());
    return newGroup;
  }

  @override
  Future<Group> addMember(String groupId, Member member) async {
    final docRef = _groups.doc(groupId);
    await docRef.update({
      'memberIds': FieldValue.arrayUnion([member.memberId]),
      'members.${member.memberId}': member.toMap(),
    });
    final doc = await docRef.get();
    final data = doc.data();
    if (data == null) {
      throw Exception('El grupo $groupId no existe');
    }
    return Group.fromMap(doc.id, data);
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'members.$uid': FieldValue.delete(),
    });
  }

  @override
  Future<void> updateMemberName(String groupId, String uid, String name) async {
    await _groups.doc(groupId).update({'members.$uid.name': name});
  }

  @override
  Future<void> updateGroup(String groupId, {required String name, required String currency}) async {
    await _groups.doc(groupId).update({'name': name, 'currency': currency});
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    // 1. Borrar subcolección expenses en batches.
    while (true) {
      final snap = await _expenses(groupId).limit(450).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // 2. Borrar subcolección settlements en batches.
    while (true) {
      final snap = await _settlements(groupId).limit(450).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // 3. Borrar el documento del grupo.
    await _groups.doc(groupId).delete();
  }

  // --- expenses (Fase 3) ---

  @override
  Stream<List<Expense>> watchExpenses(String groupId) {
    return _expenses(groupId).orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromMap(doc.id, _normalizeExpenseMap(doc.data())))
              .toList(),
        );
  }

  @override
  Future<List<Expense>> getExpenses(String groupId) async {
    final snapshot = await _expenses(groupId).orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => Expense.fromMap(doc.id, _normalizeExpenseMap(doc.data())))
        .toList();
  }

  @override
  Future<Expense> addExpense(String groupId, Expense expense) async {
    final docRef = _expenses(groupId).doc();
    final newExpense = Expense(
      expenseId: docRef.id,
      description: expense.description,
      amount: expense.amount,
      currency: expense.currency,
      category: expense.category,
      paidBy: expense.paidBy,
      createdBy: expense.createdBy,
      date: expense.date,
      createdAt: expense.createdAt,
      notes: expense.notes,
      splits: expense.splits,
      payments: expense.payments,
    );
    await docRef.set(newExpense.toMap());
    return newExpense;
  }

  @override
  Future<Expense> updateExpense(String groupId, Expense expense) async {
    await _expenses(groupId).doc(expense.expenseId).update(expense.toMap());
    return expense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _expenses(groupId).doc(expenseId).delete();
  }

  @override
  Future<int> deleteAllExpenses(String groupId) async {
    int deleted = 0;
    // Firestore no permite borrar una colección entera con una sola llamada;
    // se leen en batches de 450 y se borran con escritura en batch.
    while (true) {
      final snapshot = await _expenses(groupId).limit(450).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        deleted++;
      }
      await batch.commit();
    }
    return deleted;
  }

  @override
  Future<void> addExpensesBatch(String groupId, List<Expense> expenses) async {
    final collection = _expenses(groupId);
    // Firestore limita los batches a 500 operaciones.
    for (var i = 0; i < expenses.length; i += 450) {
      final chunk = expenses.skip(i).take(450);
      final batch = _firestore.batch();
      for (final expense in chunk) {
        final docRef = collection.doc();
        batch.set(
          docRef,
          Expense(
            expenseId: docRef.id,
            description: expense.description,
            amount: expense.amount,
            currency: expense.currency,
            category: expense.category,
            paidBy: expense.paidBy,
            createdBy: expense.createdBy,
            date: expense.date,
            createdAt: expense.createdAt,
            notes: expense.notes,
            splits: expense.splits,
            payments: expense.payments,
          ).toMap(),
        );
      }
      await batch.commit();
    }
  }

  // --- settlements (Fase 4, pendiente) ---

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) {
    return _settlements(groupId).orderBy('date', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Settlement.fromMap(doc.id, doc.data())).toList(),
        );
  }

  @override
  Future<Settlement> addSettlement(String groupId, Settlement settlement) async {
    final docRef = _settlements(groupId).doc();
    final newSettlement = Settlement(
      settlementId: docRef.id,
      fromMemberId: settlement.fromMemberId,
      toMemberId: settlement.toMemberId,
      amount: settlement.amount,
      date: settlement.date,
      notes: settlement.notes,
    );
    await docRef.set(newSettlement.toMap());
    return newSettlement;
  }

  // --- notifications ---

  CollectionReference<Map<String, dynamic>> _pending(String uid) =>
      _firestore.collection('notifications').doc(uid).collection('pending');

  @override
  Future<void> sendNotificationToUser(
      String recipientUid, Map<String, dynamic> payload) async {
    await _pending(recipientUid).add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchPendingNotifications(String uid) {
    return _pending(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  @override
  Future<void> deleteNotification(String uid, String notificationId) async {
    await _pending(uid).doc(notificationId).delete();
  }
}
