import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/themes/app_theme.dart';
import '../../../core/models/address.dart';

class InteractiveLocationMap extends StatefulWidget {
  final Address? initialAddress;
  final Function(double lat, double lng)? onLocationChanged;
  final bool readOnly;

  const InteractiveLocationMap({
    super.key,
    this.initialAddress,
    this.onLocationChanged,
    this.readOnly = false,
  });

  @override
  State<InteractiveLocationMap> createState() => _InteractiveLocationMapState();
}

class _InteractiveLocationMapState extends State<InteractiveLocationMap> {
  late double _markerX;
  late double _markerY;
  late double _currentLat;
  late double _currentLng;
  late double _zoom;

  // Map dimensions
  final double _mapWidth = 600;
  final double _mapHeight = 300;

  // World bounds (approximate)
  final double _minLat = -85.0;
  final double _maxLat = 85.0;
  final double _minLng = -180.0;
  final double _maxLng = 180.0;

  @override
  void initState() {
    super.initState();
    _zoom = 1.0;

    // Initialize with provided address or default location
    if (widget.initialAddress?.latitude != null &&
        widget.initialAddress?.longitude != null) {
      _currentLat = widget.initialAddress!.latitude!;
      _currentLng = widget.initialAddress!.longitude!;
    } else {
      // Default to a central location (e.g., London)
      _currentLat = 51.5074;
      _currentLng = -0.1278;
    }

    _updateMarkerPosition();
  }

  void _updateMarkerPosition() {
    // Convert lat/lng to screen coordinates
    _markerX = (_currentLng - _minLng) / (_maxLng - _minLng) * _mapWidth;
    _markerY = (_maxLat - _currentLat) / (_maxLat - _minLat) * _mapHeight;
  }

  void _updateLatLngFromMarker(double x, double y) {
    // Convert screen coordinates to lat/lng
    _currentLng = _minLng + (x / _mapWidth) * (_maxLng - _minLng);
    _currentLat = _maxLat - (y / _mapHeight) * (_maxLat - _minLat);

    // Clamp values to valid ranges
    _currentLat = _currentLat.clamp(_minLat, _maxLat);
    _currentLng = _currentLng.clamp(_minLng, _maxLng);

    _updateMarkerPosition();

    // Notify parent of location change
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(_currentLat, _currentLng);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.readOnly) return;

    setState(() {
      _markerX = (details.localPosition.dx).clamp(0, _mapWidth);
      _markerY = (details.localPosition.dy).clamp(0, _mapHeight);
      _updateLatLngFromMarker(_markerX, _markerY);
    });
  }

  void _onMapTap(TapDownDetails details) {
    if (widget.readOnly) return;

    setState(() {
      _markerX = details.localPosition.dx.clamp(0, _mapWidth);
      _markerY = details.localPosition.dy.clamp(0, _mapHeight);
      _updateLatLngFromMarker(_markerX, _markerY);
    });
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom * 1.5).clamp(0.1, 5.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom / 1.5).clamp(0.1, 5.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _mapWidth,
      height: _mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Map background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.primaryColor,
                    context.secondaryColor,
                  ],
                ),
              ),
            ),

            // Grid lines (simulating map grid)
            Transform.scale(
              scale: _zoom,
              child: CustomPaint(
                size: Size(_mapWidth, _mapHeight),
                painter: MapGridPainter(context),
              ),
            ),

            // Map tap detector
            GestureDetector(
              onTapDown: _onMapTap,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),

            // Marker
            Positioned(
              left: _markerX - 12,
              top: _markerY - 24,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: context.shadowColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: context.backgroundColor,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Zoom controls
            Positioned(
              right: 8,
              top: 8,
              child: Column(
                children: [
                  _buildZoomButton(Icons.add, _zoomIn),
                  const SizedBox(height: 4),
                  _buildZoomButton(Icons.remove, _zoomOut),
                  const SizedBox(height: 4),
                  _buildZoomButton(Icons.center_focus_strong, _resetZoom),
                ],
              ),
            ),

            // Coordinates display
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.backgroundColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  'Lat: ${_currentLat.toStringAsFixed(6)}, Lng: ${_currentLng.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ),
            // Instructions overlay (only when not readonly)
            if (!widget.readOnly)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.backgroundColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    'Click or drag marker to set location',
                    style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: context.backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Icon(icon, size: 16, color: context.textPrimaryColor),
        ),
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  MapGridPainter(this.context);
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = context.borderColor.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw vertical grid lines
    for (int i = 0; i <= 20; i++) {
      double x = (size.width / 20) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (int i = 0; i <= 10; i++) {
      double y = (size.height / 10) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
