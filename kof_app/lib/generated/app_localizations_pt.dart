// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Kof';

  @override
  String get appTagline => 'Café. Pedido.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'voce@exemplo.com';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get cancel => 'Cancelar';

  @override
  String get total => 'Total';

  @override
  String tableLabel(String table) {
    return 'Mesa $table';
  }

  @override
  String get loginForgotPassword => 'Esqueceu a senha?';

  @override
  String get loginFieldsRequired => 'Por favor, preencha todos os campos.';

  @override
  String get loginButton => 'Entrar';

  @override
  String get loginOrContinueWith => 'ou continue com';

  @override
  String get loginWithGoogle => 'Continuar com Google';

  @override
  String get loginWithApple => 'Continuar com Apple';

  @override
  String get loginAppleNotAvailable =>
      'Login com Apple não está disponível ainda.';

  @override
  String get loginAsGuest => 'Continuar como Convidado';

  @override
  String get loginNoAccount => 'Não tem uma conta?';

  @override
  String get loginRegister => 'Registar';

  @override
  String get forgotPasswordTitle => 'Esqueci a Senha';

  @override
  String get forgotPasswordHeading => 'Redefinir senha';

  @override
  String get forgotPasswordSubtitle =>
      'Insira o seu endereço de email e enviaremos um link para redefinir a senha.';

  @override
  String get forgotPasswordButton => 'Enviar Link';

  @override
  String get forgotPasswordSuccess => 'Verifique a sua caixa de entrada';

  @override
  String forgotPasswordSuccessBody(String email) {
    return 'Se existir uma conta para $email, um link de redefinição foi enviado.';
  }

  @override
  String get forgotPasswordBackToLogin => 'Voltar ao Login';

  @override
  String get forgotPasswordEmailRequired =>
      'Por favor, insira o seu endereço de email.';

  @override
  String get registerAppBarTitle => 'Criar Conta';

  @override
  String get registerHeading => 'Junte-se ao Kof';

  @override
  String get registerSubtitle =>
      'Crie uma conta para acompanhar pedidos e seguir as suas cafetarias favoritas.';

  @override
  String get registerNameLabel => 'Nome completo';

  @override
  String get registerNameHint => 'João Silva';

  @override
  String get registerPasswordHint => 'Pelo menos 6 caracteres';

  @override
  String get registerPhoneLabel => 'Número de telefone (opcional)';

  @override
  String get registerPhoneHint => '+351 912 000 000';

  @override
  String get registerFieldsRequired =>
      'Por favor, preencha todos os campos obrigatórios.';

  @override
  String get registerPasswordShort =>
      'A senha deve ter pelo menos 6 caracteres.';

  @override
  String get registerButton => 'Criar Conta';

  @override
  String get registerAlreadyAccount => 'Já tem uma conta?';

  @override
  String get registerLogIn => 'Entrar';

  @override
  String homeGreeting(String name) {
    return 'Olá, $name!';
  }

  @override
  String get homeWelcome => 'Bem-vindo ao Kof';

  @override
  String get homeSubtitle => 'O que gostaria de fazer?';

  @override
  String get homeScanTitle => 'Ler QR Code da Mesa';

  @override
  String get homeScanSubtitle => 'Comece a pedir na sua mesa';

  @override
  String get homeMapTitle => 'Cafetarias que usam o Kof';

  @override
  String get homeMapSubtitle => 'Encontre e siga cafetarias perto de si';

  @override
  String get homeMapComingSoon => 'Mapa — em breve';

  @override
  String get homeNotificationsTooltip => 'Notificações';

  @override
  String get homeNotificationsComingSoon => 'Notificações — em breve';

  @override
  String get drawerGuestName => 'Convidado';

  @override
  String get drawerBrowsingAsGuest => 'A navegar como convidado';

  @override
  String get drawerMyOrders => 'Os Meus Pedidos';

  @override
  String get drawerMyOrdersComingSoon => 'Os Meus Pedidos — em breve';

  @override
  String get drawerSettings => 'Definições';

  @override
  String get drawerSettingsComingSoon => 'Definições — em breve';

  @override
  String get drawerLogout => 'Terminar sessão';

  @override
  String get drawerPrivacyPolicy => 'Política de Privacidade';

  @override
  String get drawerTerms => 'Termos e Condições';

  @override
  String get drawerContactUs => 'Contacte-nos';

  @override
  String get drawerVersion => 'Kof v1.0.0';

  @override
  String get scanTitle => 'Ler QR Code da Mesa';

  @override
  String get scanSubtitle => 'Aponte a câmara para o QR code na sua mesa';

  @override
  String get scanConnecting => 'A ligar à cafetaria...';

  @override
  String get scanTryAgain => 'Tentar novamente';

  @override
  String get scanEnterManually => 'Introduzir manualmente';

  @override
  String get scanManualDialogTitle => 'Introdução Manual';

  @override
  String get scanManualServerLabel => 'URL do servidor';

  @override
  String get scanManualServerHint => 'http://192.168.1.10:3000';

  @override
  String get scanManualTableLabel => 'Identificador da mesa';

  @override
  String get scanManualTableHint => '1';

  @override
  String get scanManualTokenLabel => 'Token da mesa';

  @override
  String get scanManualTokenHint => 'colar token aqui';

  @override
  String get scanConnect => 'Ligar';

  @override
  String get scanInvalidQr => 'QR code inválido';

  @override
  String get scanNotKofQr =>
      'Não é um QR code de mesa Kof.\nPor favor, leia o QR code na sua mesa.';

  @override
  String get scanWrongServer => 'O QR code não aponta para um servidor Kof.';

  @override
  String get menuPickupOrder => 'Pedido de balcão';

  @override
  String get menuQrHint => 'A pedir de uma mesa? Leia o QR code da mesa aqui!';

  @override
  String get menuNoItems => 'Sem itens disponíveis';

  @override
  String get menuRetry => 'Tentar novamente';

  @override
  String get menuReviewOrder => 'Rever Pedido';

  @override
  String get menuScanDifferentTable => 'Ler outra mesa';

  @override
  String orderNumber(int number) {
    return 'Pedido #$number';
  }

  @override
  String get orderCancelledMessage => 'Este pedido foi cancelado';

  @override
  String get orderAgain => 'Pedir Novamente';

  @override
  String get orderScanDifferentTable => 'Ler Outra Mesa';

  @override
  String get statusNew => 'Pedido Recebido';

  @override
  String get statusMaking => 'Em Preparação';

  @override
  String get statusReady => 'Pronto para Levantar';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get menuItemLowStock => 'Stock reduzido';

  @override
  String get menuItemUnavailable => 'Indisponível';

  @override
  String get menuItemAdd => 'Adicionar';

  @override
  String get cartYourOrder => 'O Seu Pedido';

  @override
  String get cartNoteHint => 'Adicionar uma nota (opcional)';

  @override
  String cartEach(String price) {
    return '$price cada';
  }

  @override
  String get cartPlaceOrder => 'Fazer Pedido';

  @override
  String get myOrdersTitle => 'Os Meus Pedidos';

  @override
  String get myOrdersEmpty => 'Sem pedidos ainda';

  @override
  String get myOrdersEmptySubtitle =>
      'Os pedidos que fizer em cafetarias aparecerão aqui.';

  @override
  String get myOrdersScanCta => 'Ler um QR code de mesa';

  @override
  String get myOrdersActive => 'Em curso';

  @override
  String get myOrdersHistory => 'Histórico';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsEmpty => 'Sem notificações ainda';

  @override
  String get notificationsEmptySubtitle =>
      'Siga cafetarias para receber atualizações sobre promoções e ofertas especiais.';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsPreferences => 'Preferências';

  @override
  String get settingsHapticFeedback => 'Feedback háptico';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Sentir vibrações suaves ao interagir com a aplicação';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidade';

  @override
  String get settingsTerms => 'Termos e Condições';

  @override
  String get settingsContactUs => 'Contacte-nos';

  @override
  String get settingsLogout => 'Terminar sessão';

  @override
  String get settingsLogoutConfirm =>
      'Tem a certeza que quer terminar a sessão?';

  @override
  String get settingsLogoutConfirmYes => 'Terminar sessão';

  @override
  String get settingsNotificationsPermission => 'Permissões de notificação';

  @override
  String get settingsNotificationsPermissionSubtitle =>
      'Permitir que o Kof envie notificações push';

  @override
  String get mapTitle => 'Cafetarias';

  @override
  String get mapLocationDenied =>
      'Acesso à localização negado. Ative-o nas Definições para ver cafetarias perto de si.';

  @override
  String get mapNoShopsNearby => 'Nenhuma cafetaria por perto ainda';

  @override
  String get mapNoShopsSubtitle =>
      'As cafetarias que usam o Kof aparecerão aqui quando a plataforma for lançada.';

  @override
  String get mapOpenSettings => 'Abrir Definições';

  @override
  String get mapNoShopsCountryHint =>
      'Sem lojas? Pode estar a ver um país diferente da sua localização atual. Atualize o seu país nas Definições.';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsThemeMode => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Padrão do sistema';

  @override
  String get loginSelectLanguage => 'Idioma';

  @override
  String get loginSelectTheme => 'Tema';

  @override
  String get authErrorInvalidEmail => 'O email parece inválido.';

  @override
  String get authErrorUserDisabled => 'Esta conta foi desativada.';

  @override
  String get authErrorUserNotFound =>
      'Nenhuma conta encontrada com este email.';

  @override
  String get authErrorWrongPassword => 'Email ou senha incorretos.';

  @override
  String get authErrorInvalidCredential => 'Email ou senha incorretos.';

  @override
  String get authErrorEmailInUse => 'Já existe uma conta com este email.';

  @override
  String get authErrorWeakPassword =>
      'Senha demasiado fraca. Experimente uma mais longa.';

  @override
  String get authErrorNetwork => 'Sem ligação à internet. Tente novamente.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiadas tentativas. Aguarde um momento e tente novamente.';

  @override
  String get authErrorGoogleCancelled => 'Login com Google cancelado.';

  @override
  String get authErrorGoogleFailed =>
      'Login com Google falhou. Tente novamente.';

  @override
  String get authErrorUnknown => 'Algo correu mal. Tente novamente.';

  @override
  String get verifyEmailTitle => 'Verifique o seu email';

  @override
  String verifyEmailSentTo(String email) {
    return 'Enviámos um link de verificação para $email. Toque no link para ativar a sua conta.';
  }

  @override
  String get verifyEmailCheck => 'Já verifiquei — continuar';

  @override
  String get verifyEmailResend => 'Reenviar email';

  @override
  String get verifyEmailResent => 'Email de verificação enviado.';

  @override
  String get verifyEmailNotYet =>
      'Email ainda não verificado. Verifique a caixa de entrada e o spam.';

  @override
  String get verifyEmailChangeAccount => 'Usar outra conta';

  @override
  String get drawerFollowedShops => 'Lojas seguidas';

  @override
  String get shopFollow => 'Seguir';

  @override
  String get shopUnfollow => 'A seguir';

  @override
  String get shopFollowRequiresAccount =>
      'Inicie sessão para seguir lojas e receber novidades.';

  @override
  String get shopFollowFailed => 'Não foi possível atualizar. Tente novamente.';

  @override
  String get shopAboutHeading => 'Sobre';

  @override
  String get shopMenuPreviewHeading => 'Pré-visualização do menu';

  @override
  String get shopReviewsHeading => 'Avaliações';

  @override
  String get shopDiscountsHeading => 'Descontos';

  @override
  String get shopSectionComingSoon => 'Em breve';

  @override
  String get followedShopsTitle => 'Lojas seguidas';

  @override
  String get followedShopsGuestTitle => 'Inicie sessão para seguir lojas';

  @override
  String get followedShopsGuestBody =>
      'Crie uma conta para seguir lojas e receber novidades e ofertas.';

  @override
  String get followedShopsEmptyTitle => 'Ainda não segue nenhuma loja';

  @override
  String get followedShopsEmptyBody =>
      'Abra o mapa para descobrir lojas e toque em Seguir para receber atualizações.';

  @override
  String get countryLabel => 'País';

  @override
  String get countryHint => 'Selecione o seu país';

  @override
  String get countrySearch => 'Pesquisar países...';

  @override
  String get settingsCountry => 'País';

  @override
  String get shopWalkInButton => 'Pedir Aqui';

  @override
  String get shopWalkInConnecting => 'A ligar...';

  @override
  String get shopWalkInDialogTitle => 'Pedir nesta loja';

  @override
  String get shopWalkInNameLabel => 'O seu nome';

  @override
  String get shopWalkInNameHint => 'ex: João';

  @override
  String get shopWalkInWifi =>
      'Certifique-se de que está ligado ao Wi-Fi da loja';

  @override
  String get shopWalkInError =>
      'Não foi possível ligar ao servidor da loja. Está ligado ao Wi-Fi da loja?';

  @override
  String shopWalkInDistanceLabel(int meters) {
    return '${meters}m de distância';
  }

  @override
  String get menuFeatured => 'Em destaque';

  @override
  String get menuCategories => 'Categorias';

  @override
  String get menuAllItems => 'Todos os itens';

  @override
  String get menuSearchHint => 'Pesquisar bebidas ou comida';

  @override
  String get categoryAll => 'Tudo';

  @override
  String get categoryEspresso => 'Espresso';

  @override
  String get categoryHotDrinks => 'Bebidas Quentes';

  @override
  String get categoryColdDrinks => 'Bebidas Frias';

  @override
  String get categoryPastries => 'Pastelaria';

  @override
  String get categoryFood => 'Comida';

  @override
  String get categoryOther => 'Outros';

  @override
  String get itemDetailSize => 'Tamanho';

  @override
  String get itemDetailQuantity => 'Quantidade';

  @override
  String get itemDetailAddToCart => 'Adicionar ao Carrinho';

  @override
  String get itemDetailPlaceOrder => 'Fazer Pedido';

  @override
  String get itemDetailUnavailable => 'Indisponível de momento';

  @override
  String get itemDetailBack => 'Voltar';

  @override
  String get sizeSmall => 'Pequeno';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get sizeXtraLarge => 'Extra Grande';

  @override
  String get orderStatusItems => 'Itens';

  @override
  String get orderStatusNote => 'Nota';

  @override
  String orderStatusPlacedAt(String time) {
    return 'Feito às $time';
  }

  @override
  String orderStatusPickupFor(String name) {
    return 'Levantamento para $name';
  }

  @override
  String orderStatusItemCount(int count) {
    return '$count item(s)';
  }

  @override
  String get orderStatusPaid => 'Pago';

  @override
  String get orderStatusUnpaid => 'Por pagar';

  @override
  String get orderStatusOffline => 'Sem ligação — tente atualizar';

  @override
  String get receiptTitle => 'Recibo';

  @override
  String get receiptPaidStamp => 'PAGO';

  @override
  String get receiptThankYou => 'Obrigado pela sua visita';

  @override
  String get receiptViewButton => 'Ver Recibo';

  @override
  String get statusReadyTable => 'A caminho da sua mesa';
}
