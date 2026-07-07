import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/domain/invoker/invoker.dart';
import 'package:share_app/domain/repository/balances_repository_contract.dart';
import 'package:share_app/domain/result/result.dart';
import 'package:share_app/domain/usecase/calculate_balances_use_case.dart';
import 'package:share_app/domain/usecase/get_balances_use_case.dart';
import 'package:share_app/domain/usecase/settle_up_use_case.dart';
import 'package:share_app/domain/usecase/watch_settlements_use_case.dart';
import 'package:share_app/models/balance.dart';
import 'package:share_app/models/settlement.dart';

// ── In-memory balances repo ───────────────────────────────────────────────────
class _FakeBalancesRepo implements BalancesRepositoryContract {
  List<MemberBalance> balances = [
    MemberBalance(memberId: 'alice', paid: 90, owed: 30),
    MemberBalance(memberId: 'bob', paid: 0, owed: 60),
    MemberBalance(memberId: 'charlie', paid: 0, owed: 0),
  ];
  final List<Settlement> _settlements = [];
  bool shouldThrow = false;

  @override
  Future<List<MemberBalance>> getBalances(String groupId) async {
    if (shouldThrow) throw Exception('get failed');
    return balances;
  }

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) =>
      Stream.value(List.unmodifiable(_settlements));

  @override
  Future<Settlement> settleUp(String groupId, Settlement settlement) async {
    if (shouldThrow) throw Exception('settle failed');
    _settlements.add(settlement);
    return settlement;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  late _FakeBalancesRepo repo;
  late Invoker invoker;

  setUp(() {
    repo = _FakeBalancesRepo();
    invoker = Invoker();
  });

  group('GetBalancesUseCase', () {
    test('éxito devuelve lista de balances', () async {
      final uc = GetBalancesUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      final list = results.first.data as List<MemberBalance>;
      expect(list.length, 3);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = GetBalancesUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('CalculateBalancesUseCase', () {
    test('éxito devuelve transferencias simplificadas', () async {
      final uc = CalculateBalancesUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      final transfers = results.first.data as List<DebtTransfer>;
      expect(transfers, isNotEmpty);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final uc = CalculateBalancesUseCase(repository: repo)..params = 'g1';
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });

    // Tests del algoritmo puro simplifyDebts
    group('simplifyDebts', () {
      test('dos miembros: un transfer', () {
        final transfers = CalculateBalancesUseCase.simplifyDebts([
          MemberBalance(memberId: 'alice', paid: 60, owed: 30),
          MemberBalance(memberId: 'bob', paid: 0, owed: 30),
        ]);
        expect(transfers.length, 1);
        expect(transfers.first.fromMemberId, 'bob');
        expect(transfers.first.toMemberId, 'alice');
        expect(transfers.first.amount, closeTo(30, 0.01));
      });

      test('tres miembros: minimiza transfers', () {
        final transfers = CalculateBalancesUseCase.simplifyDebts([
          MemberBalance(memberId: 'alice', paid: 90, owed: 30),
          MemberBalance(memberId: 'bob', paid: 0, owed: 30),
          MemberBalance(memberId: 'charlie', paid: 0, owed: 30),
        ]);
        // alice tiene +60, bob -30, charlie -30 → 2 transfers
        expect(transfers.length, 2);
      });

      test('balances en cero: sin transfers', () {
        final transfers = CalculateBalancesUseCase.simplifyDebts([
          MemberBalance(memberId: 'alice', paid: 30, owed: 30),
          MemberBalance(memberId: 'bob', paid: 30, owed: 30),
        ]);
        expect(transfers, isEmpty);
      });

      test('la suma de amounts de transfers cubre la deuda total', () {
        final balances = [
          MemberBalance(memberId: 'alice', paid: 120, owed: 40),
          MemberBalance(memberId: 'bob', paid: 0, owed: 40),
          MemberBalance(memberId: 'charlie', paid: 0, owed: 40),
        ];
        final transfers = CalculateBalancesUseCase.simplifyDebts(balances);
        final total = transfers.fold(0.0, (sum, t) => sum + t.amount);
        expect(total, closeTo(80, 0.01));
      });

      test('con tolerancia epsilon ignora diferencias de redondeo', () {
        final transfers = CalculateBalancesUseCase.simplifyDebts([
          MemberBalance(memberId: 'alice', paid: 100, owed: 33.34),
          MemberBalance(memberId: 'bob', paid: 0, owed: 33.33),
          MemberBalance(memberId: 'charlie', paid: 0, owed: 33.33),
        ]);
        // alice net ≈ +66.66, bob net ≈ -33.33, charlie net ≈ -33.33
        expect(transfers.length, lessThanOrEqualTo(2));
      });
    });
  });

  group('SettleUpUseCase', () {
    test('éxito devuelve la liquidación guardada', () async {
      final settlement = Settlement(settlementId: '', fromMemberId: 'bob', toMemberId: 'alice', amount: 30, date: DateTime(2024), currency: 'EUR');
      final uc = SettleUpUseCase(repository: repo)
        ..params = SettleUpParams(groupId: 'g1', settlement: settlement);
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Success>());
      expect(repo._settlements.length, 1);
    });

    test('fallo devuelve Error', () async {
      repo.shouldThrow = true;
      final settlement = Settlement(settlementId: '', fromMemberId: 'bob', toMemberId: 'alice', amount: 30, date: DateTime(2024), currency: 'EUR');
      final uc = SettleUpUseCase(repository: repo)
        ..params = SettleUpParams(groupId: 'g1', settlement: settlement);
      final results = await invoker.execute(uc).toList();
      expect(results.first, isA<Error>());
    });
  });

  group('WatchSettlementsUseCase', () {
    test('watch devuelve stream de liquidaciones', () async {
      repo._settlements.add(Settlement(settlementId: 's1', fromMemberId: 'bob', toMemberId: 'alice', amount: 30, date: DateTime(2024), currency: 'EUR'));
      final uc = WatchSettlementsUseCase(repository: repo);
      final list = await uc.watch('g1').first;
      expect(list.length, 1);
    });
  });
}
