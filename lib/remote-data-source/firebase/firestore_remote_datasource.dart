import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_app/data/datasource/firestore_remote_datasource_contract.dart';
import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';

/// Implementación de [FirestoreRemoteDataSourceContract] sobre Cloud
/// Firestore. Fase 2: grupos. Las operaciones de gastos/liquidaciones se
/// implementarán en las Fases 3-4.
class FirestoreRemoteDataSource implements FirestoreRemoteDataSourceContract {
  final FirebaseFirestore _firestore;

  FirestoreRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
        .map((snapshot) => snapshot.docs.map((doc) => Group.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Future<List<Group>> getGroups(String uid) async {
    final snapshot = await _groups.where('memberIds', arrayContains: uid).get();
    return snapshot.docs.map((doc) => Group.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Stream<Group> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        throw Exception('El grupo $groupId no existe');
      }
      return Group.fromMap(doc.id, data);
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

  // --- expenses (Fase 3) ---

  @override
  Stream<List<Expense>> watchExpenses(String groupId) {
    return _expenses(groupId).orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList(),
        );
  }

  @override
  Future<List<Expense>> getExpenses(String groupId) async {
    final snapshot = await _expenses(groupId).orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
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
      date: expense.date,
      createdAt: expense.createdAt,
      notes: expense.notes,
      splits: expense.splits,
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
            date: expense.date,
            createdAt: expense.createdAt,
            notes: expense.notes,
            splits: expense.splits,
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
}
