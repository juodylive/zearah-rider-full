import 'package:zearah_rider/core/extensions/workspace.dart';
import 'package:zearah_rider/core/services/config.dart';
import 'package:zearah_rider/core/services/http.dart';

class WalletRepository {
  Future<Map<String, dynamic>> getWallet() async {
    final r = await httpPost(Config.getWallet, {},
        context: navigatorKey.currentContext!);
    return Map<String, dynamic>.from(r as Map);
  }

  Future<Map<String, dynamic>> getTransactions({String offset = "0"}) async {
    final r = await httpPost(Config.getWalletTransactions, {"offset": offset},
        context: navigatorKey.currentContext!);
    return Map<String, dynamic>.from(r as Map);
  }
}
