import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../share/presentation/pages/share_run_page.dart';
import '../../domain/entities/run_session_entity.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tela de detalhes exibida logo após salvar uma corrida.
///
/// Mostra as estatísticas do exercício (distância, tempo, calorias, ritmo,
/// velocidade), o percurso no mapa e uma opção de compartilhamento via
/// share sheet nativo.
class RunCompletedPage extends StatefulWidget {
  final RunSessionEntity runSession;
  final VoidCallback? onClose;

  const RunCompletedPage({super.key, required this.runSession, this.onClose});

  @override
  State<RunCompletedPage> createState() => _RunCompletedPageState();
}

class _RunCompletedPageState extends State<RunCompletedPage> {
  late final List<LatLng> _polylinePoints;
  late final Set<Polyline> _polylines;
  late final Set<Marker> _markers;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _polylinePoints = _decodePolyline(widget.runSession.polyline);
    _setupMapData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  List<LatLng> _decodePolyline(String polylineString) {
    if (polylineString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(polylineString);
      return list.map((element) {
        final lat = double.parse(element[0].toString());
        final lng = double.parse(element[1].toString());
        return LatLng(lat, lng);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void _setupMapData() {
    if (_polylinePoints.isEmpty) return;
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _polylinePoints,
        color: AppColors.accentOrange,
        width: 5,
      ),
    };
    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: _polylinePoints.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: _polylinePoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_polylinePoints.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 200), _fitMapToPolyline);
    }
  }

  void _fitMapToPolyline() {
    final points = _polylinePoints;
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double minLong = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLong = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLong) minLong = point.longitude;
      if (point.longitude > maxLong) maxLong = point.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLong),
          northeast: LatLng(maxLat, maxLong),
        ),
        40.0,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceMinPerKm) {
    final mins = paceMinPerKm.floor();
    final secs = ((paceMinPerKm - mins) * 60).round();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _shareRun() => ShareRunPage.open(context, widget.runSession);

  @override
  Widget build(BuildContext context) {
    final run = widget.runSession;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final dateStr = DateFormat(
      'E., d/MM/yyyy',
      locale,
    ).format(run.createdAt).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          dateStr,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompletedHeader(l10n),
                  _buildMap(),
                  _buildMainStats(run, l10n),
                  _buildDetailedStats(run, l10n),
                ],
              ),
            ),
          ),
          _buildShareBar(l10n),
        ],
      ),
    );
  }

  Widget _buildCompletedHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.progressGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.seedling,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.runCompletedTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 260,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _polylinePoints.isNotEmpty
              ? _polylinePoints.first
              : const LatLng(0, 0),
          zoom: 15,
        ),
        polylines: _polylines,
        markers: _markers,
        onMapCreated: _onMapCreated,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
      ),
    );
  }

  Widget _buildMainStats(RunSessionEntity run, AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMainStat(
            run.distanceKm.toStringAsFixed(2),
            l10n.exercisesDetailsDistance(l10n.homeUnitKm).toUpperCase(),
          ),
          _buildMainStat(
            _formatDuration(run.durationSeconds),
            l10n.exercisesDetailsDuration.toUpperCase(),
          ),
          _buildMainStat(
            run.calories.toStringAsFixed(0),
            l10n.exercisesDetailsCalories.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(RunSessionEntity run, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.timer_outlined,
            title: l10n.exercisesDetailsPace,
            value: '${_formatPace(run.pace)} min/km',
          ),
          _buildListTile(
            icon: Icons.speed_rounded,
            title: l10n.exercisesDetailsAvgSpeed,
            value: '${run.averageSpeed.toStringAsFixed(1)} km/h',
          ),
          _buildListTile(
            icon: Icons.speed_rounded,
            title: l10n.exercisesDetailsMaxSpeed,
            value: '${run.maxSpeed.toStringAsFixed(1)} km/h',
          ),
          _buildListTile(
            icon: Icons.forest_outlined,
            title: l10n.exercisesDetailsSeedsEarned,
            value: '${run.treesEarned}',
          ),
          _buildListTile(
            icon: Icons.access_time_rounded,
            title: l10n.exercisesDetailsStartTime,
            value: DateFormat.Hm(locale).format(run.createdAt),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildShareBar(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: ElevatedButton.icon(
        onPressed: _shareRun,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.progressGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.share_rounded),
        label: Text(
          l10n.runCompletedShareButton,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontFamily: GoogleFonts.bebasNeue().fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildMainStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 28),
              const SizedBox(width: 16),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 24,
            color: Color(0xFFEEEEEE),
          ),
      ],
    );
  }
}
