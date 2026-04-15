import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../l10n/l10n.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _position;
  bool _locationDenied = false;
  bool _loading = true;

  static const _defaultLatLng = LatLng(38.7169, -9.1399); // Lisbon fallback

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialTarget,
              zoom: 13,
            ),
            myLocationEnabled: !_locationDenied,
            myLocationButtonEnabled: !_locationDenied,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            // Shop markers will be added here once backend is ready
            markers: const {},
          ),

          // ── Loading overlay ──────────────────────────────────────
          if (_loading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),

          // ── Location denied banner ───────────────────────────────
          if (_locationDenied)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_off_outlined,
                          color: theme.colorScheme.onErrorContainer, size: 18),
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
                        child: Text(l10n.mapOpenSettings,
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── No shops yet card ────────────────────────────────────
          if (!_loading)
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
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.coffee_outlined,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mapNoShopsNearby,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.mapNoShopsSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
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
