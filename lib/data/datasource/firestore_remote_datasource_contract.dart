import 'package:share_app/models/expense.dart';
import 'package:share_app/models/group.dart';
import 'package:share_app/models/member.dart';
import 'package:share_app/models/settlement.dart';

/// Contrato del datasource remoto de Cloud Firestore. Centraliza el acceso a
/// las colecciones `groups`, `groups/{groupId}/expenses` y
/// `groups/{groupId}/settlements`. Implementado en
/// `remote-data-source/firebase/firestore_remote_datasource.dart` (Fase 2-4).
abstract class FirestoreRemoteDataSourceContract {
  // --- groups ---
  Stream<List<Group>> watchGroups(String uid);

  Future<List<Group>> getGroups(String uid);

  Stream<Group> watchGroup(String groupId);

  Future<Group> createGroup(Group group);

  Future<Group> addMember(String groupId, Member member);

  Future<void> leaveGroup(String groupId, String uid);

  // --- expenses ---
  Stream<List<Expense>> watchExpenses(String groupId);

  Future<List<Expense>> getExpenses(String groupId);

  Future<Expense> addExpense(String groupId, Expense expense);

  Future<Expense> updateExpense(String groupId, Expense expense);

  Future<void> deleteExpense(String groupId, String expenseId);

  Future<void> addExpensesBatch(String groupId, List<Expense> expenses);

  // --- settlements ---
  Stream<List<Settlement>> watchSettlements(String groupId);

  Future<Settlement> addSettlement(String groupId, Settlement settlement);
}
