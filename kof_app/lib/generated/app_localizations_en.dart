// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kof';

  @override
  String get appTagline => 'Coffee. Ordered.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get cancel => 'Cancel';

  @override
  String get total => 'Total';

  @override
  String tableLabel(String table) {
    return 'Table $table';
  }

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginFieldsRequired => 'Please fill in all fields.';

  @override
  String get loginButton => 'Log In';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get loginAppleNotAvailable => 'Apple Sign-In is not available yet.';

  @override
  String get loginAsGuest => 'Continue as Guest';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegister => 'Register';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordHeading => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get forgotPasswordButton => 'Send Reset Link';

  @override
  String get forgotPasswordSuccess => 'Check your inbox';

  @override
  String forgotPasswordSuccessBody(String email) {
    return 'If an account exists for $email, a password reset link has been sent.';
  }

  @override
  String get forgotPasswordBackToLogin => 'Back to Login';

  @override
  String get forgotPasswordEmailRequired => 'Please enter your email address.';

  @override
  String get registerAppBarTitle => 'Create Account';

  @override
  String get registerHeading => 'Join Kof';

  @override
  String get registerSubtitle =>
      'Create an account to track orders and follow your favourite coffee shops.';

  @override
  String get registerNameLabel => 'Full name';

  @override
  String get registerNameHint => 'Jane Doe';

  @override
  String get registerPasswordHint => 'At least 6 characters';

  @override
  String get registerPhoneLabel => 'Phone number (optional)';

  @override
  String get registerPhoneHint => '+1 555 000 0000';

  @override
  String get registerFieldsRequired => 'Please fill in all required fields.';

  @override
  String get registerPasswordShort => 'Password must be at least 6 characters.';

  @override
  String get registerButton => 'Create Account';

  @override
  String get registerAlreadyAccount => 'Already have an account?';

  @override
  String get registerLogIn => 'Log In';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeWelcome => 'Welcome to Kof';

  @override
  String get homeSubtitle => 'What would you like to do?';

  @override
  String get homeScanTitle => 'Scan Table QR Code';

  @override
  String get homeScanSubtitle => 'Start ordering at your table';

  @override
  String get homeMapTitle => 'Coffee Shops using Kof';

  @override
  String get homeMapSubtitle => 'Find and follow coffee shops near you';

  @override
  String get homeMapComingSoon => 'Map — coming soon';

  @override
  String get homeNotificationsTooltip => 'Notifications';

  @override
  String get homeNotificationsComingSoon => 'Notifications — coming soon';

  @override
  String get drawerGuestName => 'Guest';

  @override
  String get drawerBrowsingAsGuest => 'Browsing as guest';

  @override
  String get drawerMyOrders => 'My Orders';

  @override
  String get drawerMyOrdersComingSoon => 'My Orders — coming soon';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerSettingsComingSoon => 'Settings — coming soon';

  @override
  String get drawerLogout => 'Logout';

  @override
  String get drawerPrivacyPolicy => 'Privacy Policy';

  @override
  String get drawerTerms => 'Terms and Conditions';

  @override
  String get drawerContactUs => 'Contact Us';

  @override
  String get drawerVersion => 'Kof v1.0.0';

  @override
  String get scanTitle => 'Scan Table QR Code';

  @override
  String get scanSubtitle => 'Point your camera at the QR code on your table';

  @override
  String get scanConnecting => 'Connecting to shop...';

  @override
  String get scanTryAgain => 'Try again';

  @override
  String get scanEnterManually => 'Enter manually';

  @override
  String get scanManualDialogTitle => 'Manual Entry';

  @override
  String get scanManualServerLabel => 'Server URL';

  @override
  String get scanManualServerHint => 'http://192.168.1.10:3000';

  @override
  String get scanManualTableLabel => 'Table label';

  @override
  String get scanManualTableHint => '1';

  @override
  String get scanManualTokenLabel => 'Table token';

  @override
  String get scanManualTokenHint => 'paste token here';

  @override
  String get scanConnect => 'Connect';

  @override
  String get scanInvalidQr => 'Invalid QR code';

  @override
  String get scanNotKofQr =>
      'Not a Kof table QR code.\nPlease scan the QR code on your table.';

  @override
  String get scanWrongServer => 'QR code does not point to a Kof server.';

  @override
  String get menuPickupOrder => 'Pickup order';

  @override
  String get menuQrHint =>
      'Ordering from a table? Scan the table\'s QR code here!';

  @override
  String get menuNoItems => 'No items available';

  @override
  String get menuRetry => 'Retry';

  @override
  String get menuReviewOrder => 'Review Order';

  @override
  String get menuScanDifferentTable => 'Scan different table';

  @override
  String orderNumber(int number) {
    return 'Order #$number';
  }

  @override
  String get orderCancelledMessage => 'This order was cancelled';

  @override
  String get orderAgain => 'Order Again';

  @override
  String get orderScanDifferentTable => 'Scan a Different Table';

  @override
  String get statusNew => 'Order Received';

  @override
  String get statusMaking => 'Being Prepared';

  @override
  String get statusReady => 'Ready for Pickup';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get menuItemLowStock => 'Low stock';

  @override
  String get menuItemUnavailable => 'Unavailable';

  @override
  String get menuItemAdd => 'Add';

  @override
  String get cartYourOrder => 'Your Order';

  @override
  String get cartNoteHint => 'Add a note (optional)';

  @override
  String cartEach(String price) {
    return '$price each';
  }

  @override
  String get cartPlaceOrder => 'Place Order';

  @override
  String get myOrdersTitle => 'My Orders';

  @override
  String get myOrdersEmpty => 'No orders yet';

  @override
  String get myOrdersEmptySubtitle =>
      'Orders you place at coffee shops will appear here.';

  @override
  String get myOrdersScanCta => 'Scan a table QR code';

  @override
  String get myOrdersActive => 'Active';

  @override
  String get myOrdersHistory => 'History';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptySubtitle =>
      'Follow coffee shops to receive updates about promotions and special offers.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsHapticFeedback => 'Haptic feedback';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Feel subtle taps when interacting with the app';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms and Conditions';

  @override
  String get settingsContactUs => 'Contact Us';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get settingsLogoutConfirmYes => 'Log out';

  @override
  String get settingsNotificationsPermission => 'Notification permissions';

  @override
  String get settingsNotificationsPermissionSubtitle =>
      'Allow Kof to send you push notifications';

  @override
  String get mapTitle => 'Coffee Shops';

  @override
  String get mapLocationDenied =>
      'Location access denied. Enable it in Settings to see shops near you.';

  @override
  String get mapNoShopsNearby => 'No coffee shops nearby yet';

  @override
  String get mapNoShopsSubtitle =>
      'Shops using Kof will appear here once the platform launches.';

  @override
  String get mapOpenSettings => 'Open Settings';

  @override
  String get mapNoShopsCountryHint =>
      'Not seeing any shops? You may be browsing a different country than your current location. Update your country in Settings.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get loginSelectLanguage => 'Language';

  @override
  String get loginSelectTheme => 'Theme';

  @override
  String get authErrorInvalidEmail => 'That email address looks invalid.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect email or password.';

  @override
  String get authErrorInvalidCredential => 'Incorrect email or password.';

  @override
  String get authErrorEmailInUse =>
      'An account with this email already exists.';

  @override
  String get authErrorWeakPassword => 'Password is too weak. Try a longer one.';

  @override
  String get authErrorNetwork => 'No internet connection. Please try again.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorGoogleCancelled => 'Google Sign-In was cancelled.';

  @override
  String get authErrorGoogleFailed =>
      'Google Sign-In failed. Please try again.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSentTo(String email) {
    return 'We sent a verification link to $email. Tap the link to activate your account.';
  }

  @override
  String get verifyEmailCheck => 'I\'ve verified — continue';

  @override
  String get verifyEmailResend => 'Resend email';

  @override
  String get verifyEmailResent => 'Verification email sent.';

  @override
  String get verifyEmailNotYet =>
      'Email not verified yet. Check your inbox and spam folder.';

  @override
  String get verifyEmailChangeAccount => 'Use a different account';

  @override
  String get drawerFollowedShops => 'Followed Shops';

  @override
  String get shopFollow => 'Follow';

  @override
  String get shopUnfollow => 'Following';

  @override
  String get shopFollowRequiresAccount =>
      'Sign in to follow shops and get updates.';

  @override
  String get shopFollowFailed => 'Couldn\'t update follow. Please try again.';

  @override
  String get shopAboutHeading => 'About';

  @override
  String get shopMenuPreviewHeading => 'Menu preview';

  @override
  String get shopReviewsHeading => 'Reviews';

  @override
  String get shopDiscountsHeading => 'Discounts';

  @override
  String get shopSectionComingSoon => 'Coming soon';

  @override
  String get followedShopsTitle => 'Followed Shops';

  @override
  String get followedShopsGuestTitle => 'Sign in to follow shops';

  @override
  String get followedShopsGuestBody =>
      'Create an account to follow shops and get notified about news and offers.';

  @override
  String get followedShopsEmptyTitle => 'No followed shops yet';

  @override
  String get followedShopsEmptyBody =>
      'Open the map to find shops and tap Follow to get their updates.';

  @override
  String get countryLabel => 'Country';

  @override
  String get countryHint => 'Select your country';

  @override
  String get countrySearch => 'Search countries...';

  @override
  String get settingsCountry => 'Country';

  @override
  String get shopWalkInButton => 'Order Here';

  @override
  String get shopWalkInConnecting => 'Connecting...';

  @override
  String get shopWalkInDialogTitle => 'Order at this shop';

  @override
  String get shopWalkInNameLabel => 'Your name';

  @override
  String get shopWalkInNameHint => 'e.g. Jane';

  @override
  String get shopWalkInWifi =>
      'Make sure you\'re connected to the shop\'s Wi-Fi';

  @override
  String get shopWalkInError =>
      'Could not connect to the shop server. Are you on the shop\'s Wi-Fi?';

  @override
  String shopWalkInDistanceLabel(int meters) {
    return '${meters}m away';
  }

  @override
  String get menuFeatured => 'Featured';

  @override
  String get menuCategories => 'Categories';

  @override
  String get menuAllItems => 'All items';

  @override
  String get menuSearchHint => 'Search beverages or foods';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryEspresso => 'Espresso';

  @override
  String get categoryHotDrinks => 'Hot Drinks';

  @override
  String get categoryColdDrinks => 'Cold Drinks';

  @override
  String get categoryPastries => 'Pastries';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryOther => 'Other';

  @override
  String get itemDetailSize => 'Size';

  @override
  String get itemDetailQuantity => 'Quantity';

  @override
  String get itemDetailAddToCart => 'Add to Cart';

  @override
  String get itemDetailPlaceOrder => 'Place Order';

  @override
  String get itemDetailUnavailable => 'Currently unavailable';

  @override
  String get itemDetailBack => 'Back';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get sizeXtraLarge => 'Xtra Large';

  @override
  String get orderStatusItems => 'Items';

  @override
  String get orderStatusNote => 'Note';

  @override
  String orderStatusPlacedAt(String time) {
    return 'Placed at $time';
  }

  @override
  String orderStatusPickupFor(String name) {
    return 'Pickup for $name';
  }

  @override
  String orderStatusItemCount(int count) {
    return '$count item(s)';
  }

  @override
  String get orderStatusPaid => 'Paid';

  @override
  String get orderStatusUnpaid => 'Unpaid';

  @override
  String get orderStatusOffline => 'Offline — try refreshing';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptPaidStamp => 'PAID';

  @override
  String get receiptThankYou => 'Thank you for your visit';

  @override
  String get receiptViewButton => 'View Receipt';

  @override
  String get statusReadyTable => 'On its way to your table';
}
