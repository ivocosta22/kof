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
  String get drawerContactUsFailed => 'Sähköpostia ei voitu avata';

  @override
  String get receiptShare => 'Jaa';

  @override
  String get receiptShareFailed => 'Kuitin jakaminen epäonnistui';

  @override
  String get accountSettingsTakePhoto => 'Ota kuva';

  @override
  String get accountSettingsChooseFromLibrary => 'Valitse kirjastosta';

  @override
  String get accountSettingsPhotoUploadFailed =>
      'Profiilikuvaa ei voitu päivittää';

  @override
  String get apiServerNotReachable => 'Palvelin ei tavoitettavissa';

  @override
  String get apiFailedLoadMenu => 'Menun lataus epäonnistui';

  @override
  String get apiFailedPlaceOrder => 'Tilauksen tekeminen epäonnistui';

  @override
  String get apiOrderNotFound => 'Tilausta ei löytynyt';

  @override
  String get apiFailedLoadDiscounts => 'Alennusten lataus epäonnistui';

  @override
  String get apiUnknownError => 'Jotain meni vikaan. Yritä uudelleen.';

  @override
  String get guestMigrateTitle => 'Siirretäänkö vierailutilisi tiedot?';

  @override
  String guestMigrateBody(int orders, int follows, String both) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: '$orders aiempaa tilausta',
      one: '1 aiempi tilaus',
      zero: '',
    );
    String _temp1 = intl.Intl.selectLogic(both, {'true': ' ja ', 'other': ''});
    String _temp2 = intl.Intl.pluralLogic(
      follows,
      locale: localeName,
      other: '$follows seurattua kahvilaa',
      one: '1 seurattu kahvila',
      zero: '',
    );
    return '$_temp0$_temp1$_temp2 vierailutililtä — siirretäänkö tilillesi?';
  }

  @override
  String get guestMigrateKeep => 'Siirrä tililleni';

  @override
  String get guestMigrateDiscard => 'Hylkää';

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
  String get menuPickupOrder => 'Noutoasiakas';

  @override
  String get menuQrHint => 'Tilaatko pöydältä? Skannaa pöydän QR-koodi täältä!';

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
  String get cartCouponHint => 'Kuponkikoodi';

  @override
  String get cartCouponApply => 'Käytä';

  @override
  String get cartCouponRemove => 'Poista';

  @override
  String get cartCouponInvalid => 'Virheellinen tai vanhentunut kuponki';

  @override
  String cartCouponRequiresCategory(String category) {
    return 'Lisää tuote ryhmästä $category käyttääksesi kuponkia';
  }

  @override
  String cartCouponNeedsTargetCategory(String category) {
    return 'Kuponki koskee vain ryhmää $category — lisää yksi ensin';
  }

  @override
  String shopDiscountsRequires(String category) {
    return 'Vaatii $category';
  }

  @override
  String shopDiscountsAppliesAll(String category) {
    return 'Kohde: $category';
  }

  @override
  String shopDiscountsAppliesQty(int qty, String category) {
    return 'Kohde: $qty× $category';
  }

  @override
  String get shopDiscountsClaimAtCounter =>
      'Pyydä tämä alennus tiskillä maksaessasi';

  @override
  String get cartSubtotal => 'Välisumma';

  @override
  String get cartDiscount => 'Alennus';

  @override
  String cartCouponApplied(String code) {
    return 'Kuponki \"$code\" käytössä';
  }

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
  String get myOrdersActive => 'Aktiiviset';

  @override
  String get myOrdersHistory => 'Historia';

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
  String get mapNoShopsCountryHint =>
      'Ei kahviloita? Selaat ehkä eri maata kuin sijaintisi. Päivitä maasi Asetuksissa.';

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

  @override
  String get countryLabel => 'Maa';

  @override
  String get countryHint => 'Valitse maasi';

  @override
  String get countrySearch => 'Hae maita...';

  @override
  String get settingsCountry => 'Maa';

  @override
  String get settingsCountryDemoDisabled => 'Maa (Pois käytöstä demotilassa)';

  @override
  String get shopWalkInButton => 'Tilaa tässä';

  @override
  String get shopWalkInButtonDemo => 'Tilaa tässä (vain demo)';

  @override
  String get shopWalkInProximityNote =>
      'Oikeassa sovelluksessa voit tilata vain, jos olet 100 metrin säteellä kahvilasta.';

  @override
  String get shopWalkInConnecting => 'Yhdistetään...';

  @override
  String get shopWalkInDialogTitle => 'Tilaa tästä kahvilasta';

  @override
  String get shopWalkInNameLabel => 'Nimesi';

  @override
  String get shopWalkInNameHint => 'esim. Matti';

  @override
  String get shopWalkInNameInvalid => 'Kirjoita oikea nimesi';

  @override
  String get shopWalkInWifi =>
      'Varmista, että olet liittyneenä kahvilan Wi-Fi-verkkoon';

  @override
  String get shopWalkInError =>
      'Kahvilan palvelimeen ei saatu yhteyttä. Oletko kahvilan Wi-Fi-verkossa?';

  @override
  String shopWalkInDistanceLabel(int meters) {
    return '${meters}m päässä';
  }

  @override
  String get mapDemoZoomHint =>
      'Loitonna nähdäksesi kahvilamme Portugalissa ja Suomessa! (Vain demo)';

  @override
  String get menuHello => 'Hei!';

  @override
  String menuHelloUser(String name) {
    return 'Hei, $name!';
  }

  @override
  String get cartBubbleContinue => 'Jatka tilausta';

  @override
  String cartBubbleItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tuotetta ostoskorissa',
      one: '1 tuote ostoskorissa',
    );
    return '$_temp0';
  }

  @override
  String get menuFeatured => 'Suositellut';

  @override
  String get menuCategories => 'Kategoriat';

  @override
  String get menuAllItems => 'Kaikki tuotteet';

  @override
  String get menuSearchHint => 'Etsi juomia tai ruokaa';

  @override
  String get categoryAll => 'Kaikki';

  @override
  String get categoryEspresso => 'Espresso';

  @override
  String get categoryHotDrinks => 'Kuumat juomat';

  @override
  String get categoryColdDrinks => 'Kylmät juomat';

  @override
  String get categoryPastries => 'Leivonnaiset';

  @override
  String get categoryFood => 'Ruoka';

  @override
  String get categoryOther => 'Muut';

  @override
  String get itemDetailSize => 'Koko';

  @override
  String get itemDetailQuantity => 'Määrä';

  @override
  String get itemDetailAddToCart => 'Lisää koriin';

  @override
  String get itemDetailPlaceOrder => 'Tilaa';

  @override
  String get itemDetailUnavailable => 'Ei juuri nyt saatavilla';

  @override
  String get itemDetailBack => 'Takaisin';

  @override
  String get sizeSmall => 'Pieni';

  @override
  String get sizeMedium => 'Keskikokoinen';

  @override
  String get sizeLarge => 'Suuri';

  @override
  String get sizeXtraLarge => 'Erittäin suuri';

  @override
  String get orderStatusItems => 'Tuotteet';

  @override
  String get orderStatusNote => 'Huomio';

  @override
  String orderStatusPlacedAt(String time) {
    return 'Tilattu klo $time';
  }

  @override
  String orderStatusPickupFor(String name) {
    return 'Nouto: $name';
  }

  @override
  String orderStatusItemCount(int count) {
    return '$count tuote(tta)';
  }

  @override
  String get orderStatusPaid => 'Maksettu';

  @override
  String get orderStatusUnpaid => 'Maksamatta';

  @override
  String get orderStatusOffline => 'Ei yhteyttä — päivitä';

  @override
  String get receiptTitle => 'Kuitti';

  @override
  String get receiptPaidStamp => 'MAKSETTU';

  @override
  String get receiptThankYou => 'Kiitos käynnistäsi';

  @override
  String get receiptViewButton => 'Näytä kuitti';

  @override
  String get statusReadyTable => 'Tulossa pöytääsi';

  @override
  String get shopPreviewNotAvailable =>
      'Tämän kahvilan menun esikatselu ei ole vielä saatavilla.';

  @override
  String get shopPreviewUnreachable =>
      'Kahvilaan ei juuri nyt saada yhteyttä. Yritä uudelleen.';

  @override
  String shopReviewsBasedOn(int count) {
    return '$count arvostelun perusteella';
  }

  @override
  String get shopReviewsEmpty => 'Ei vielä arvosteluja';

  @override
  String get shopDiscountsEmpty => 'Ei aktiivisia tarjouksia juuri nyt.';

  @override
  String get shopDiscountsUnreachable =>
      'Tarjouksia ei voitu ladata. Yritä uudelleen.';

  @override
  String shopDiscountsCode(String code) {
    return 'Koodi: $code';
  }

  @override
  String shopDiscountsValidUntil(String date) {
    return 'Voimassa $date asti';
  }

  @override
  String shopDiscountsValidFrom(String date) {
    return 'Alkaa $date';
  }

  @override
  String shopDiscountsPercentOff(int percent) {
    return '$percent% alennus';
  }

  @override
  String shopDiscountsAmountOff(String amount) {
    return '€$amount alennus';
  }

  @override
  String get notificationsClearAll => 'Tyhjennä kaikki';

  @override
  String get notificationsClearConfirmTitle => 'Tyhjennä kaikki ilmoitukset?';

  @override
  String get notificationsClearConfirmBody =>
      'Tämä poistaa kaikki ilmoitukset. Niitä ei voi palauttaa.';

  @override
  String get notificationsCleared => 'Ilmoitukset tyhjennetty';

  @override
  String get notificationsTimeJustNow => 'Juuri nyt';

  @override
  String notificationsTimeMinutes(int minutes) {
    return '$minutes min sitten';
  }

  @override
  String notificationsTimeHours(int hours) {
    return '$hours t sitten';
  }

  @override
  String notificationsTimeDays(int days) {
    return '$days pv sitten';
  }

  @override
  String get accountSettingsTitle => 'Tili';

  @override
  String get accountSettingsSectionProfile => 'Profiili';

  @override
  String get accountSettingsSectionAccount => 'Tili';

  @override
  String get accountSettingsName => 'Näyttönimi';

  @override
  String get accountSettingsPhone => 'Puhelinnumero';

  @override
  String get accountSettingsPhotoUrl => 'Profiilikuvan URL';

  @override
  String get accountSettingsPhotoUrlHint => 'https://example.com/kuva.jpg';

  @override
  String get accountSettingsSave => 'Tallenna muutokset';

  @override
  String get accountSettingsSaved => 'Muutokset tallennettu';

  @override
  String get accountSettingsSaveFailed =>
      'Tallennus epäonnistui. Yritä uudelleen.';

  @override
  String get accountSettingsEmail => 'Sähköpostiosoite';

  @override
  String get accountSettingsEmailGoogle =>
      'Sähköposti on Googlen hallinnoima eikä sitä voi muuttaa tässä.';

  @override
  String get accountSettingsChangePassword => 'Vaihda salasana';

  @override
  String get accountSettingsChangePasswordSubtitle =>
      'Salasanan palautuslinkki lähetetään sähköpostiisi';

  @override
  String get accountSettingsChangePasswordSent =>
      'Salasanan palautuslinkki lähetetty';

  @override
  String get accountSettingsCurrentPassword => 'Nykyinen salasana';

  @override
  String get accountSettingsEmailReauthTitle => 'Vahvista salasana';

  @override
  String get accountSettingsEmailReauthBody =>
      'Anna nykyinen salasanasi päivittääksesi sähköpostiosoitteen.';

  @override
  String get accountSettingsEmailChanged =>
      'Vahvistusviesti lähetetty. Tarkista postilaatikkosi.';

  @override
  String get accountSettingsDemoNotice =>
      'Demotila on käytössä — tämä näyttö on vain visuaalista tarkoitusta varten.';

  @override
  String get loginAsDemoUser => 'Kirjaudu demokäyttäjänä';

  @override
  String get myOrdersClearAllTooltip => 'Tyhjennä kaikki tilaukset (Vain demo)';

  @override
  String get myOrdersClearAllTitle => 'Tyhjennä kaikki tilaukset?';

  @override
  String get myOrdersClearAllBody =>
      'Tämä poistaa kaikki tilaukset historiastasi, mukaan lukien demotilaukset.';

  @override
  String get myOrdersClearAllConfirm => 'Tyhjennä kaikki';

  @override
  String get demoModeTitle => 'Demotila';

  @override
  String get demoScanHeading => 'Valitse demoskenaario';

  @override
  String get demoScanSubtitle => 'Kameraa tai oikeaa kahvilaa ei tarvita.';

  @override
  String get demoShop1Description =>
      'Erikoiskahvia ja kotitekoisia leivonnaisia Helsingin sydämessä. Pavumme tulevat yksittäisiltä tiloilta ja paahdetaan paikan päällä.';

  @override
  String get demoShop2Description =>
      'Porton suosikki kolmannen aallon kahvila. Loistava espresso, vegaaniset leivonnaiset ja aurinkoinen terassi jokinäkymällä.';

  @override
  String get demoDiscount1Title => 'Leivonnais- ja juomatarjous';

  @override
  String get demoDiscount1Description =>
      'Osta mikä tahansa leivonnainen ja saat espresson tai kuuman/kylmän juoman ilmaiseksi.';

  @override
  String get demoDiscount2Title => 'Kesätarjous';

  @override
  String get demoDiscount2Description =>
      '25 % alennus koko tilauksestasi. Ei vähimmäisostoa.';

  @override
  String get demoNotif1Title => 'Viikonlopputarjous!';

  @override
  String get demoNotif1Body =>
      'Croissantit puoleen hintaan tänään. Tule ennen puoltapäivää ja mainitse Kof!';

  @override
  String get demoNotif2Title => 'Uusi kausijuoma';

  @override
  String get demoNotif2Body =>
      'Syksyinen Spice Latte on nyt saatavilla. Kokeile tänään!';

  @override
  String get demoItem1Name => 'Espresso';

  @override
  String get demoItem1Description =>
      'Rikas ja täyteläinen annos talon omaa sekoitusta.';

  @override
  String get demoItem3Name => 'Americano';

  @override
  String get demoItem3Description =>
      'Espresso laimennettuna kuumalla vedellä — puhdas ja pehmeä.';

  @override
  String get demoItem4Name => 'Cappuccino';

  @override
  String get demoItem4Description =>
      'Yhtä paljon espressoa, höyrytettyä maitoa ja samettista vaahtoa.';

  @override
  String get demoItem5Name => 'Latte';

  @override
  String get demoItem5Description =>
      'Espresso silkkisellä höyrytetyllä maidolla. Lisää kaura-, manteli- tai soijamaito.';

  @override
  String get demoItem7Name => 'Kaakao';

  @override
  String get demoItem7Description =>
      'Täyteläistä belgialaista suklaata höyrytetyssä täysmaidossa.';

  @override
  String get demoItem8Name => 'Jääamericano';

  @override
  String get demoItem8Description =>
      'Tupla espresso jään päälle kaadettuna. Virkistävää.';

  @override
  String get demoItem9Name => 'Cold Brew';

  @override
  String get demoItem9Description =>
      'Haudutettu 18 tuntia — silkkisen pehmeää ja vähähappoista.';

  @override
  String get demoItem10Name => 'Matcha Latte';

  @override
  String get demoItem10Description =>
      'Seremoniallisen tason matchaa kauramaidolla.';

  @override
  String get demoItem11Name => 'Suklaamuffini';

  @override
  String get demoItem11Description =>
      'Leivottu päivittäin tuoreena. Täyteläistä tummaa suklaata ja pehmeä keskus.';

  @override
  String get demoItem12Name => 'Croissant';

  @override
  String get demoItem12Description =>
      'Voinen ja hilseilevä. Parhaimmillaan vielä lämpimänä.';

  @override
  String get demoItem13Name => 'Korvapuusti';

  @override
  String get demoItem13Description =>
      'Klassinen pohjoismainen korvapuusti kuorrutuksella.';

  @override
  String get demoItem14Name => 'Avokadotoast';

  @override
  String get demoItem14Description =>
      'Hapanjuurileipää, muussattua avokadoa, chilihiutaleita ja uppomuna.';

  @override
  String get privacyLastUpdated => 'Päivitetty viimeksi: 2026-05-02';

  @override
  String get privacySection1Title => 'Keitä olemme';

  @override
  String get privacySection1Body =>
      'Kof on henkilökohtainen tilaussovellus, jonka avulla voit selata kahviloita, tehdä tilauksia etukäteen ja seurata suosikkikahviloitasi. Tämä on portfolioprojekti — sen takana ei ole oikeaa yritystä.';

  @override
  String get privacySection2Title => 'Mitä keräämme';

  @override
  String get privacySection2Body =>
      'Kun luot tilin, tallennamme sähköpostisi, näyttönimesi ja (valinnaisesti) puhelinnumerosi sekä profiilikuvasi. Kun teet tilauksen, tallennamme tilauksen sisällön, ajan ja sen kahvilan, joka tilauksen vastaanotti. Jos seuraat kahvilaa, tallennamme tämän yhteyden voidaksemme lähettää ilmoituksia.';

  @override
  String get privacySection3Title => 'Miten käytämme tietoja';

  @override
  String get privacySection3Body =>
      'Tilitietoja käytetään kirjautumiseen ja sovelluksen personointiin. Tilaustietoja näytetään sinulle Tilauksissa ja kahvilan henkilökunnalle tilauksen valmistamista varten. Ilmoitusasetuksilla voit vastaanottaa push-viestejä seuraamiltasi kahviloilta.';

  @override
  String get privacySection4Title => 'Kenelle jaamme tietoja';

  @override
  String get privacySection4Body =>
      'Emme myy tietojasi. Tilauksen tiedot jaetaan vain sen kahvilan kanssa, josta tilasit. Tunnistautumisen ja push-viestien lähettämisen hoitaa Firebase (Google) omien tietosuojaehtojensa mukaisesti.';

  @override
  String get privacySection5Title => 'Sinun valintasi';

  @override
  String get privacySection5Body =>
      'Voit muokata tai poistaa nimesi, puhelinnumerosi ja profiilikuvasi Tilin asetuksissa milloin tahansa. Voit lopettaa kahvilan seuraamisen lopettaaksesi sen ilmoitusten vastaanottamisen. Uloskirjautuminen tyhjentää paikallisen istuntosi.';

  @override
  String get privacySection6Title => 'Yhteystiedot';

  @override
  String get privacySection6Body =>
      'Kysymyksiä tästä käytännöstä? Ota yhteyttä customersupport@kof.example.com.';

  @override
  String get termsLastUpdated => 'Päivitetty viimeksi: 2026-05-02';

  @override
  String get termsSection1Title => '1. Tietoja sovelluksesta';

  @override
  String get termsSection1Body =>
      'Kof on henkilökohtainen portfolioprojekti. Käyttämällä sovellusta hyväksyt, että sen takana ei ole oikeaa kaupallista yritystä ja että sovelluksessa näkyvät tilaukset, hinnat ja kahvilat saattavat olla esittelyjä eivätkä oikeita yrityksiä.';

  @override
  String get termsSection2Title => '2. Tilisi';

  @override
  String get termsSection2Body =>
      'Olet vastuussa kirjautumistietojesi turvassa pitämisestä. Sinun on annettava sähköpostiosoite, johon sinulla on pääsy. Voimme jäädyttää tilin, jota käytetään palvelun tai osallistuvien kahviloiden väärinkäyttöön.';

  @override
  String get termsSection3Title => '3. Tilaukset ja maksut';

  @override
  String get termsSection3Body =>
      'Sovelluksen kautta tehdyt tilaukset lähetetään asianomaiselle kahvilalle valmistettavaksi. Maksu hoidetaan tiskillä tai kahvilan omien järjestelmien kautta — sovellus ei tällä hetkellä käsittele maksuja. Sovelluksessa näytettävät alennuskoodit ovat niiden myöntäneen kahvilan ehtojen alaisia.';

  @override
  String get termsSection4Title => '4. Hyväksyttävä käyttö';

  @override
  String get termsSection4Body =>
      'Älä käytä sovellusta kahviloiden henkilökunnan häirintään, vilpillisten tilausten tekemiseen tai yritä päästä käsiksi muiden käyttäjien tietoihin. Automaattinen tietojen kaapiminen tai kuormitustestaus ilman lupaa ei ole sallittua.';

  @override
  String get termsSection5Title => '5. Vastuunrajoitus';

  @override
  String get termsSection5Body =>
      'Sovellus tarjotaan \"sellaisenaan\" ilman minkäänlaisia takuita. Emme ole vastuussa puuttuvista tilauksista, vääristä tuotteista tai mistään sovelluksen käytöstä aiheutuvista tappioista.';

  @override
  String get termsSection6Title => '6. Muutokset';

  @override
  String get termsSection6Body =>
      'Näitä ehtoja voidaan päivittää ajoittain. Käytön jatkaminen muutosten jälkeen tarkoittaa päivitettyjen ehtojen hyväksymistä.';

  @override
  String get termsSection7Title => '7. Yhteystiedot';

  @override
  String get termsSection7Body =>
      'Kysymyksiä tai valituksia? Ota yhteyttä customersupport@kof.example.com.';

  @override
  String activeOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktiivista tilausta',
      one: '1 aktiivinen tilaus',
    );
    return '$_temp0';
  }

  @override
  String get onboardingNext => 'Seuraava';

  @override
  String get onboardingSkip => 'Ohita esittely';

  @override
  String get onboardingGetStarted => 'Aloita';

  @override
  String get onboardingWelcomeTitle => 'Tervetuloa Kofiin';

  @override
  String get onboardingWelcomeBody => 'Tilaa lempikahvisi vaivattomasti.';

  @override
  String get onboardingScanTitle => 'Skannaa, selaa, tilaa';

  @override
  String get onboardingScanBody =>
      'Skannaa pöytäsi QR-koodi, selaa reaaliaikaista valikkoa ja tee tilauksesi sekunneissa.';

  @override
  String get onboardingTrackTitle => 'Seuraa jokaista kulausta';

  @override
  String get onboardingTrackBody =>
      'Seuraa tilaustasi reaaliajassa, kun se etenee uudesta valmistukseen ja noudettavaksi.';

  @override
  String get onboardingFollowTitle => 'Seuraa ja säästä';

  @override
  String get onboardingFollowBody =>
      'Seuraa rakastamiasi kahviloita avataksesi niiden uusimmat tarjoukset ja saadaksesi ilmoituksia uusista eduista.';
}
