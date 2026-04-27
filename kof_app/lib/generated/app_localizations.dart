import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fi'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kof'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Coffee. Ordered.'**
  String get appTagline;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @tableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table {table}'**
  String tableLabel(String table);

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get loginFieldsRequired;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginWithApple;

  /// No description provided for @loginAppleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In is not available yet.'**
  String get loginAppleNotAvailable;

  /// No description provided for @loginAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginAsGuest;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get loginRegister;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordHeading;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordButton;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get forgotPasswordSuccess;

  /// No description provided for @forgotPasswordSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a password reset link has been sent.'**
  String forgotPasswordSuccessBody(String email);

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @forgotPasswordEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get forgotPasswordEmailRequired;

  /// No description provided for @registerAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerAppBarTitle;

  /// No description provided for @registerHeading.
  ///
  /// In en, this message translates to:
  /// **'Join Kof'**
  String get registerHeading;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to track orders and follow your favourite coffee shops.'**
  String get registerSubtitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerNameLabel;

  /// No description provided for @registerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get registerNameHint;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get registerPasswordHint;

  /// No description provided for @registerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get registerPhoneLabel;

  /// No description provided for @registerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 000 0000'**
  String get registerPhoneHint;

  /// No description provided for @registerFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get registerFieldsRequired;

  /// No description provided for @registerPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get registerPasswordShort;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @registerAlreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerAlreadyAccount;

  /// No description provided for @registerLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get registerLogIn;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kof'**
  String get homeWelcome;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get homeSubtitle;

  /// No description provided for @homeScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Table QR Code'**
  String get homeScanTitle;

  /// No description provided for @homeScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start ordering at your table'**
  String get homeScanSubtitle;

  /// No description provided for @homeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Coffee Shops using Kof'**
  String get homeMapTitle;

  /// No description provided for @homeMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and follow coffee shops near you'**
  String get homeMapSubtitle;

  /// No description provided for @homeMapComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Map — coming soon'**
  String get homeMapComingSoon;

  /// No description provided for @homeNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotificationsTooltip;

  /// No description provided for @homeNotificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications — coming soon'**
  String get homeNotificationsComingSoon;

  /// No description provided for @drawerGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get drawerGuestName;

  /// No description provided for @drawerBrowsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browsing as guest'**
  String get drawerBrowsingAsGuest;

  /// No description provided for @drawerMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get drawerMyOrders;

  /// No description provided for @drawerMyOrdersComingSoon.
  ///
  /// In en, this message translates to:
  /// **'My Orders — coming soon'**
  String get drawerMyOrdersComingSoon;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings — coming soon'**
  String get drawerSettingsComingSoon;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogout;

  /// No description provided for @drawerPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get drawerPrivacyPolicy;

  /// No description provided for @drawerTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get drawerTerms;

  /// No description provided for @drawerContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get drawerContactUs;

  /// No description provided for @drawerVersion.
  ///
  /// In en, this message translates to:
  /// **'Kof v1.0.0'**
  String get drawerVersion;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Table QR Code'**
  String get scanTitle;

  /// No description provided for @scanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code on your table'**
  String get scanSubtitle;

  /// No description provided for @scanConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to shop...'**
  String get scanConnecting;

  /// No description provided for @scanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanTryAgain;

  /// No description provided for @scanEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get scanEnterManually;

  /// No description provided for @scanManualDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get scanManualDialogTitle;

  /// No description provided for @scanManualServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get scanManualServerLabel;

  /// No description provided for @scanManualServerHint.
  ///
  /// In en, this message translates to:
  /// **'http://192.168.1.10:3000'**
  String get scanManualServerHint;

  /// No description provided for @scanManualTableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table label'**
  String get scanManualTableLabel;

  /// No description provided for @scanManualTableHint.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get scanManualTableHint;

  /// No description provided for @scanManualTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Table token'**
  String get scanManualTokenLabel;

  /// No description provided for @scanManualTokenHint.
  ///
  /// In en, this message translates to:
  /// **'paste token here'**
  String get scanManualTokenHint;

  /// No description provided for @scanConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get scanConnect;

  /// No description provided for @scanInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get scanInvalidQr;

  /// No description provided for @scanNotKofQr.
  ///
  /// In en, this message translates to:
  /// **'Not a Kof table QR code.\nPlease scan the QR code on your table.'**
  String get scanNotKofQr;

  /// No description provided for @scanWrongServer.
  ///
  /// In en, this message translates to:
  /// **'QR code does not point to a Kof server.'**
  String get scanWrongServer;

  /// No description provided for @menuPickupOrder.
  ///
  /// In en, this message translates to:
  /// **'Pickup order'**
  String get menuPickupOrder;

  /// No description provided for @menuQrHint.
  ///
  /// In en, this message translates to:
  /// **'Ordering from a table? Scan the table\'s QR code here!'**
  String get menuQrHint;

  /// No description provided for @menuNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items available'**
  String get menuNoItems;

  /// No description provided for @menuRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get menuRetry;

  /// No description provided for @menuReviewOrder.
  ///
  /// In en, this message translates to:
  /// **'Review Order'**
  String get menuReviewOrder;

  /// No description provided for @menuScanDifferentTable.
  ///
  /// In en, this message translates to:
  /// **'Scan different table'**
  String get menuScanDifferentTable;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(int number);

  /// No description provided for @orderCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This order was cancelled'**
  String get orderCancelledMessage;

  /// No description provided for @orderAgain.
  ///
  /// In en, this message translates to:
  /// **'Order Again'**
  String get orderAgain;

  /// No description provided for @orderScanDifferentTable.
  ///
  /// In en, this message translates to:
  /// **'Scan a Different Table'**
  String get orderScanDifferentTable;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'Order Received'**
  String get statusNew;

  /// No description provided for @statusMaking.
  ///
  /// In en, this message translates to:
  /// **'Being Prepared'**
  String get statusMaking;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get statusReady;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @menuItemLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get menuItemLowStock;

  /// No description provided for @menuItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get menuItemUnavailable;

  /// No description provided for @menuItemAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get menuItemAdd;

  /// No description provided for @cartYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your Order'**
  String get cartYourOrder;

  /// No description provided for @cartNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get cartNoteHint;

  /// No description provided for @cartEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String cartEach(String price);

  /// No description provided for @cartPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get cartPlaceOrder;

  /// No description provided for @myOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrdersTitle;

  /// No description provided for @myOrdersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get myOrdersEmpty;

  /// No description provided for @myOrdersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders you place at coffee shops will appear here.'**
  String get myOrdersEmptySubtitle;

  /// No description provided for @myOrdersScanCta.
  ///
  /// In en, this message translates to:
  /// **'Scan a table QR code'**
  String get myOrdersScanCta;

  /// No description provided for @myOrdersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myOrdersActive;

  /// No description provided for @myOrdersHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get myOrdersHistory;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow coffee shops to receive updates about promotions and special offers.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsHapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHapticFeedback;

  /// No description provided for @settingsHapticFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Feel subtle taps when interacting with the app'**
  String get settingsHapticFeedbackSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get settingsTerms;

  /// No description provided for @settingsContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get settingsContactUs;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLogoutConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutConfirmYes;

  /// No description provided for @settingsNotificationsPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification permissions'**
  String get settingsNotificationsPermission;

  /// No description provided for @settingsNotificationsPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Kof to send you push notifications'**
  String get settingsNotificationsPermissionSubtitle;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Coffee Shops'**
  String get mapTitle;

  /// No description provided for @mapLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied. Enable it in Settings to see shops near you.'**
  String get mapLocationDenied;

  /// No description provided for @mapNoShopsNearby.
  ///
  /// In en, this message translates to:
  /// **'No coffee shops nearby yet'**
  String get mapNoShopsNearby;

  /// No description provided for @mapNoShopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shops using Kof will appear here once the platform launches.'**
  String get mapNoShopsSubtitle;

  /// No description provided for @mapOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get mapOpenSettings;

  /// No description provided for @mapNoShopsCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Not seeing any shops? You may be browsing a different country than your current location. Update your country in Settings.'**
  String get mapNoShopsCountryHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @loginSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get loginSelectLanguage;

  /// No description provided for @loginSelectTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get loginSelectTheme;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address looks invalid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Try a longer one.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In was cancelled.'**
  String get authErrorGoogleCancelled;

  /// No description provided for @authErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed. Please try again.'**
  String get authErrorGoogleFailed;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Tap the link to activate your account.'**
  String verifyEmailSentTo(String email);

  /// No description provided for @verifyEmailCheck.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified — continue'**
  String get verifyEmailCheck;

  /// No description provided for @verifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get verifyEmailResent;

  /// No description provided for @verifyEmailNotYet.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Check your inbox and spam folder.'**
  String get verifyEmailNotYet;

  /// No description provided for @verifyEmailChangeAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get verifyEmailChangeAccount;

  /// No description provided for @drawerFollowedShops.
  ///
  /// In en, this message translates to:
  /// **'Followed Shops'**
  String get drawerFollowedShops;

  /// No description provided for @shopFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get shopFollow;

  /// No description provided for @shopUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get shopUnfollow;

  /// No description provided for @shopFollowRequiresAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow shops and get updates.'**
  String get shopFollowRequiresAccount;

  /// No description provided for @shopFollowFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update follow. Please try again.'**
  String get shopFollowFailed;

  /// No description provided for @shopAboutHeading.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get shopAboutHeading;

  /// No description provided for @shopMenuPreviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Menu preview'**
  String get shopMenuPreviewHeading;

  /// No description provided for @shopReviewsHeading.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get shopReviewsHeading;

  /// No description provided for @shopDiscountsHeading.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get shopDiscountsHeading;

  /// No description provided for @shopSectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get shopSectionComingSoon;

  /// No description provided for @followedShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Followed Shops'**
  String get followedShopsTitle;

  /// No description provided for @followedShopsGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow shops'**
  String get followedShopsGuestTitle;

  /// No description provided for @followedShopsGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account to follow shops and get notified about news and offers.'**
  String get followedShopsGuestBody;

  /// No description provided for @followedShopsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No followed shops yet'**
  String get followedShopsEmptyTitle;

  /// No description provided for @followedShopsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Open the map to find shops and tap Follow to get their updates.'**
  String get followedShopsEmptyBody;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @countryHint.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get countryHint;

  /// No description provided for @countrySearch.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get countrySearch;

  /// No description provided for @settingsCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get settingsCountry;

  /// No description provided for @shopWalkInButton.
  ///
  /// In en, this message translates to:
  /// **'Order Here'**
  String get shopWalkInButton;

  /// No description provided for @shopWalkInConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get shopWalkInConnecting;

  /// No description provided for @shopWalkInDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Order at this shop'**
  String get shopWalkInDialogTitle;

  /// No description provided for @shopWalkInNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get shopWalkInNameLabel;

  /// No description provided for @shopWalkInNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jane'**
  String get shopWalkInNameHint;

  /// No description provided for @shopWalkInWifi.
  ///
  /// In en, this message translates to:
  /// **'Make sure you\'re connected to the shop\'s Wi-Fi'**
  String get shopWalkInWifi;

  /// No description provided for @shopWalkInError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the shop server. Are you on the shop\'s Wi-Fi?'**
  String get shopWalkInError;

  /// No description provided for @shopWalkInDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'{meters}m away'**
  String shopWalkInDistanceLabel(int meters);

  /// No description provided for @menuFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get menuFeatured;

  /// No description provided for @menuCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get menuCategories;

  /// No description provided for @menuAllItems.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get menuAllItems;

  /// No description provided for @menuSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search beverages or foods'**
  String get menuSearchHint;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryEspresso.
  ///
  /// In en, this message translates to:
  /// **'Espresso'**
  String get categoryEspresso;

  /// No description provided for @categoryHotDrinks.
  ///
  /// In en, this message translates to:
  /// **'Hot Drinks'**
  String get categoryHotDrinks;

  /// No description provided for @categoryColdDrinks.
  ///
  /// In en, this message translates to:
  /// **'Cold Drinks'**
  String get categoryColdDrinks;

  /// No description provided for @categoryPastries.
  ///
  /// In en, this message translates to:
  /// **'Pastries'**
  String get categoryPastries;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @itemDetailSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get itemDetailSize;

  /// No description provided for @itemDetailQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get itemDetailQuantity;

  /// No description provided for @itemDetailAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get itemDetailAddToCart;

  /// No description provided for @itemDetailPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get itemDetailPlaceOrder;

  /// No description provided for @itemDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get itemDetailUnavailable;

  /// No description provided for @itemDetailBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get itemDetailBack;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @sizeXtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Xtra Large'**
  String get sizeXtraLarge;

  /// No description provided for @orderStatusItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderStatusItems;

  /// No description provided for @orderStatusNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get orderStatusNote;

  /// No description provided for @orderStatusPlacedAt.
  ///
  /// In en, this message translates to:
  /// **'Placed at {time}'**
  String orderStatusPlacedAt(String time);

  /// No description provided for @orderStatusPickupFor.
  ///
  /// In en, this message translates to:
  /// **'Pickup for {name}'**
  String orderStatusPickupFor(String name);

  /// No description provided for @orderStatusItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String orderStatusItemCount(int count);

  /// No description provided for @orderStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get orderStatusPaid;

  /// No description provided for @orderStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get orderStatusUnpaid;

  /// No description provided for @orderStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — try refreshing'**
  String get orderStatusOffline;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptPaidStamp.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get receiptPaidStamp;

  /// No description provided for @receiptThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your visit'**
  String get receiptThankYou;

  /// No description provided for @receiptViewButton.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get receiptViewButton;

  /// No description provided for @statusReadyTable.
  ///
  /// In en, this message translates to:
  /// **'On its way to your table'**
  String get statusReadyTable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fi', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fi':
      return AppLocalizationsFi();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
