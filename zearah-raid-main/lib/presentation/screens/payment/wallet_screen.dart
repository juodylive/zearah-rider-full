import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/config.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../core/utils/translate.dart';
import '../../cubits/payment/wallet_cubit.dart';
import 'wallet_recharge_webview.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _quick = ['5', '10', '20', '50'];

  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().load();
  }

  Future<void> _topUp() async {
    final amount = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: notifires.getbgcolor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AmountSheet(quick: _quick),
    );
    if (amount == null || amount.isEmpty || !mounted) return;

    final base = Config.baseUrl.replaceAll("/api/v1/", "");
    final query = {
      "token": token,
      "amount": amount,
      "currency": currency,
    }.entries.map((e) =>
        "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}").join("&");

    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => WalletRechargeWebView(url: "$base/wallet_recharge?$query")));
    if (!mounted) return;
    context.read<WalletCubit>().load();
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Wallet recharged successfully".translate(context))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      appBar: CustomAppBars(
        title: "Wallet".translate(context),
        titleColor: notifires.getwhiteblackColor,
        backgroundColor: notifires.getbgcolor,
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<WalletCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _balanceCard(context, state),
                const SizedBox(height: 24),
                Text("Transactions".translate(context),
                    style: headingBlack(context)),
                const SizedBox(height: 8),
                if (state.loading && state.transactions.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()))
                else if (state.transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                        child: Text("No transactions yet".translate(context),
                            style: regular(context))),
                  )
                else
                  ...state.transactions.map((t) => _tile(context, t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _balanceCard(BuildContext context, WalletState s) {
    final bal = double.tryParse(s.balance ?? '');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
            colors: [themeColor, themeColor.withValues(alpha: .75)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Wallet Balance".translate(context),
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            bal == null ? "--" : "$currency ${bal.toStringAsFixed(2)}",
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _topUp,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text("Add Money".translate(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, WalletTx t) {
    final color = t.isCredit ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notifires.getbgcolor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: grey5.withValues(alpha: .5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(t.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description.isEmpty ? t.type : t.description,
                    style: heading3Grey1(context)),
                Text(t.date, style: regular(context)),
              ],
            ),
          ),
          Text("${t.isCredit ? '+' : '-'}$currency ${t.amount}",
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AmountSheet extends StatefulWidget {
  final List<String> quick;
  const _AmountSheet({required this.quick});

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add Money".translate(context), style: headingBlack(context)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: widget.quick
                .map((a) => ActionChip(
                      label: Text("$currency $a"),
                      onPressed: () => setState(() => _c.text = a),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "Enter amount".translate(context),
              prefixText: "$currency ",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final v = double.tryParse(_c.text.trim()) ?? 0;
                if (v <= 0) {
                  showErrorToastMessage(
                      "Please enter an amount".translate(context));
                  return;
                }
                Navigator.pop(context, _c.text.trim());
              },
              child: Text("Proceed to Pay".translate(context)),
            ),
          ),
        ],
      ),
    );
  }
}
