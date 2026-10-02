import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/share_options.dart';
import '../utils/share_route_camera.dart';

/// Mapa com o percurso usado como fundo do card.
///
/// O usuário pode arrastar e dar zoom para enquadrar do jeito que quiser;
/// trocar o formato reenquadra o trajeto.
class ShareMapBackground extends StatefulWidget {
  final List<LatLng> points;
  final ShareMapStyle style;
  final ShareFormat format;

  const ShareMapBackground({
    super.key,
    required this.points,
    required this.style,
    required this.format,
  });

  @override
  State<ShareMapBackground> createState() => ShareMapBackgroundState();
}

/// Pública para a página pedir o [takeSnapshot] via `GlobalKey`: o GoogleMap
/// é uma platform view e não sai em `RenderRepaintBoundary.toImage`.
class ShareMapBackgroundState extends State<ShareMapBackground> {
  GoogleMapController? _controller;
  Size? _framedSize;

  /// PNG do mapa como está na tela agora.
  Future<Uint8List?> takeSnapshot() async => _controller?.takeSnapshot();

  void _frameRoute(Size size) {
    _controller?.moveCamera(
      CameraUpdate.newCameraPosition(
        shareRouteCamera(
          points: widget.points,
          viewport: size,
          format: widget.format,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_controller != null && size != _framedSize) {
          _framedSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _frameRoute(size);
          });
        }

        return GoogleMap(
          initialCameraPosition: shareRouteCamera(
            points: widget.points,
            viewport: size,
            format: widget.format,
          ),
          onMapCreated: (controller) {
            _controller = controller;
            _framedSize = size;
          },
          mapType: widget.style.mapType,
          style: widget.style.json,
          polylines: {
            Polyline(
              polylineId: const PolylineId('share_route'),
              points: widget.points,
              color: widget.style.routeColor,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          indoorViewEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        );
      },
    );
  }
}
