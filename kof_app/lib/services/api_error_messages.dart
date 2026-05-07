import '../l10n/l10n.dart';
import 'api_service.dart';

/// Maps an [ApiErrorCode] to a localized user-facing message. Falls back to
/// the unknown-error string for non-API errors so callers can pipe any
/// exception through this helper.
String localizedApiError(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case ApiErrorCode.serverNotReachable:
        return l10n.apiServerNotReachable;
      case ApiErrorCode.failedLoadMenu:
        return l10n.apiFailedLoadMenu;
      case ApiErrorCode.failedPlaceOrder:
        return error.rawMessage ?? l10n.apiFailedPlaceOrder;
      case ApiErrorCode.orderNotFound:
        return l10n.apiOrderNotFound;
      case ApiErrorCode.failedLoadDiscounts:
        return l10n.apiFailedLoadDiscounts;
      case ApiErrorCode.unknown:
        return error.rawMessage ?? l10n.apiUnknownError;
    }
  }
  return l10n.apiUnknownError;
}
