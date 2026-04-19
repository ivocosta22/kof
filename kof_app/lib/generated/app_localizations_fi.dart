// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appName => 'Kof';

  @override
  String get appTagline => 'Kahvi. Tilattu.';

  @override
  String get emailLabel => 'Sähköposti';

  @override
  String get emailHint => 'sinä@esimerkki.fi';

  @override
  String get passwordLabel => 'Salasana';

  @override
  String get cancel => 'Peruuta';

  @override
  String get total => 'Yhteensä';

  @override
  String tableLabel(String table) {
    return 'Pöytä $table';
  }

  @override
  String get loginForgotPassword => 'Unohditko salasanan?';

  @override
  String get loginFieldsRequired => 'Täytä kaikki kentät.';

  @override
  String get loginButton => 'Kirjaudu sisään';

  @override
  String get loginOrContinueWith => 'tai jatka';

  @override
  String get loginWithGoogle => 'Jatka Googlella';

  @override
  String get loginWithApple => 'Jatka Applella';

  @override
  String get loginAppleNotAvailable =>
      'Apple-kirjautuminen ei ole vielä käytettävissä.';

  @override
  String get loginAsGuest => 'Jatka vieraana';

  @override
  String get loginNoAccount => 'Ei tiliä?';

  @override
  String get loginRegister => 'Rekisteröidy';

  @override
  String get forgotPasswordTitle => 'Unohtunut salasana';

  @override
  String get forgotPasswordHeading => 'Nollaa salasanasi';

  @override
  String get forgotPasswordSubtitle =>
      'Syötä sähköpostiosoitteesi ja lähetämme sinulle linkin salasanan nollaamiseksi.';

  @override
  String get forgotPasswordButton => 'Lähetä nollauslinkki';

  @override
  String get forgotPasswordSuccess => 'Tarkista sähköpostisi';

  @override
  String forgotPasswordSuccessBody(String email) {
    return 'Jos tilisi $email on olemassa, salasanan nollaustilinkki on lähetetty.';
  }

  @override
  String get forgotPasswordBackToLogin => 'Takaisin kirjautumiseen';

  @override
  String get forgotPasswordEmailRequired => 'Syötä sähköpostiosoitteesi.';

  @override
  String get registerAppBarTitle => 'Luo tili';

  @override
  String get registerHeading => 'Liity Kofiin';

  @override
  String get registerSubtitle =>
      'Luo tili tilataksesi ja seurataksesi suosikkikahvilojasi.';

  @override
  String get registerNameLabel => 'Koko nimi';

  @override
  String get registerNameHint => 'Matti Meikäläinen';

  @override
  String get registerPasswordHint => 'Vähintään 6 merkkiä';

  @override
  String get registerPhoneLabel => 'Puhelinnumero (valinnainen)';

  @override
  String get registerPhoneHint => '+358 40 000 0000';

  @override
  String get registerFieldsRequired => 'Täytä kaikki pakolliset kentät.';

  @override
  String get registerPasswordShort =>
      'Salasanan on oltava vähintään 6 merkkiä.';

  @override
  String get registerButton => 'Luo tili';

  @override
  String get registerAlreadyAccount => 'Onko sinulla jo tili?';

  @override
  String get registerLogIn => 'Kirjaudu sisään';

  @override
  String homeGreeting(String name) {
    return 'Hei, $name!';
  }

  @override
  String get homeWelcome => 'Tervetuloa Kofiin';

  @override
  String get homeSubtitle => 'Mitä haluaisit tehdä?';

  @override
  String get homeScanTitle => 'Skannaa pöydän QR-koodi';

  @override
  String get homeScanSubtitle => 'Aloita tilaaminen pöydältäsi';

  @override
  String get homeMapTitle => 'Kof-kahvilat';

  @override
  String get homeMapSubtitle => 'Löydä ja seuraa lähellä olevia kahviloita';

  @override
  String get homeMapComingSoon => 'Kartta — tulossa pian';

  @override
  String get homeNotificationsTooltip => 'Ilmoitukset';

  @override
  String get homeNotificationsComingSoon => 'Ilmoitukset — tulossa pian';

  @override
  String get drawerGuestName => 'Vieras';

  @override
  String get drawerBrowsingAsGuest => 'Selaat vieraana';

  @override
  String get drawerMyOrders => 'Omat tilaukset';

  @override
  String get drawerMyOrdersComingSoon => 'Omat tilaukset — tulossa pian';

  @override
  String get drawerSettings => 'Asetukset';

  @override
  String get drawerSettingsComingSoon => 'Asetukset — tulossa pian';

  @override
  String get drawerLogout => 'Kirjaudu ulos';

  @override
  String get drawerPrivacyPolicy => 'Tietosuojakäytäntö';

  @override
  String get drawerTerms => 'Käyttöehdot';

  @override
  String get drawerContactUs => 'Ota yhteyttä';

  @override
  String get drawerVersion => 'Kof v1.0.0';

  @override
  String get scanTitle => 'Skannaa pöydän QR-koodi';

  @override
  String get scanSubtitle => 'Suuntaa kamera pöydälläsi olevaan QR-koodiin';

  @override
  String get scanConnecting => 'Yhdistetään kahvilaan...';

  @override
  String get scanTryAgain => 'Yritä uudelleen';

  @override
  String get scanEnterManually => 'Syötä manuaalisesti';

  @override
  String get scanManualDialogTitle => 'Manuaalinen syöttö';

  @override
  String get scanManualServerLabel => 'Palvelimen URL';

  @override
  String get scanManualServerHint => 'http://192.168.1.10:3000';

  @override
  String get scanManualTableLabel => 'Pöydän tunniste';

  @override
  String get scanManualTableHint => '1';

  @override
  String get scanManualTokenLabel => 'Pöydän token';

  @override
  String get scanManualTokenHint => 'liitä token tähän';

  @override
  String get scanConnect => 'Yhdistä';

  @override
  String get scanInvalidQr => 'Virheellinen QR-koodi';

  @override
  String get scanNotKofQr =>
      'Ei Kof-pöydän QR-koodi.\nSkannaa pöydälläsi oleva QR-koodi.';

  @override
  String get scanWrongServer => 'QR-koodi ei osoita Kof-palvelimeen.';

  @override
  String get menuNoItems => 'Ei saatavilla olevia tuotteita';

  @override
  String get menuRetry => 'Yritä uudelleen';

  @override
  String get menuReviewOrder => 'Tarkista tilaus';

  @override
  String get menuScanDifferentTable => 'Skannaa eri pöytä';

  @override
  String orderNumber(int number) {
    return 'Tilaus #$number';
  }

  @override
  String get orderCancelledMessage => 'Tämä tilaus peruutettiin';

  @override
  String get orderAgain => 'Tilaa uudelleen';

  @override
  String get orderScanDifferentTable => 'Skannaa eri pöytä';

  @override
  String get statusNew => 'Tilaus vastaanotettu';

  @override
  String get statusMaking => 'Valmistetaan';

  @override
  String get statusReady => 'Valmis noudettavaksi';

  @override
  String get statusCompleted => 'Valmis';

  @override
  String get statusCancelled => 'Peruutettu';

  @override
  String get menuItemLowStock => 'Vähän varastossa';

  @override
  String get menuItemUnavailable => 'Ei saatavilla';

  @override
  String get menuItemAdd => 'Lisää';

  @override
  String get cartYourOrder => 'Tilauksesi';

  @override
  String get cartNoteHint => 'Lisää huomio (valinnainen)';

  @override
  String cartEach(String price) {
    return '$price kpl';
  }

  @override
  String get cartPlaceOrder => 'Tee tilaus';

  @override
  String get myOrdersTitle => 'Omat tilaukset';

  @override
  String get myOrdersEmpty => 'Ei vielä tilauksia';

  @override
  String get myOrdersEmptySubtitle =>
      'Kahviloissa tekemäsi tilaukset näkyvät täällä.';

  @override
  String get myOrdersScanCta => 'Skannaa pöydän QR-koodi';

  @override
  String get notificationsTitle => 'Ilmoitukset';

  @override
  String get notificationsEmpty => 'Ei vielä ilmoituksia';

  @override
  String get notificationsEmptySubtitle =>
      'Seuraa kahviloita saadaksesi tietoja tarjouksista ja erikoistarjouksista.';

  @override
  String get settingsTitle => 'Asetukset';

  @override
  String get settingsPreferences => 'Asetukset';

  @override
  String get settingsHapticFeedback => 'Haptinen palaute';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Tunne hienovaraiset napautukset sovellusta käytettäessä';

  @override
  String get settingsAbout => 'Tietoja';

  @override
  String get settingsVersion => 'Versio';

  @override
  String get settingsPrivacyPolicy => 'Tietosuojakäytäntö';

  @override
  String get settingsTerms => 'Käyttöehdot';

  @override
  String get settingsContactUs => 'Ota yhteyttä';

  @override
  String get settingsLogout => 'Kirjaudu ulos';

  @override
  String get settingsLogoutConfirm => 'Haluatko varmasti kirjautua ulos?';

  @override
  String get settingsLogoutConfirmYes => 'Kirjaudu ulos';

  @override
  String get settingsNotificationsPermission => 'Ilmoitusluvat';

  @override
  String get settingsNotificationsPermissionSubtitle =>
      'Salli Kofin lähettää push-ilmoituksia';

  @override
  String get mapTitle => 'Kahvilat';

  @override
  String get mapLocationDenied =>
      'Sijaintilupa evätty. Ota se käyttöön Asetuksissa nähdäksesi lähellä olevat kahvilat.';

  @override
  String get mapNoShopsNearby => 'Ei lähellä olevia kahviloita vielä';

  @override
  String get mapNoShopsSubtitle =>
      'Kof-kahvilat näkyvät täällä kun alusta on lanseerattu.';

  @override
  String get mapOpenSettings => 'Avaa asetukset';

  @override
  String get settingsAppearance => 'Ulkoasu';

  @override
  String get settingsThemeMode => 'Teema';

  @override
  String get settingsThemeSystem => 'Järjestelmä';

  @override
  String get settingsThemeLight => 'Vaalea';

  @override
  String get settingsThemeDark => 'Tumma';

  @override
  String get settingsLanguage => 'Kieli';

  @override
  String get settingsLanguageSystem => 'Järjestelmän oletus';

  @override
  String get loginSelectLanguage => 'Kieli';

  @override
  String get loginSelectTheme => 'Teema';

  @override
  String get authErrorInvalidEmail =>
      'Sähköpostiosoite näyttää virheelliseltä.';

  @override
  String get authErrorUserDisabled => 'Tämä tili on poistettu käytöstä.';

  @override
  String get authErrorUserNotFound => 'Tällä sähköpostilla ei löydy tiliä.';

  @override
  String get authErrorWrongPassword => 'Virheellinen sähköposti tai salasana.';

  @override
  String get authErrorInvalidCredential =>
      'Virheellinen sähköposti tai salasana.';

  @override
  String get authErrorEmailInUse => 'Tili tällä sähköpostilla on jo olemassa.';

  @override
  String get authErrorWeakPassword =>
      'Salasana on liian heikko. Kokeile pidempää.';

  @override
  String get authErrorNetwork => 'Ei internet-yhteyttä. Yritä uudelleen.';

  @override
  String get authErrorTooManyRequests =>
      'Liian monta yritystä. Odota hetki ja yritä uudelleen.';

  @override
  String get authErrorGoogleCancelled => 'Google-kirjautuminen peruutettiin.';

  @override
  String get authErrorGoogleFailed =>
      'Google-kirjautuminen epäonnistui. Yritä uudelleen.';

  @override
  String get authErrorUnknown => 'Jotain meni pieleen. Yritä uudelleen.';

  @override
  String get verifyEmailTitle => 'Vahvista sähköpostisi';

  @override
  String verifyEmailSentTo(String email) {
    return 'Lähetimme vahvistuslinkin osoitteeseen $email. Aktivoi tilisi napauttamalla linkkiä.';
  }

  @override
  String get verifyEmailCheck => 'Olen vahvistanut — jatka';

  @override
  String get verifyEmailResend => 'Lähetä uudelleen';

  @override
  String get verifyEmailResent => 'Vahvistusviesti lähetetty.';

  @override
  String get verifyEmailNotYet =>
      'Sähköpostia ei ole vielä vahvistettu. Tarkista myös roskaposti.';

  @override
  String get verifyEmailChangeAccount => 'Käytä toista tiliä';

  @override
  String get drawerFollowedShops => 'Seuratut kahvilat';

  @override
  String get shopFollow => 'Seuraa';

  @override
  String get shopUnfollow => 'Seuraat';

  @override
  String get shopFollowRequiresAccount =>
      'Kirjaudu sisään seurataksesi kahviloita ja saadaksesi päivityksiä.';

  @override
  String get shopFollowFailed => 'Päivitys epäonnistui. Yritä uudelleen.';

  @override
  String get shopAboutHeading => 'Tietoja';

  @override
  String get shopMenuPreviewHeading => 'Menun esikatselu';

  @override
  String get shopReviewsHeading => 'Arvostelut';

  @override
  String get shopDiscountsHeading => 'Tarjoukset';

  @override
  String get shopSectionComingSoon => 'Tulossa pian';

  @override
  String get followedShopsTitle => 'Seuratut kahvilat';

  @override
  String get followedShopsGuestTitle => 'Kirjaudu seurataksesi kahviloita';

  @override
  String get followedShopsGuestBody =>
      'Luo tili seurataksesi kahviloita ja saadaksesi ilmoituksia uutisista ja tarjouksista.';

  @override
  String get followedShopsEmptyTitle => 'Ei seurattuja kahviloita';

  @override
  String get followedShopsEmptyBody =>
      'Avaa kartta löytääksesi kahviloita ja napauta Seuraa saadaksesi päivityksiä.';
}
