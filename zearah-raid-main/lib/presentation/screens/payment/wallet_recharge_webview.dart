import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../core/utils/theme/project_color.dart';

/// Opens the backend's wallet top-up page. Pops with `true` on success.
class WalletRechargeWebView extends StatefulWidget {
  final String url;
  const WalletRechargeWebView({super.key, required this.url});

  @override
  State<WalletRechargeWebView> createState() => _WalletRechargeWebViewState();
}

class _WalletRechargeWebViewState extends State<WalletRechargeWebView> {
  bool _loading = true;
  bool _done = false;

  void _finish(bool ok) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(ok);
  }

  void _inspect(String url) {
    if (url.contains('wallet_recharge_success')) {
      _finish(true);
    } else if (url.contains('wallet_recharge_fail') ||
        url.contains('payment_fail') ||
        url.contains('/invalid-order')) {
      _finish(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      appBar: AppBar(
        backgroundColor: notifires.getbgcolor,
        elevation: 0,
        iconTheme: IconThemeData(color: notifires.getwhiteblackColor),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
            ),
            onLoadStart: (c, url) => setState(() => _loading = true),
            onLoadStop: (c, url) {
              setState(() => _loading = false);
              _inspect(url.toString());
            },
            shouldOverrideUrlLoading: (c, action) async {
              _inspect(action.request.url.toString());
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
