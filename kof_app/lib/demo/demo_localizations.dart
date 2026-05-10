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

  static String itemName(AppLocalizations l10n, int itemId, String fallback) {
    switch (itemId) {
      case 1: return l10n.demoItem1Name;
      case 3: return l10n.demoItem3Name;
      case 4: return l10n.demoItem4Name;
      case 5: return l10n.demoItem5Name;
      case 7: return l10n.demoItem7Name;
      case 8: return l10n.demoItem8Name;
      case 9: return l10n.demoItem9Name;
      case 10: return l10n.demoItem10Name;
      case 11: return l10n.demoItem11Name;
      case 12: return l10n.demoItem12Name;
      case 13: return l10n.demoItem13Name;
      case 14: return l10n.demoItem14Name;
      default: return fallback;
    }
  }

  static String itemDescription(AppLocalizations l10n, int itemId, String fallback) {
    switch (itemId) {
      case 1: return l10n.demoItem1Description;
      case 3: return l10n.demoItem3Description;
      case 4: return l10n.demoItem4Description;
      case 5: return l10n.demoItem5Description;
      case 7: return l10n.demoItem7Description;
      case 8: return l10n.demoItem8Description;
      case 9: return l10n.demoItem9Description;
      case 10: return l10n.demoItem10Description;
      case 11: return l10n.demoItem11Description;
      case 12: return l10n.demoItem12Description;
      case 13: return l10n.demoItem13Description;
      case 14: return l10n.demoItem14Description;
      default: return fallback;
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
