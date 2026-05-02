import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Import for compute()
import 'dart:convert';
import '../session_manager/session_manager.dart';
import '../widgets/home_back_button.dart';
import 'package:gsense_app/api_constants.dart'; // Import ApiConstants

// Fallback GoogleFonts class matching your project structure
class GoogleFonts {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

class DeviceMapScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const DeviceMapScreen({
    super.key,
    this.deviceId = "",
    this.deviceName = "Device",
  });

  @override
  State<DeviceMapScreen> createState() => _DeviceMapScreenState();
}

class _DeviceMapScreenState extends State<DeviceMapScreen> {
  LatLng? _deviceLocation;
  List<LatLng> _boundaryPoints = []; // Holds the fetched 4 corner coordinates
  bool _isLoading = true;
  String _markerName = "Device";

  // Controller to programmatically handle zoom and map movement
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _markerName = widget.deviceName;

    // Defer the API calls until AFTER the first frame renders to prevent
    // blocking the main thread and dropping frames (Choreographer warnings)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDeviceLocation();
    });
  }

  Future<void> _fetchDeviceBoundary(String id) async {
    if (id.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devices/$id/boundary'),
        headers: {
          'Authorization': 'Bearer ${SessionManager().accessToken}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Use compute() to decode JSON in a background isolate, freeing the UI thread
        final jsonResponse = await compute(jsonDecode, response.body);

        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          List<LatLng> points = [];
          for (var point in jsonResponse['data']) {
            double pLat =
                double.tryParse(point['lat']?.toString() ?? "0.0") ?? 0.0;
            double pLng =
                double.tryParse(point['lng']?.toString() ?? "0.0") ?? 0.0;

            if (pLat != 0.0 && pLng != 0.0) {
              points.add(LatLng(pLat, pLng));
            }
          }

          if (mounted && points.isNotEmpty) {
            setState(() {
              _boundaryPoints = points;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching device boundary for map: $e");
    }
  }

  Future<void> _fetchDeviceLocation() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devices/'),
        headers: {
          'Authorization': 'Bearer ${SessionManager().accessToken}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Use compute() to decode potentially large arrays in a background isolate
        final decodedData = await compute(jsonDecode, response.body);
        final List<dynamic> devices = decodedData as List<dynamic>;

        // Find the device matching the passed deviceId
        Map<String, dynamic>? targetDevice;
        for (var device in devices) {
          String currentId = device['id']?.toString() ??
              device['device_uid']?.toString() ??
              "";
          if (currentId == widget.deviceId || widget.deviceId.isEmpty) {
            targetDevice = device;
            break; // Stop at the first match or if no deviceId was given, take the first device
          }
        }

        // If found, update location
        if (targetDevice != null) {
          double lat =
              double.tryParse(targetDevice['latitude']?.toString() ?? "0.0") ??
                  0.0;
          double lng =
              double.tryParse(targetDevice['longitude']?.toString() ?? "0.0") ??
                  0.0;
          String fetchedName =
              targetDevice['location_name']?.toString() ?? widget.deviceName;
          String resolvedId = targetDevice['id']?.toString() ??
              targetDevice['device_uid']?.toString() ??
              "";

          if (lat != 0.0 && lng != 0.0) {
            // Wait for boundary fetching before removing loader
            await _fetchDeviceBoundary(resolvedId);

            if (mounted) {
              setState(() {
                _deviceLocation = LatLng(lat, lng);
                _markerName = fetchedName;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching device location for map: $e");
    }

    // Fallback to SessionManager or default coordinates if API fails or device not found
    _applyFallbackLocation();
  }

  void _applyFallbackLocation() {
    double lat = SessionManager().latitude;
    double lng = SessionManager().longitude;

    if (lat == 0.0 && lng == 0.0) {
      // Default fallback (Dehradun coordinates based on the API example)
      lat = 30.3165;
      lng = 78.0322;
    }

    if (mounted) {
      setState(() {
        _deviceLocation = LatLng(lat, lng);
        _isLoading = false;
      });
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        elevation: 0,
        leading: const HomeBackButton(),
        title: Text(
          "Field Location",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF166534)))
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _deviceLocation!,
                      initialZoom: 18.0, // High initial zoom
                      minZoom: 3.0,
                      maxZoom: 22.0, // Allow zooming in deeply
                    ),
                    children: [
                      TileLayer(
                        // FIX: Added /256/ size param for FlutterMap standardization
                        urlTemplate:
                            'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=${ApiConstants.mapTilerApiKey}',
                        userAgentPackageName: 'com.example.gridsphere',
                        // FIX: Limits API fetch to zoom 18. Extrapolates imagery above zoom 18 avoiding 404 Grey Screens
                        maxNativeZoom: 18,
                      ),
                      // Custom Shape Geo Fencing Layer (Polygon)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            // Dynamically plots API points or fallback mock points
                            points: _boundaryPoints.isNotEmpty
                                ? _boundaryPoints
                                : [
                                    LatLng(
                                        _deviceLocation!.latitude + 0.00015,
                                        _deviceLocation!.longitude -
                                            0.00020), // Top-Left
                                    LatLng(
                                        _deviceLocation!.latitude + 0.00010,
                                        _deviceLocation!.longitude +
                                            0.00025), // Top-Right
                                    LatLng(
                                        _deviceLocation!.latitude - 0.00015,
                                        _deviceLocation!.longitude +
                                            0.00015), // Bottom-Right
                                    LatLng(
                                        _deviceLocation!.latitude - 0.00010,
                                        _deviceLocation!.longitude -
                                            0.00025), // Bottom-Left
                                  ],
                            color: const Color(0xFF166534)
                                .withOpacity(0.2), // Light green fill
                            isFilled: true,
                            borderColor:
                                const Color(0xFF166534), // Solid green border
                            borderStrokeWidth: 2.0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _deviceLocation!,
                            width: 120,
                            height: 80,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        )
                                      ]),
                                  child: Text(
                                    _markerName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.mapPin,
                                  color: Color(0xFF166534),
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Zoom Controls overlaid on the map
                  Positioned(
                    bottom: 30,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: "btn_zoom_in",
                          mini: true,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF166534),
                          onPressed: _zoomIn,
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: "btn_zoom_out",
                          mini: true,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF166534),
                          onPressed: _zoomOut,
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                  // Geo Fence Label Tag
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534).withOpacity(0.4),
                              border: Border.all(
                                  color: const Color(0xFF166534), width: 2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Custom Field Boundary",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF374151),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
