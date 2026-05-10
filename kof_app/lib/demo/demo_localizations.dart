import '../generated/app_localizations.dart';

/// Look up localized text for hardcoded demo content (shops, discounts,
/// notifications). Returns the original [fallback] when the id isn't a known
/// demo entity, so production data passes through untouched.
abstract final class DemoL10n {
  static String shopDescription(AppLocalizations l10n, String shopId, String fallback) {
    switch (shopId) {
      case 'demo-shop-1':
        return l10n.demoShop1Description;
      case 'demo-shop-2':
        return l10n.demoShop2Description;
      default:
        return fallback;
    }
  }

  static String discountTitle(AppLocalizations l10n, int discountId, String fallback) {
    switch (discountId) {
      case 1:
        return l10n.demoDiscount1Title;
      case 2:
        return l10n.demoDiscount2Title;
      default:
        return fallback;
    }
  }

  static String discountDescription(AppLocalizations l10n, int discountId, String fallback) {
    switch (discountId) {
      case 1:
        return l10n.demoDiscount1Description;
      case 2:
        return l10n.demoDiscount2Description;
      default:
        return fallback;
    }
  }

  static String notificationTitle(AppLocalizations l10n, String notifId, String fallback) {
    switch (notifId) {
      case 'demo-notif-1':
        return l10n.demoNotif1Title;
      case 'demo-notif-2':
        return l10n.demoNotif2Title;
      default:
        return fallback;
    }
  }

  static String notificationBody(AppLocalizations l10n, String notifId, String fallback) {
    switch (notifId) {
      case 'demo-notif-1':
        return l10n.demoNotif1Body;
      case 'demo-notif-2':
        return l10n.demoNotif2Body;
      default:
        return fallback;
    }
  }
}
