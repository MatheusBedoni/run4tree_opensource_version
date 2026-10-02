import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

import '../../../../core/services/weather_service.dart';
import '../../../garden/data/repositories/tree_garden_repository_impl.dart';
import '../../../garden/domain/repositories/tree_garden_repository.dart';
import '../../domain/entities/run_stats_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/run_stats_model.dart';

/// Implementação concreta do [HomeRepository].
///
/// O clima é obtido em tempo real via [WeatherService] (OpenWeatherMap),
/// usando a localização atual do dispositivo. Árvores plantadas e o
/// progresso vêm do [TreeGardenRepository] (sementes ganhas assistindo
/// anúncios). Distância continua mockada até a sessão de corrida atual
/// ser exposta aqui.
class HomeRepositoryImpl implements HomeRepository {
  final WeatherService _weatherService;
  final TreeGardenRepository _treeGardenRepository;

  HomeRepositoryImpl({
    WeatherService weatherService = const WeatherService(),
    TreeGardenRepository? treeGardenRepository,
  }) : _weatherService = weatherService,
       _treeGardenRepository =
           treeGardenRepository ?? TreeGardenRepositoryImpl();

  @override
  Future<RunStatsEntity> getRunStats() async {
    final weather = await _fetchWeather();
    final treeProgress = await _treeGardenRepository.getProgress();

    return RunStatsModel(
      treesPlanted: treeProgress.treesPlanted,
      distanceKm: 0,
      progressPercent: treeProgress.progressPercent,
      weatherTemp: weather?.temperature?.celsius?.round() ?? 0,
      weatherCondition: _weatherService.mapCondition(weather?.weatherMain),
    );
  }

  Future<Weather?> _fetchWeather() async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return null;

      return await _weatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('HomeRepositoryImpl._fetchWeather error: $e');
      return null;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }
}
