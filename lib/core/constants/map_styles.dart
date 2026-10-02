/// Cartoon-style map JSON for Google Maps — inspired by Pokémon GO's visual language.
/// Soft greens for nature, pastel roads, bright water and minimal labels.
class MapStyles {
  MapStyles._();

  static const String cartoonStyle = '''
[
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5a7a5a"}, {"weight": 0.8}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#ffffff"}, {"weight": 3}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#c9d5c9"}, {"weight": 1}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4a7a4a"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#e8f5e9"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#a8d5a2"}]
  },
  {
    "featureType": "landscape.natural.terrain",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#8fc98f"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f0ece4"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#c8e6c9"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#7bc67e"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [{"visibility": "simplified"}, {"color": "#388e3c"}]
  },
  {
    "featureType": "poi.sports_complex",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#9ccc9c"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#dcedc8"}, {"weight": 1.5}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#fffde7"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#f9e79f"}, {"weight": 1}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#fce4ac"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#f5c842"}, {"weight": 1}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8faa8f"}]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#7ecce3"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4bafc7"}]
  }
]
''';

  /// Cinza claro e discreto do card de compartilhamento (percurso em preto).
  static const String shareLightStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#f2f3f0"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#5f6368"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#cfe8c4"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#e3e3e3"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#b9dcea"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#7aa7b8"}]}
]
''';

  /// Azul-marinho do card de compartilhamento (percurso em branco).
  static const String shareDarkStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1b2336"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a97b0"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1b2336"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#3b4a66"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#1d2a3c"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#212b40"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1f4a33"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#34405a"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1b2336"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#6b7894"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#46557a"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f6fb3"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4f8fc0"}]}
]
''';

  /// Satélite (tipo híbrido): só esconde ícones de comércio e transporte
  /// para o percurso ser o destaque.
  static const String shareSatelliteStyle = '''
[
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]}
]
''';
}
