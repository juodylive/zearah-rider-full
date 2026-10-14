import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/data_store.dart';
import '../../../data/repositories/wallet_repository.dart';

class WalletTx extends Equatable {
  final String type; // credit | debit
  final String description;
  final String amount;
  final String date;
  const WalletTx(this.type, this.description, this.amount, this.date);
  bool get isCredit => type.toLowerCase() == 'credit';
  @override
  List<Object?> get props => [type, description, amount, date];
}

class WalletState extends Equatable {
  final bool loading;
  final String? balance; // null = unknown
  final List<WalletTx> transactions;
  final bool balanceFromServer;
  const WalletState({
    this.loading = false,
    this.balance,
    this.transactions = const [],
    this.balanceFromServer = false,
  });
  @override
  List<Object?> get props =>
      [loading, balance, transactions, balanceFromServer];
}

class WalletCubit extends Cubit<WalletState> {
  final WalletRepository repository;
  WalletCubit(this.repository) : super(WalletState(balance: _storedBalance()));

  /// Balance saved at login (may be stale until the server call succeeds).
  static String? _storedBalance() {
    try {
      final raw = box.get("UserData");
      if (raw == null) return null;
      final m = jsonDecode(raw.toString());
      dynamic v = m is Map ? m['wallet'] : null;
      if (v == null && m is Map && m['data'] is Map) v = m['data']['wallet'];
      return v?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Current balance as a number (0 when unknown).
  double get balanceValue => double.tryParse(state.balance ?? '') ?? 0;

  Future<void> load() async {
    emit(WalletState(
        loading: true,
        balance: state.balance,
        transactions: state.transactions,
        balanceFromServer: state.balanceFromServer));
    String? balance = state.balance;
    bool fromServer = false;
    var txs = <WalletTx>[];
    try {
      final w = await repository.getWallet();
      if (w['status'] == 200 && w['data'] is Map) {
        final b = (w['data'] as Map)['walletBalance'];
        if (b != null) {
          balance = b.toString();
          fromServer = true;
        }
      }
    } catch (_) {}
    try {
      final t = await repository.getTransactions();
      if (t['status'] == 200 && t['data'] is Map) {
        final list = (t['data'] as Map)['WalletTransactionsDetails'];
        if (list is List) {
          txs = list
              .whereType<Map>()
              .map((e) => WalletTx(
                  '${e['type'] ?? ''}',
                  '${e['description'] ?? ''}',
                  '${e['amount'] ?? ''}',
                  '${e['created_at'] ?? ''}'))
              .toList();
        }
      }
    } catch (_) {}
    if (isClosed) return;
    emit(WalletState(
        loading: false,
        balance: balance,
        transactions: txs,
        balanceFromServer: fromServer));
  }
}
