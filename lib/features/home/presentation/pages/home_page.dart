import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:run_4_tree/features/exercises/presentation/pages/exercises_page.dart';
import 'package:run_4_tree/features/garden/presentation/pages/garden_page.dart';
import 'package:run_4_tree/features/notifications/presentation/push_permission_prompt.dart';
import 'package:run_4_tree/features/profile/presentation/pages/profile_page.dart';

import '../../../../../core/constants/demo_ads.dart';
import '../../../../../core/constants/map_styles.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/observability/critical_flow_telemetry.dart';
import '../../../../../core/services/rewarded_interstitial_ad_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../garden/data/repositories/tree_garden_repository_impl.dart';
import '../../../garden/data/services/earned_trees.dart';
import '../../../garden/presentation/pages/tree_celebration_page.dart';
import '../../../garden/domain/entities/tree_progress_entity.dart';
import '../../../garden/domain/usecases/credit_ad_revenue_usecase.dart';
import '../../../runs/data/datasources/run_session_local_datasource_impl.dart';
import '../../../runs/data/repositories/run_session_repository_impl.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../../../runs/domain/usecases/save_run_usecase.dart';
import '../../../runs/presentation/pages/run_completed_page.dart';
import '../../../stickers/presentation/controllers/sticker_controller.dart';
import '../../../stickers/presentation/controllers/sticker_controller_factory.dart';
import '../../../stickers/presentation/utils/sticker_marker_factory.dart';
import '../../../stickers/presentation/widgets/sticker_unlocked_dialog.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/run_stats_entity.dart';
import '../../domain/usecases/get_run_stats_usecase.dart';
import '../controllers/home_controller.dart';
import '../widgets/demo_ad_page.dart';
import '../widgets/run_ad_loading_overlay.dart';
import '../widgets/run_banner_ad.dart';
import '../widgets/run_seed_ticker.dart';

enum RunState { idle, running, paused }

enum ExerciseType { bike, walk, run }

