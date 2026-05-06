import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Package utama peta
import 'package:latlong2/latlong.dart'; // Package untuk titik koordinat

class LokasiScreen extends StatefulWidget {
  const LokasiScreen({super.key});

  @override
  State<LokasiScreen> createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen> {
  final Color primaryBlue = const Color(0xFF36ADFD);
  final Color textDark = const Color(0xFF103249);
  final Color bgLightBlue = const Color(0xFFEAF2FF);
  final Color safeGreen = const Color(0xFF0DB331);

  // Controller untuk mengatur peta (seperti zoom)
  final MapController _mapController = MapController();

  // Titik koordinat awal (Area pesisir laut)
  final LatLng _lokasiNelayan = const LatLng(-0.9555, 100.3522);
  double _currentZoom = 14.0;

  // Fungsi untuk tombol Zoom In
  void _zoomIn() {
    setState(() {
      _currentZoom++;
      _mapController.move(_lokasiNelayan, _currentZoom);
    });
  }

  // Fungsi untuk tombol Zoom Out
  void _zoomOut() {
    setState(() {
      _currentZoom--;
      _mapController.move(_lokasiNelayan, _currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Biru
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.only(top: 60),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: const Center(
              child: Text(
                'Lokasi Sistem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Noto Sans Georgian',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Area Peta & Informasi Floating
          Expanded(
            child: Stack(
              children: [
                // FLUTTER MAP MENGGANTIKAN IMAGE DUMMY
                Container(
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  width: double.infinity,
                  height: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _lokasiNelayan,
                      initialZoom: _currentZoom,
                    ),
                    children: [
                      // Layer visual peta dari OpenStreetMap
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.simola.app',
                      ),
                      // Layer penanda (Marker) lokasi nelayan
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _lokasiNelayan,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Card Informasi Floating di bawah peta
                Positioned(
                  bottom: 24,
                  left: 32,
                  right: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: bgLightBlue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '02 Januari 2026',
                              style: TextStyle(
                                color: textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '21.00 WIB',
                              style: TextStyle(color: textDark, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: primaryBlue.withOpacity(0.3),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Aman',
                              style: TextStyle(
                                color: safeGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kondisi Cuaca Laut',
                              style: TextStyle(color: textDark, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Zoom In/Out Floating
                Positioned(
                  top: 32,
                  right: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgLightBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryBlue, width: 1),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, color: primaryBlue),
                          onPressed: _zoomIn, // Fungsi panggil zoom in
                        ),
                        Container(height: 1, width: 30, color: primaryBlue),
                        IconButton(
                          icon: Icon(Icons.remove, color: primaryBlue),
                          onPressed: _zoomOut, // Fungsi panggil zoom out
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}