import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/env.dart';

/// Notificações push (OneSignal).
///
/// O app só carrega o **App ID**, que apenas identifica o app. Quem dispara
/// os pushes é o servidor: as Cloud Functions usam a REST API Key, guardada
/// no Secret Manager, no momento em que uma árvore é plantada de verdade.
///
/// Best-effort como o resto das integrações: sem `ONE_SIGNAL_ID` no `.env`,
/// ou com o SDK indisponível, o app segue funcionando sem notificações.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  /// App ID público do OneSignal.
  static String? get appId => envOrNull('ONE_SIGNAL_ID');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final id = appId;
    if (id == null) {
      debugPrint('[Push] ONE_SIGNAL_ID ausente no .env — push desativado');
      return;
    }
    try {
      OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.warn : OSLogLevel.none,
      );
      OneSignal.initialize(id);
      OneSignal.Notifications.addClickListener(_onNotificationClicked);
      _isInitialized = true;
      debugPrint('[Push] OneSignal inicializado (permissão=$hasPermission)');
    } catch (e) {
      debugPrint('[Push] falha ao inicializar: $e');
    }
  }

  /// Liga o aparelho ao `uid` anônimo usado pelo pedido de plantio.
  Future<void> login(String uid) async {
    if (!_isInitialized) return;
    try {
      await OneSignal.login(uid);
      debugPrint('[Push] external id = $uid');
    } catch (e) {
      debugPrint('[Push] login falhou: $e');
    }
  }

  /// Tags usadas para segmentar os envios de árvores e sementes.
  Future<void> setTags(Map<String, String> tags) async {
    if (!_isInitialized || tags.isEmpty) return;
    try {
      await OneSignal.User.addTags(tags);
      debugPrint('[Push] tags: $tags');
    } catch (e) {
      debugPrint('[Push] setTags falhou: $e');
    }
  }

  bool get hasPermission {
    try {
      return OneSignal.Notifications.permission;
    } catch (_) {
      return false;
    }
  }

  /// Abre o pedido de permissão do sistema. Retorna `true` se o usuário
  /// aceitou. No Android 13+ o diálogo só aparece uma vez por instalação.
  Future<bool> requestPermission() async {
    if (!_isInitialized) return false;
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      debugPrint('[Push] permissão concedida=$granted');
      return granted;
    } catch (e) {
      debugPrint('[Push] requestPermission falhou: $e');
      return false;
    }
  }

  /// Push de árvore plantada abre o certificado; os demais apenas trazem o app
  /// para a frente.
  void _onNotificationClicked(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    debugPrint(
      '[Push] notificação aberta: ${event.notification.title} dados=$data',
    );
    final certificate = certificateUriFrom(data);
    if (certificate == null) return;
    launchUrl(certificate, mode: LaunchMode.externalApplication).then(
      (opened) => debugPrint('[Push] certificado aberto=$opened: $certificate'),
      onError: (Object e) =>
          debugPrint('[Push] falha ao abrir certificado: $e'),
    );
  }

  /// Link do certificado de um push de árvore; `null` para outros pushes ou
  /// link que não seja https.
  @visibleForTesting
  static Uri? certificateUriFrom(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['type'] != 'personal_tree') return null;
    final raw = data['certificateUrl'];
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
