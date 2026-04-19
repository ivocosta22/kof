import '../l10n/l10n.dart';
import 'auth_service.dart';

/// Maps an [AuthErrorCode] to a localized user-facing message.
String localizedAuthError(AppLocalizations l10n, Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case AuthErrorCode.invalidEmail:
        return l10n.authErrorInvalidEmail;
      case AuthErrorCode.userDisabled:
        return l10n.authErrorUserDisabled;
      case AuthErrorCode.userNotFound:
        return l10n.authErrorUserNotFound;
      case AuthErrorCode.wrongPassword:
        return l10n.authErrorWrongPassword;
      case AuthErrorCode.invalidCredential:
        return l10n.authErrorInvalidCredential;
      case AuthErrorCode.emailAlreadyInUse:
        return l10n.authErrorEmailInUse;
      case AuthErrorCode.weakPassword:
        return l10n.authErrorWeakPassword;
      case AuthErrorCode.networkError:
        return l10n.authErrorNetwork;
      case AuthErrorCode.tooManyRequests:
        return l10n.authErrorTooManyRequests;
      case AuthErrorCode.googleCancelled:
        return l10n.authErrorGoogleCancelled;
      case AuthErrorCode.googleFailed:
        return l10n.authErrorGoogleFailed;
      case AuthErrorCode.unknown:
        return error.rawMessage ?? l10n.authErrorUnknown;
    }
  }
  return l10n.authErrorUnknown;
}
