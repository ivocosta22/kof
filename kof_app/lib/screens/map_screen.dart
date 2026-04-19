import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../l10n/l10n.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';
import 'shop_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ShopService _shopService = ShopService();
  GoogleMapController? _mapController;
  Position? _position;
  bool _locationDenied = false;
  bool _loading = true;
  List<Shop> _shops = const [];
  StreamSubscription<List<Shop>>? _shopsSub;
  BitmapDescriptor? _markerIcon;

  static const _defaultLatLng = LatLng(38.7169, -9.1399); // Lisbon fallback

  @override
  void initState() {
    super.initState();
    _initLocation();
    _buildCustomMarker().then((icon) {
      if (!mounted) return;
      setState(() => _markerIcon = icon);
    });
    _shopsSub = _shopService.streamShops().listen((shops) {
      if (!mounted) return;
      setState(() => _shops = shops);
    });
  }

  Future<BitmapDescriptor> _buildCustomMarker() async {
    const double w = 110;
    const double h = 140;
    const double cx = w / 2;
    const double cy = 52;
    const double outerR = 52;
    const double innerR = 46;
    const Color green = Color(0xFF3D6B52);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White border circle
    canvas.drawCircle(
      const Offset(cx, cy),
      outerR,
      Paint()..color = Colors.white,
    );
    // Green fill circle
    canvas.drawCircle(const Offset(cx, cy), innerR, Paint()..color = green);

    // Teardrop pointer
    final pointer = Path()
      ..moveTo(cx - 13, cy + innerR - 6)
      ..lineTo(cx + 13, cy + innerR - 6)
      ..lineTo(cx, h)
      ..close();
    canvas.drawPath(pointer, Paint()..color = green);
    // White border on pointer edges
    canvas.drawPath(
      pointer,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Logo inside circle
    final data = await rootBundle.load('assets/logo_app.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (innerR * 1.35).toInt(),
      targetHeight: (innerR * 1.35).toInt(),
    );
    final frame = await codec.getNextFrame();
    final logo = frame.image;
    final logoSize = innerR * 1.35;
    canvas.drawImage(
      logo,
      Offset(cx - logoSize / 2, cy - logoSize / 2),
      Paint(),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 60);
  }

  @override
  void dispose() {
    _shopsSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationDenied = true;
          _loading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = pos;
        _loading = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  LatLng get _initialTarget => _position != null
      ? LatLng(_position!.latitude, _position!.longitude)
      : _defaultLatLng;

  Set<Marker> _buildMarkers() {
    return _shops
        .map(
          (s) => Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.latitude, s.longitude),
            icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: s.name, snippet: s.address),
            onTap: () => _openShop(s),
          ),
        )
        .toSet();
  }

  void _openShop(Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final markers = _buildMarkers();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialTarget,
              zoom: 13,
            ),
            myLocationEnabled: !_locationDenied,
            myLocationButtonEnabled: !_locationDenied,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            markers: markers,
          ),

          if (_loading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_locationDenied)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        color: theme.colorScheme.onErrorContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.mapLocationDenied,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Geolocator.openAppSettings(),
                        child: Text(
                          l10n.mapOpenSettings,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_loading && _shops.isEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.coffee_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mapNoShopsNearby,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.mapNoShopsSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
