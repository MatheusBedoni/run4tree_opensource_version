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

  /// Liga este aparelho ao mesmo `uid` anônimo do Firebase usado nos desafios
  /// em grupo — é assim que as Cloud Functions sabem para quem mandar push.
  Future<void> login(String uid) async {
    if (!_isInitialized) return;
    try {
      await OneSignal.login(uid);
      debugPrint('[Push] external id = $uid');
    } catch (e) {
      debugPrint('[Push] login falhou: $e');
    }
  }

  /// Tags usadas para segmentar os envios (árvores, sementes, grupo...).
  Future<void> setTags(Map<String, String> tags) async {
    if (!_isInitialized || tags.isEmpty) return;
    try {
      await OneSignal.User.addTags(tags);
      debugPrint('[Push] tags: $tags');
    } catch (e) {
      debugPrint('[Push] setTags falhou: $e');
    }
  }

  /// Opt-in "Novidades do feed": o servidor manda o push do feed só para
  /// quem tem a tag `feed_updates = 1`.
  Future<void> setFeedUpdates(bool enabled) async {
    if (!_isInitialized) return;
    try {
      if (enabled) {
        await OneSignal.User.addTagWithKey('feed_updates', '1');
      } else {
        await OneSignal.User.removeTag('feed_updates');
      }
      debugPrint('[Push] novidades do feed=$enabled');
    } catch (e) {
      debugPrint('[Push] tag feed_updates falhou: $e');
    }
  }

  /// Item do feed aberto por um push `feed_post`, esperando a home abrir o
  /// feed. A home consome (e limpa) quando está na tela — assim funciona
  /// também com o app fechado, quando o push chega antes da splash sair.
  final ValueNotifier<String?> pendingFeedItem = ValueNotifier<String?>(null);

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

  /// Push de árvore plantada (pessoal ou do grupo) abre o certificado, como o
  /// texto promete; os demais só trazem o app para a frente.
  void _onNotificationClicked(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    debugPrint(
      '[Push] notificação aberta: ${event.notification.title} dados=$data',
    );
    final feedItemId = feedItemIdFrom(data);
    if (feedItemId != null) {
      pendingFeedItem.value = feedItemId;
      return;
    }
    final certificate = certificateUriFrom(data);
    if (certificate == null) return;
    launchUrl(certificate, mode: LaunchMode.externalApplication).then(
      (opened) => debugPrint('[Push] certificado aberto=$opened: $certificate'),
      onError: (Object e) => debugPrint('[Push] falha ao abrir certificado: $e'),
    );
  }

  /// Item do feed de um push `feed_post`; `null` para outros pushes.
  @visibleForTesting
  static String? feedItemIdFrom(Map<String, dynamic>? data) {
    if (data == null || data['type'] != 'feed_post') return null;
    final itemId = data['itemId'];
    return itemId is String && itemId.isNotEmpty ? itemId : null;
  }

  /// Link do certificado de um push de árvore; `null` para outros pushes ou
  /// link que não seja https.
  @visibleForTesting
  static Uri? certificateUriFrom(Map<String, dynamic>? data) {
    if (data == null) return null;
    const treeTypes = {'personal_tree', 'group_tree'};
    if (!treeTypes.contains(data['type'])) return null;
    final raw = data['certificateUrl'];
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