/// HomePage — Tela principal do Run4Tree.
///
/// Layout baseado no protótipo:
///   • Google Maps em tela cheia com estilo cartoon (Pokémon GO)
///   • Cards flutuantes de stats (clima, árvores, distância)
///   • Avatar do usuário no canto superior esquerdo
///   • Mascote centralizado com animação de pulso + flutuação
///   • Anel de progresso animado na parte inferior
///   • Bottom navigation bar customizada
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // ─── Controller ────────────────────────────────────────────────────────────
  late final HomeController _controller;

  // ─── Runs (Drift) ──────────────────────────────────────────────────────────
  late final SaveRunUseCase _saveRunUseCase;

  // ─── Anúncios do ciclo da corrida (início/fim/banner → progresso da árvore) ─
  final _runAdService = const RewardedInterstitialAdService();
  late final CreditAdRevenueUseCase _creditAdRevenueUseCase;
  bool _isShowingRunAd = false;

  /// Árvore conquistada esperando um momento calmo para os parabéns (nunca no
  /// meio de um exercício ou de um anúncio).
  StreamSubscription<EarnedTree>? _earnedTreeSub;
  EarnedTree? _pendingCelebration;
  bool _didPrecacheAdIllustrations = false;

  /// Tempo mínimo da tela de carregamento do anúncio — evita o flash
  /// desagradável quando o anúncio falha instantaneamente.
  static const _minRunAdOverlayDuration = Duration(milliseconds: 900);

  /// Quanto tempo a tela segura o resultado do anúncio antes de voltar ao
  /// mapa: o suficiente para ver as sementes creditadas.
  static const _runAdRewardDuration = Duration(milliseconds: 2400);
  static const _runAdMissedDuration = Duration(milliseconds: 1500);

  // ─── Garden tab (refresh ao navegar após uma corrida) ───────────────────────
  final _gardenPageKey = GlobalKey<GardenPageState>();

  // ─── Animações ─────────────────────────────────────────────────────────────
  late final AnimationController _progressAnimCtrl;
  late final Animation<double> _progressAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ─── Mapa ──────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ─── Adesivos (avatar + marcador do usuário no mapa) ───────────────────────
  late final StickerController _stickerController;

  /// Marcador do usuário, desenhado a partir do adesivo escolhido.
  BitmapDescriptor? _userMarkerIcon;

  /// Adesivo que gerou o [_userMarkerIcon] atual — evita redesenhar a toa.
  String? _renderedMarkerAsset;

  /// Última posição conhecida do usuário (marcador do mapa).
  LatLng? _currentPosition;

  /// Stream de GPS fora da corrida, só para manter o marcador no lugar certo.
  StreamSubscription<Position>? _ambientLocationSub;

  Set<Marker> _markers = {};

  // Future que resolve para a posição inicial real do usuário (fallback: São Paulo)
  late final Future<CameraPosition> _initialCameraFuture;

  // ─── Nav ───────────────────────────────────────────────────────────────────
  int _selectedNavIndex = 0;

  // ─── Run State ─────────────────────────────────────────────────────────────
  RunState _runState = RunState.idle;
  ExerciseType _selectedExerciseType = ExerciseType.walk;
  int _runSeconds = 0;
  Timer? _runTimer;

  // ─── Tracking ──────────────────────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _locationSub;
  double _runDistanceKm = 0.0;
  LatLng? _lastTrackingPosition;

  /// Amostras (segundo da corrida, km acumulado) que alimentam o pace e a
  /// velocidade em tempo real. O tempo guardado é o da corrida, não o do
  /// relógio, então pausas não entram na conta.
  final List<_PaceSample> _paceSamples = [];

  /// Janela do pace instantâneo, em segundos de corrida.
  static const int _paceWindowSeconds = 30;

  bool _isMapReady = false;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _controller = HomeController(GetRunStatsUseCase(HomeRepositoryImpl()));
    _controller.addListener(_onStatsLoaded);
    _controller.loadStats();

    // Drift: instancia a cadeia datasource → repository → usecase
    final db = AppDatabase.instance;
    final runDataSource = RunSessionLocalDataSourceImpl(db);
    final runRepository = RunSessionRepositoryImpl(runDataSource);
    _saveRunUseCase = SaveRunUseCase(runRepository);

    _creditAdRevenueUseCase = CreditAdRevenueUseCase(
      TreeGardenRepositoryImpl(),
    );

    // Adesivos: o mesmo controller alimenta o avatar do perfil e o marcador
    // do mapa, então trocar o adesivo no perfil atualiza o mapa na hora.
    _stickerController = createStickerController();
    _stickerController.addListener(_onSelectedStickerChanged);
    _stickerController.load();

    _earnedTreeSub = EarnedTrees.instance.stream.listen((tree) {
      _pendingCelebration = tree;
      unawaited(_maybeShowCelebration());
    });

    // Push do feed: abre o post (também quando o app abriu pelo push).

    // Resolve a posição real do usuário antes de montar o mapa
    _initialCameraFuture = _getInitialCameraPosition();

    // Progresso circular: anima de 0 → valor real quando dados chegam
    _progressAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _progressAnim = CurvedAnimation(
      parent: _progressAnimCtrl,
      curve: Curves.easeOutCubic,
    );

    // Pulso do mascote
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decodifica as ilustrações da tela de anúncio bem antes do primeiro
    // "Start", para a transição já abrir com a imagem pronta.
    if (!_didPrecacheAdIllustrations) {
      _didPrecacheAdIllustrations = true;
      unawaited(RunAdLoadingOverlay.precacheIllustrations(context));
    }
  }

  void _onStatsLoaded() {
    if (_controller.stats != null && !_controller.isLoading) {
      _progressAnimCtrl.forward(from: 0);
    }
  }

  // ─── Marcador do usuário (adesivo) ─────────────────────────────────────────

  void _onSelectedStickerChanged() => _refreshUserMarkerIcon();

  /// Redesenha o bitmap do marcador quando o adesivo escolhido muda.
  Future<void> _refreshUserMarkerIcon() async {
    if (!mounted) return;
    final sticker = _stickerController.selectedSticker;
    if (sticker == null) return;
    if (sticker.assetPath == _renderedMarkerAsset && _userMarkerIcon != null) {
      return;
    }

    try {
      final icon = await StickerMarkerFactory.build(
        assetPath: sticker.assetPath,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      if (!mounted) return;
      setState(() {
        _userMarkerIcon = icon;
        _renderedMarkerAsset = sticker.assetPath;
        _updateUserMarker();
      });
    } catch (e) {
      debugPrint('Erro ao gerar o marcador do adesivo: $e');
    }
  }

  /// Reconstrói o conjunto de marcadores. Chamar sempre dentro de um setState.
  void _updateUserMarker() {
    final position = _currentPosition;
    final icon = _userMarkerIcon;
    if (position == null || icon == null) {
      _markers = {};
      return;
    }
    _markers = {
      Marker(
        markerId: const MarkerId('user_avatar'),
        position: position,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ),
    };
  }

  /// GPS de baixa frequência fora da corrida, só para o marcador acompanhar o
  /// usuário. Durante a corrida quem atualiza é o stream de tracking.
  void _subscribeToAmbientLocation() {
    _ambientLocationSub?.cancel();
    _ambientLocationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 8,
          ),
        ).listen(
          (pos) {
            if (!mounted) return;
            setState(() {
              _currentPosition = LatLng(pos.latitude, pos.longitude);
              _updateUserMarker();
            });
          },
          onError: (Object e) =>
              debugPrint('Erro no stream de localização ambiente: $e'),
        );
  }

  /// Reavalia as conquistas e celebra os adesivos novos, um por vez.
  Future<void> _syncStickersAndCelebrate() async {
    await _stickerController.load();
    if (!mounted) return;

    final pending = List.of(_stickerController.pendingCelebrations);
    for (final sticker in pending) {
      if (!mounted) return;
      final useAsAvatar = await showStickerUnlockedDialog(context, sticker);
      _stickerController.consumeCelebration(sticker);
      if (useAsAvatar) {
        await _stickerController.selectSticker(sticker.id);
      }
    }
  }

  @override
  void dispose() {
    _earnedTreeSub?.cancel();
    _runTimer?.cancel();
    _locationSub?.cancel();
    _ambientLocationSub?.cancel();
    _stickerController.removeListener(_onSelectedStickerChanged);
    _stickerController.dispose();
    _controller.removeListener(_onStatsLoaded);
    _controller.dispose();
    _progressAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    await _showBlockingRunAd(placement: 'run_start', phase: RunAdPhase.start);
    if (!mounted) return;

    setState(() => _runState = RunState.running);
    _runTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _runSeconds++);
    });
    _startTracking();
  }

  /// Mostra os parabéns da árvore conquistada, se o usuário está livre.
  Future<void> _maybeShowCelebration() async {
    final tree = _pendingCelebration;
    if (tree == null ||
        !mounted ||
        _isShowingRunAd ||
        _runState != RunState.idle) {
      return;
    }
    _pendingCelebration = null;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => TreeCelebrationPage(tree: tree)),
    );
    _gardenPageKey.currentState?.refresh();
  }

  void _pauseTimer() {
    setState(() => _runState = RunState.paused);
    _runTimer?.cancel();
    _pauseTracking();
  }

  void _resumeTimer() {
    setState(() => _runState = RunState.running);
    _runTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _runSeconds++);
    });
    _resumeTracking();
  }

  Future<void> _stopTimer() async {
    _runTimer?.cancel();

    // Salva a corrida no banco Drift antes de limpar o estado
    final savedRun = await _saveCurrentRun();

    _stopTracking();

    await _showBlockingRunAd(placement: 'run_end', phase: RunAdPhase.finish);
    if (!mounted) return;

    setState(() {
      _runState = RunState.idle;
      _runSeconds = 0;
    });
    _gardenPageKey.currentState?.refresh();

    // Abre a tela de detalhes com as estatísticas + mapa + compartilhamento
    if (savedRun != null && mounted) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => RunCompletedPage(runSession: savedRun),
        ),
      );
    }

    // Depois do resumo, os parabéns pela árvore conquistada nesta corrida.
    await _maybeShowCelebration();

    // Terminou de se exercitar: momento em que o aviso de "sua árvore foi
    // plantada" faz sentido para quem ainda não permitiu notificações.
    if (mounted) {
      await maybeAskForPushPermission(
        context,
        reason: PushPromptReason.finishedExercise,
      );
    }

    // A corrida pode ter completado uma conquista (distância, sequência...).
    if (mounted) await _syncStickersAndCelebrate();
  }

  /// Exibe um anúncio de vídeo (rewarded interstitial) bloqueante — usado nos
  /// momentos de início e fim de uma corrida. Se falhar ao carregar ou for
  /// fechado sem recompensa, o fluxo segue normalmente sem crédito de
  /// progresso. Reentrância é bloqueada por [_isShowingRunAd].
  Future<void> _showBlockingRunAd({
    required String placement,
    required RunAdPhase phase,
  }) async {
    if (_isShowingRunAd) return;
    _isShowingRunAd = true;

    // Base de comparação para mostrar quantas sementes este anúncio rendeu.
    final statsBefore = _controller.stats;
    final overlayController = RunAdOverlayController(
      phase: phase,
      progressBefore: statsBefore?.progressPercent,
      treesBefore: statsBefore?.treesPlanted,
    );

    final startedAt = DateTime.now();
    var overlayVisible = false;

    if (mounted) {
      overlayVisible = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        useSafeArea: false,
        builder: (_) => RunAdLoadingOverlay(controller: overlayController),
      );
    }

    try {
      // DEMO_ADS (só para gravar o vídeo): troca o AdMob pela tela fictícia.
      final result = DemoAds.enabled && mounted
          ? await showDemoRewardedAd(
              Navigator.of(context, rootNavigator: true),
              placement: placement,
            )
          : await _runAdService.watchAd(placement: placement);
      debugPrint(
        '[Ad:$placement] success=${result.success} '
        'revenueUsd=${result.revenueUsd} estimada=${result.isEstimatedRevenue}',
      );
      if (result.success) {
        final progress = await _creditAdRevenueUseCase(result.revenueUsd);
        unawaited(CriticalFlowTelemetry.seedRewarded(source: placement));
        _controller.applyTreeProgress(progress);
        // Mostra o crédito antes de sair: é o momento em que o loop
        // anúncio → sementes → árvore real fica visível para o usuário.
        overlayController.markRewarded(progress);
        await Future<void>.delayed(_runAdRewardDuration);
      } else {
        debugPrint('Anúncio de $placement não exibido: ${result.errorMessage}');
        overlayController.markMissed();
        await Future<void>.delayed(_runAdMissedDuration);
      }
    } catch (e, st) {
      unawaited(
        CriticalFlowTelemetry.seedRewardFailed(
          source: placement,
          error: e,
          stackTrace: st,
        ),
      );
      debugPrint('Erro no anúncio de $placement: $e');
      overlayController.markMissed();
      await Future<void>.delayed(_runAdMissedDuration);
    } finally {
      _isShowingRunAd = false;
      // Se o anúncio falhar na hora (sem unidade configurada, sem rede...),
      // a animação não some num piscar de olhos.
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < _minRunAdOverlayDuration) {
        await Future<void>.delayed(_minRunAdOverlayDuration - elapsed);
      }
      if (overlayVisible && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      overlayController.dispose();
    }
  }

  /// Chamado pelo [RunBannerAd] a cada crédito de receita durante a corrida.
  Future<void> _onBannerAdRevenue(double revenueUsd) async {
    debugPrint('[Ad:banner] revenueUsd=$revenueUsd');
    try {
      final progress = await _creditAdRevenueUseCase(revenueUsd);
      unawaited(CriticalFlowTelemetry.seedRewarded(source: 'run_banner'));
      if (mounted) _controller.applyTreeProgress(progress);
    } catch (e, st) {
      unawaited(
        CriticalFlowTelemetry.seedRewardFailed(
          source: 'run_banner',
          error: e,
          stackTrace: st,
        ),
      );
      debugPrint('Erro ao creditar receita do banner: $e');
    }
  }

  /// Persiste a sessão de corrida atual no SQLite via Drift.
  /// Retorna a entidade salva (com o ID) ou `null` se não houver corrida.
  Future<RunSessionEntity?> _saveCurrentRun() async {
    // Não salva se não houve movimentação
    if (_runSeconds <= 0 && _runDistanceKm <= 0) return null;

    try {
      // Serializa a polyline como JSON
      final polylineJson = jsonEncode(
        _routePoints.map((p) => [p.latitude, p.longitude]).toList(),
      );

      // Calcula métricas
      final durationHours = _runSeconds / 3600.0;
      final avgSpeed = durationHours > 0 ? _runDistanceKm / durationHours : 0.0;
      final pace = _runDistanceKm > 0
          ? (_runSeconds / 60.0) / _runDistanceKm
          : 0.0;

      // Estimativa simples de calorias (MET * peso_medio * horas)
      final calories = _exerciseMet * 70.0 * durationHours; // 70kg padrão

      final entity = RunSessionEntity(
        durationSeconds: _runSeconds,
        distanceKm: _runDistanceKm,
        calories: calories,
        averageSpeed: avgSpeed,
        maxSpeed: avgSpeed, // TODO: rastrear velocidade máxima real
        pace: pace,
        polyline: polylineJson,
        temperature: _controller.stats?.weatherTemp.toString(),
        isNight: false, // TODO: determinar via hora do dia
        treesEarned: 0,
        exerciseType: _selectedExerciseType.name,
        createdAt: DateTime.now(),
      );

      final savedId = await _saveRunUseCase(entity);

      return RunSessionEntity(
        id: savedId,
        durationSeconds: entity.durationSeconds,
        distanceKm: entity.distanceKm,
        calories: entity.calories,
        averageSpeed: entity.averageSpeed,
        maxSpeed: entity.maxSpeed,
        pace: entity.pace,
        polyline: entity.polyline,
        temperature: entity.temperature,
        isNight: entity.isNight,
        treesEarned: entity.treesEarned,
        exerciseType: entity.exerciseType,
        createdAt: entity.createdAt,
      );
    } catch (e) {
      debugPrint('Erro ao salvar corrida: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.homeRunSaveErrorMessage,
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return null;
    }
  }

  // ─── GPS Tracking ──────────────────────────────────────────────────────────

  void _startTracking() {
    // Durante a corrida o stream de tracking já atualiza o marcador.
    _ambientLocationSub?.cancel();
    _ambientLocationSub = null;
    _routePoints = [];
    _lastTrackingPosition = null;
    _runDistanceKm = 0.0;
    _paceSamples.clear();
    _subscribeToLocationStream();
  }

  void _pauseTracking() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  void _resumeTracking() {
    // Não limpa os pontos ao resumir — continua o trajeto
    _subscribeToLocationStream();
  }

  void _stopTracking() {
    _locationSub?.cancel();
    _locationSub = null;
    setState(() {
      _routePoints = [];
      _polylines = {};
      _runDistanceKm = 0.0;
      _lastTrackingPosition = null;
      _paceSamples.clear();
    });
    _subscribeToAmbientLocation();
  }

  void _subscribeToLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // atualiza a cada 5 metros
    );
    _locationSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (pos) {
            if (!mounted) return;
            final newPoint = LatLng(pos.latitude, pos.longitude);
            setState(() {
              if (_lastTrackingPosition != null) {
                final meters = Geolocator.distanceBetween(
                  _lastTrackingPosition!.latitude,
                  _lastTrackingPosition!.longitude,
                  newPoint.latitude,
                  newPoint.longitude,
                );
                _runDistanceKm += meters / 1000.0;
              }
              _routePoints.add(newPoint);
              _lastTrackingPosition = newPoint;
              _paceSamples.add(
                _PaceSample(seconds: _runSeconds, km: _runDistanceKm),
              );
              _prunePaceSamples();
              _currentPosition = newPoint;
              _updateUserMarker();
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('run_route'),
                  points: List.from(_routePoints),
                  color: AppColors.accentOrange,
                  width: 5,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                ),
              };
            });
            // Centraliza o mapa na posição atual durante a corrida
            _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
          },
        );
  }

  // ─── Pace / velocidade em tempo real ──────────────────────────────────────

  /// Descarta amostras velhas demais para a janela — a lista não cresce com a
  /// duração da corrida.
  void _prunePaceSamples() {
    final cutoff = _runSeconds - _paceWindowSeconds * 2;
    while (_paceSamples.length > 2 && _paceSamples.first.seconds < cutoff) {
      _paceSamples.removeAt(0);
    }
  }

  /// Velocidade dos últimos [_paceWindowSeconds] segundos, em km/h.
  ///
  /// `null` quando não há movimento recente suficiente para um número honesto
  /// (parado num semáforo, por exemplo) — a UI mostra "--" em vez de um valor
  /// congelado do último ponto de GPS.
  double? get _currentSpeedKmh {
    if (_paceSamples.isEmpty) return null;
    final cutoff = _runSeconds - _paceWindowSeconds;

    _PaceSample? windowStart;
    for (final sample in _paceSamples) {
      if (sample.seconds >= cutoff) {
        windowStart = sample;
        break;
      }
    }
    // Nenhum ponto novo na janela: o usuário não está se movendo.
    if (windowStart == null) return null;

    final km = _paceSamples.last.km - windowStart.km;
    final seconds = _runSeconds - windowStart.seconds;
    if (seconds <= 0 || km < 0.02) return null;
    return km / (seconds / 3600.0);
  }

  /// Pace atual em minutos por quilômetro. `null` quando parado ou lento
  /// demais para um número útil.
  double? get _currentPaceMinPerKm {
    final speed = _currentSpeedKmh;
    if (speed == null || speed <= 0) return null;
    final pace = 60.0 / speed;
    return pace > 30 ? null : pace;
  }

  /// MET aproximado do exercício selecionado, usado nas calorias.
  double get _exerciseMet => switch (_selectedExerciseType) {
    ExerciseType.run => 9.8,
    ExerciseType.bike => 7.5,
    ExerciseType.walk => 3.8,
  };

  /// Calorias estimadas até agora (70 kg como peso padrão).
  double get _currentCalories => _exerciseMet * 70.0 * (_runSeconds / 3600.0);

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildMapPage(),
          const ExercisesPage(),
          GardenPage(key: _gardenPageKey),
          ProfilePage(stickerController: _stickerController),
        ],
      ),
      bottomNavigationBar: _runState == RunState.idle
          ? _buildBottomNavBar()
          : null,
    );
  }

  Widget _buildMapPage() {
    return Stack(
      children: [
        // ── 1. Google Maps (tela cheia) ─────────────────────────────────
        _buildMap(),

        if (_isMapReady) ...[
          // ── 2. Gradient overlay no topo (legibilidade dos cards) ────────
          _buildTopGradient(),

          // ── 3. Gradient overlay na base ─────────────────────────────────
          _buildBottomGradient(),

          // ── 4. Overlay do topo: avatar + stats (oculto durante o exercício) ──
          if (_runState == RunState.idle)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final stats = _controller.stats;
                        if (stats == null) return const SizedBox();
                        return _buildStatsColumn(stats);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // ── 5. HUD de corrida (tempo + km) ───────────────────────────────
          if (_runState != RunState.idle) _buildRunHUD(),

          // ── 6. Banner de anúncio durante a corrida ───────────────────────
          if (_runState != RunState.idle) _buildRunBannerAd(),

          // ── 7. Run Controls ──────────────────────────────────────────────
          _buildRunControls(),
        ],
      ],
    );
  }

  // ─── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FutureBuilder<CameraPosition>(
      future: _initialCameraFuture,
      builder: (context, snapshot) {
        // Aguardando a posição — exibe um indicador discreto sobre fundo escuro
        if (!snapshot.hasData) {
          return Container(
            color: AppColors.primaryDark,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnim.value * 1.1,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.progressGreen.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 20 * _pulseAnim.value,
                                spreadRadius: 5 * _pulseAnim.value,
                              ),
                            ],
                          ),
                          child: Center(
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/forest.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.homeMapLoadingTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.homeMapLoadingSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return GoogleMap(
          initialCameraPosition: snapshot.data!,
          style: MapStyles.cartoonStyle,
          onMapCreated: (controller) => _mapController = controller,
          mapType: MapType.normal,
          // O ponto azul padrão dá lugar ao adesivo escolhido pelo usuário.
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          polylines: _polylines,
          markers: _markers,
        );
      },
    );
  }

  /// Obtém a posição GPS do usuário para a câmera inicial.
  /// Fallback para São Paulo se serviços ou permissão falharem.
  Future<CameraPosition> _getInitialCameraPosition() async {
    const fallback = CameraPosition(
      target: LatLng(-23.550520, -46.633308),
      zoom: 16.5,
    );
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Serviços de localização desabilitados.');
        if (mounted) setState(() => _isMapReady = true);
        return fallback;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permissões de localização negadas.');
          if (mounted) setState(() => _isMapReady = true);
          return fallback;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permissões permanentemente negadas.');
        if (mounted) setState(() => _isMapReady = true);
        return fallback;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final target = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _isMapReady = true;
          _currentPosition = target;
          _updateUserMarker();
        });
        await _refreshUserMarkerIcon();
        _subscribeToAmbientLocation();
      }
      return CameraPosition(target: target, zoom: 16.5);
    } catch (e) {
      debugPrint('Erro ao obter posição inicial: $e');
      if (mounted) setState(() => _isMapReady = true);
      return fallback;
    }
  }

  // ─── Gradients ─────────────────────────────────────────────────────────────

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 180,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x88000000), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 260,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
      ),
    );
  }

  // ─── Avatar ────────────────────────────────────────────────────────────────

  // ─── Stats cards ───────────────────────────────────────────────────────────

  Widget _buildWeatherIcon(String condition) {
    switch (condition) {
      case 'sunny':
        return const Icon(Icons.sunny, color: Color(0xFF90A4AE), size: 22);
      case 'cloudy':
        return const Icon(
          Icons.cloud_rounded,
          color: Color(0xFF90A4AE),
          size: 22,
        );
      case 'rainy':
        return const Icon(
          Icons.water_drop_rounded,
          color: Color(0xFF4FC3F7),
          size: 22,
        );
      case 'stormy':
        return const Icon(
          Icons.thunderstorm_rounded,
          color: Color(0xFF7E57C2),
          size: 22,
        );
      case 'snowy':
        return const Icon(
          Icons.ac_unit_rounded,
          color: Color(0xFF80DEEA),
          size: 22,
        );
      case 'foggy':
        return const Icon(Icons.foggy, color: Color(0xFFB0BEC5), size: 22);
      default:
        return const Icon(
          Icons.wb_sunny_rounded,
          color: Color(0xFFFFC107),
          size: 22,
        );
    }
  }

  Widget _buildStatsColumn(RunStatsEntity stats) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatCard(
          iconWidget: _buildWeatherIcon(stats.weatherCondition),
          topLine: '${stats.weatherTemp}°',
          bottomLine: null,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Widget iconWidget,
    required String topLine,
    String? bottomLine,
  }) {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 5),
          Text(
            topLine,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          if (bottomLine != null) ...[
            const SizedBox(height: 1),
            Text(
              bottomLine,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Progress ring ─────────────────────────────────────────────────────────

  Widget _buildProgressOverlay() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final targetProgress = _controller.stats?.progressPercent ?? 0.0;
        return AnimatedBuilder(
          animation: _progressAnim,
          builder: (context, _) {
            final animatedProgress = targetProgress * _progressAnim.value;
            return _buildProgressRing(animatedProgress, targetProgress);
          },
        );
      },
    );
  }

  Widget _buildProgressRing(double animatedProgress, double targetProgress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: CustomPaint(
            painter: _ProgressRingPainter(progress: animatedProgress),
            child: Center(
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.progressGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.seedling,
                    color: AppColors.primaryDark,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            '${(targetProgress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Run HUD (tempo, distância, pace e calorias ao vivo) ─────────────────

  Widget _buildRunHUD() {
    final l10n = AppLocalizations.of(context)!;
    final isPaused = _runState == RunState.paused;
    final accent = isPaused ? Colors.amber.shade700 : AppColors.progressGreen;

    final h = _runSeconds ~/ 3600;
    final m = (_runSeconds % 3600) ~/ 60;
    final s = _runSeconds % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    // Na bike, pace em min/km não diz nada — a métrica útil é velocidade.
    final isBike = _selectedExerciseType == ExerciseType.bike;
    final (rhythmValue, rhythmLabel) = isBike
        ? (_currentSpeedKmh?.toStringAsFixed(1) ?? '--', l10n.homeHudSpeedLabel)
        : (_formatPace(_currentPaceMinPerKm), l10n.homeHudPaceLabel);

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabeçalho: tipo de exercício + estado da sessão ──────────
            Row(
              children: [
                _buildHUDExerciseChip(),
                const Spacer(),
                _buildHUDStatusPill(isPaused: isPaused, accent: accent),
              ],
            ),
            const SizedBox(height: 6),

            // ── Tempo em destaque ────────────────────────────────────────
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 46,
                fontFamily: GoogleFonts.bebasNeue().fontFamily,
                color: isPaused
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                letterSpacing: 2.5,
                height: 1.0,
              ),
            ),
            Text(
              l10n.homeHudTimeLabel,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 10),

            // ── Distância · ritmo · calorias ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildHUDStat(
                    icon: Icons.route_outlined,
                    value: _runDistanceKm.toStringAsFixed(2),
                    label: l10n.homeHudKmLabel,
                    color: AppColors.progressGreen,
                  ),
                ),
                _buildHUDDivider(),
                Expanded(
                  child: _buildHUDStat(
                    icon: isBike ? Icons.speed_rounded : Icons.bolt_rounded,
                    value: rhythmValue,
                    label: rhythmLabel,
                    color: AppColors.accentOrange,
                  ),
                ),
                _buildHUDDivider(),
                Expanded(
                  child: _buildHUDStat(
                    icon: Icons.local_fire_department_rounded,
                    value: _currentCalories.round().toString(),
                    label: l10n.homeHudCaloriesLabel,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pace legível (ex: 5'12"); "--" enquanto não há movimento suficiente.
  String _formatPace(double? paceMinPerKm) {
    if (paceMinPerKm == null) return '--';
    var minutes = paceMinPerKm.floor();
    var seconds = ((paceMinPerKm - minutes) * 60).round();
    // 4'60" não existe: o arredondamento sobe para o minuto seguinte.
    if (seconds == 60) {
      minutes += 1;
      seconds = 0;
    }
    return '$minutes\'${seconds.toString().padLeft(2, '0')}"';
  }

  Widget _buildHUDExerciseChip() {
    final icon = switch (_selectedExerciseType) {
      ExerciseType.bike => Icons.directions_bike_rounded,
      ExerciseType.walk => Icons.directions_walk_rounded,
      ExerciseType.run => Icons.directions_run_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 5),
          Text(
            _getExerciseName(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Ponto pulsante "ao vivo" — reaproveita o pulso do mascote.
  Widget _buildHUDStatusPill({required bool isPaused, required Color accent}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            // O pulso do mascote varia de 0.95 a 1.06 — remapeia para uma
            // opacidade que pisca de verdade.
            final t = ((_pulseAnim.value - 0.95) / 0.11).clamp(0.0, 1.0);
            return Opacity(
              opacity: isPaused ? 1.0 : 0.35 + 0.65 * t,
              child: child,
            );
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isPaused ? l10n.homeHudPausedValue : l10n.homeHudLiveLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: accent,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHUDDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.withValues(alpha: 0.15),
    );
  }

  // ─── Banner de anúncio durante a corrida ──────────────────────────────────

  Widget _buildRunBannerAd() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32 + 70,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Torna visível o que o banner credita: sem isso o progresso
            // sobe sozinho e o usuário não liga uma coisa à outra.
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final stats = _controller.stats;
                if (stats == null) return const SizedBox.shrink();
                const total = TreeProgressEntity.seedsPerTree;
                return RunSeedTicker(
                  seeds: (stats.progressPercent * total).floor().clamp(
                    0,
                    total,
                  ),
                  treesPlanted: stats.treesPlanted,
                );
              },
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: RunBannerAd(
                onAdRevenue: _onBannerAdRevenue,
                placement: 'run_banner',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHUDStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 24,
              fontFamily: GoogleFonts.bebasNeue().fontFamily,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
              height: 1.1,
            ),
          ),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // ─── Run Controls ──────────────────────────────────────────────────────────

  String _getExerciseName() {
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedExerciseType) {
      case ExerciseType.bike:
        return l10n.homeExerciseBike;
      case ExerciseType.walk:
        return l10n.homeExerciseWalk;
      case ExerciseType.run:
        return l10n.homeExerciseRun;
    }
  }

  Widget _buildExerciseTypeButton(ExerciseType? type, IconData icon) {
    final isSelected = type != null && _selectedExerciseType == type;
    return GestureDetector(
      onTap: () {
        if (type != null) {
          setState(() => _selectedExerciseType = type);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 64,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.progressGreen : Colors.white,
          border: Border.all(color: AppColors.white, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            if (isSelected)
              BoxShadow(
                color: AppColors.progressGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.primaryDark,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildRunControls() {
    if (_runState == RunState.idle) {
      return Positioned(
        bottom: kBottomNavigationBarHeight + 75,
        left: 0,
        right: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildExerciseTypeButton(
                  ExerciseType.bike,
                  Icons.directions_bike_rounded,
                ),
                const SizedBox(width: 8),
                _buildExerciseTypeButton(
                  ExerciseType.walk,
                  Icons.directions_walk_rounded,
                ),
                const SizedBox(width: 8),
                _buildExerciseTypeButton(
                  ExerciseType.run,
                  Icons.directions_run_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _startTimer,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.progressGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.homeStartLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Text(
                                  _getExerciseName(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Controles durante corrida (HUD exibe o tempo/km no topo)
    // Barra de navegação fica oculta durante o exercício, então o
    // espaçamento inferior precisa respeitar a área segura manualmente.
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botão Pause / Resume
          _buildTextButton(
            text: _runState == RunState.running
                ? AppLocalizations.of(context)!.homePauseButton
                : AppLocalizations.of(context)!.homeResumeButton,
            onPressed: _runState == RunState.running
                ? _pauseTimer
                : _resumeTimer,
            color: _runState == RunState.running
                ? Colors.amber
                : AppColors.progressGreen,
          ),
          const SizedBox(width: 16),
          // Botão Stop
          _buildTextButton(
            text: AppLocalizations.of(context)!.homeFinishButton,
            onPressed: _stopTimer,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom navigation ─────────────────────────────────────────────────────

  Widget _buildBottomNavBar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          0,
                          Icons.house,
                          AppLocalizations.of(context)!.homeNavActivity,
                        ),
                        _buildNavItem(
                          1,
                          Icons.bar_chart_rounded,
                          AppLocalizations.of(context)!.homeNavProgress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 88), // Espaço para o anel central
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          2,
                          Icons.forest_rounded,
                          AppLocalizations.of(context)!.homeNavForest,
                        ),
                        _buildNavItem(
                          3,
                          Icons.person_rounded,
                          AppLocalizations.of(context)!.homeNavProfile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(top: -48, child: _buildProgressOverlay()),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (index == 2) _gardenPageKey.currentState?.refresh();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.navSelected
                    : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: GoogleFonts.bebasNeue().fontFamily,
                color: isSelected
                    ? AppColors.navSelected
                    : Colors.grey.shade400,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Painter: Progress Ring ─────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 7.0;

    // Track (fundo)
    final trackPaint = Paint()
      ..color = AppColors.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progresso com gradiente sweep
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.primaryLight, AppColors.progressGreen],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2, // começa do topo
      2 * math.pi * progress, // varre o arco proporcional
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

/// Um ponto de GPS reduzido ao que o cálculo de pace precisa.
class _PaceSample {
  /// Segundo da corrida (não do relógio) em que a amostra foi coletada.
  final int seconds;

  /// Distância acumulada da corrida até esta amostra, em km.
  final double km;

  const _PaceSample({required this.seconds, required this.km});
}
