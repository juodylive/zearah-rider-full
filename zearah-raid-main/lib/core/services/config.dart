class Config {
static const googleKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE";
  static const String oneSiginalAppid = 'YOUR_ONESIGNAL_APP_ID_HERE';
  static const String oneSiginalApiKey = 'YOUR_ONESIGNAL_API_KEY_HERE';


// Temporary base domain URL for setup (please add your final URL here)
 static const String baseDomain = 'https://zearah.dpdns.org';
  // Do not change any code below this line. ==================================================
  static const String version = '/api/v1/';
  static const String bearerVersion = '/api/';
  static const String baseUrl = '$baseDomain$version';
  static const String baseUrlForBearer = '$baseDomain$bearerVersion';
  // Map tiles (Stadia Maps). Prefer: flutter build apk --dart-define=STADIA_KEY=xxxx
  static const String stadiaKey = String.fromEnvironment('STADIA_KEY',
      defaultValue: '7fd22148-c7d7-4f1f-b33f-677c8dbc8496');
  // Wallet endpoints. Names copied from the driver app (same backend) - confirm
  // they accept user_type "user"; if your backend uses other names change here.
  static const String getWallet = 'getVendorWallet';
  static const String getWalletTransactions = 'getVendorWalletTransactions';
  // Pay-with-wallet at checkout stays OFF until the backend deducts the wallet
  // when the ride is paid (see WALLET_NOTES.md).
  static const bool walletPaymentEnabled = false;
  static const String secretKey = '49382716504938271650493827165049';
  static const String generateToken = 'generateToken';
  static const String registerUser = 'userRegister';
  static const String socialLogin = 'socialLogin';
  static const String verifyResetToken = 'verifyResetToken';
  static const String fcmUpdate = 'fcmUpdate';
  static const String otpVerification = 'otpVerification';
  static const String resendTokenEmailChange = 'ResendTokenEmailChange';
  static const String updateBookingStatusByUser = 'updateBookingStatusByUser';
  static const String resendOtp = 'ResendOtp';
  static const String changeEmail = 'changeEmail';
  static const String sendMobileLoginOtp = 'sendMobileLoginOtp';
  static const String checkEmail = 'checkEmail';
  static const String userMobileLogin = 'userMobileLogin';
  static const String getAllCategories = 'getAllCategories';
  static const String checkMobileNumber = 'checkMobileNumber';
  static const String changeMobileNumber = 'changeMobileNumber';
  static const String getItemPrices = 'getItemPrices';
  static const String bookItem = 'bookItem';
  static const String giveReviewByUser = 'giveReviewByUser';
  static const String updatePaymentStatusByUser = 'updatePaymentStatusByUser';
  static const String bookingRecord = 'bookingRecord';
  static const String deleteAccount = 'deleteAccount';
  static const String editProfile = 'editProfile';
  static const String uploadProfileImage = 'uploadProfileImage';
  static const String getgeneralSettings = 'getgeneralSettings';
  static const String staticPage = 'StaticPage';
  static const String sos = 'sos';
  
}
