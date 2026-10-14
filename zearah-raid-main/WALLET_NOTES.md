# Rider wallet – what is live and what is gated

LIVE
- Drawer entry "Wallet" with balance, Wallet screen (balance, history, Add Money).
- Add Money opens `<domain>/wallet_recharge?token&amount&currency` (same page the driver app uses).

CONFIRM ON THE BACKEND (copied from the driver app, may differ for riders)
- `getVendorWallet`, `getVendorWalletTransactions` must accept `user_type=user`.
  If they use other names, change `Config.getWallet / getWalletTransactions`.
  If the call fails the screen still shows the balance saved at login.

GATED (Config.walletPaymentEnabled = false)
- Paying a ride with the wallet. getItemPrices/bookItem already accept `wallet_amount`
  and return `wallet_amount` + `remaining_wallet_balance`, but I cannot see whether the
  server actually deducts the wallet when the ride is paid. Enabling this without that
  would let the driver collect less cash while the wallet is never charged.
  Verify server-side deduction, then enable.
