import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weather/weather.dart';

/// Serviço de integração com a API do OpenWeatherMap via pacote `weather`.
class WeatherService {
  static WeatherFactory? _factory;

  const WeatherService();

  WeatherFactory get _weatherFactory {
    final cached = _factory;
    if (cached != null) return cached;

    final apiKey = dotenv.env['WEATHER'] ?? '';
    final factory = WeatherFactory(apiKey, language: Language.PORTUGUESE);
    _factory = factory;
    return factory;
  }

  /// Busca o clima atual para as coordenadas informadas.
  Future<Weather> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) {
    return _weatherFactory.currentWeatherByLocation(latitude, longitude);
  }

  /// Mapeia a condição bruta da API (`weatherMain`, ex: "Clear", "Rain")
  /// para uma categoria simplificada usada pela UI.
  String mapCondition(String? weatherMain) {
    debugPrint('Weather: $weatherMain');
    switch (weatherMain?.toLowerCase()) {
      case 'clear':
        return 'sunny';
      case 'clouds':
        return 'cloudy';
      case 'rain':
      case 'drizzle':
        return 'rainy';
      case 'thunderstorm':
        return 'stormy';
      case 'snow':
        return 'snowy';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'foggy';
      default:
        return 'sunny';
    }
  }
}
