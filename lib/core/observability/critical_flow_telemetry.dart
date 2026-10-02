import 'package:sentry_flutter/sentry_flutter.dart';

/// Telemetria dos fluxos que convertem anúncios em impacto ambiental real.
///
/// Os dados enviados são estados técnicos mínimos. Não incluímos IDs de
/// usuário, tokens, valores de receita, URLs de certificado ou payloads.
class CriticalFlowTelemetry {
  const CriticalFlowTelemetry._();

  static Future<void> adWatchStarted(String placement) => _breadcrumb(
    category: 'critical_flow.ad',
    message: 'ad_watch_started',
    data: {'placement': placement},
  );

  static Future<void> adWatchCompleted({
    required String placement,
    required bool usedEstimatedRevenue,
  }) => _breadcrumb(
    category: 'critical_flow.ad',
    message: 'ad_watch_completed',
    data: {
      'placement': placement,
      'revenue_source': usedEstimatedRevenue ? 'estimated' : 'provider',
    },
  );

  static Future<void> adWatchFailed({
    required String placement,
    required String reason,
    Object? error,
    StackTrace? stackTrace,
  }) => _reportFailure(
    flow: 'ad_watch',
    reason: reason,
    data: {'placement': placement},
    error: error,
    stackTrace: stackTrace,
  );

  static Future<void> seedRewarded({required String source}) => _breadcrumb(
    category: 'critical_flow.seed',
    message: 'seed_rewarded',
    data: {'source': source},
  );

  static Future<void> seedRewardFailed({
    required String source,
    required Object error,
    required StackTrace stackTrace,
  }) => _reportFailure(
    flow: 'seed_reward',
    reason: 'credit_failed',
    data: {'source': source},
    error: error,
    stackTrace: stackTrace,
  );

  static Future<void> treePlantingStarted() => _breadcrumb(
    category: 'critical_flow.tree',
    message: 'tree_planting_started',
  );

  static Future<void> treePlanted() => _breadcrumb(
    category: 'critical_flow.tree',
    message: 'tree_planting_completed',
  );

  static Future<void> treePlantingFailed({
    required String reason,
    required Object error,
    required StackTrace stackTrace,
  }) => _reportFailure(
    flow: 'tree_planting',
    reason: reason,
    error: error,
    stackTrace: stackTrace,
  );

  static Future<void> _breadcrumb({
    required String category,
    required String message,
    Map<String, dynamic>? data,
  }) => Sentry.addBreadcrumb(
    Breadcrumb(category: category, message: message, data: data),
  );

  static Future<void> _reportFailure({
    required String flow,
    required String reason,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    void configureScope(Scope scope) {
      scope.setTag('critical_flow', flow);
      scope.setTag('failure_reason', reason);
      scope.setContexts('critical_flow', {
        'flow': flow,
        'reason': reason,
        ...?data,
      });
    }

    if (error != null) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: configureScope,
      );
      return;
    }

    await Sentry.captureMessage(
      '$flow failed',
      level: SentryLevel.warning,
      withScope: configureScope,
    );
  }
}
