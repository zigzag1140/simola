import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final MapController _mapController = MapController();

  // Titik default sementara (Pantai Padang), akan langsung ditimpa oleh data Firebase
  LatLng _lokasiNelayan = const LatLng(-0.9555, 100.3522);
  double _currentZoom = 14.0;
  bool _isFirstLocationSet = false;

  @override
  void initState() {
    super.initState();
    // JALANKAN FUNGSI DETEKTIF LOKASI TERAKHIR SAAT HALAMAN DIBUKA
    _cariLokasiTerakhirDiFirebase();
  }

  // --- FUNGSI MENCARI LOKASI VALID TERAKHIR DI HISTORY FIREBASE ---
  Future<void> _cariLokasiTerakhirDiFirebase() async {
    try {
      // 1. Ambil semua dokumen di koleksi wavex
      var snapshot = await FirebaseFirestore.instance.collection('wavex').get();

      // 2. Filter hanya dokumen yang namanya adalah tanggal (mengandung tanda strip '-')
      var docs = snapshot.docs.where((doc) => doc.id.contains('-')).toList();

      // 3. Urutkan dari tanggal paling baru ke terlama
      docs.sort((a, b) => b.id.compareTo(a.id));

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data();

        // 4. Cari key yang berawalan ts_ (timestamp history)
        var keys = data.keys.where((k) => k.startsWith('ts_')).toList();

        // 5. Urutkan waktu dari yang paling terbaru
        keys.sort((a, b) => b.compareTo(a));

        for (var key in keys) {
          // Mendukung nama variabel lama (Latitude/Longitude) atau baru (LA/LO)
          double rawLat = data[key]['LA']?.toDouble() ?? data[key]['Latitude']?.toDouble() ?? 0.0;
          double rawLon = data[key]['LO']?.toDouble() ?? data[key]['Longitude']?.toDouble() ?? 0.0;

          // JIKA KETEMU KOORDINAT YANG BUKAN 0
          if (rawLat != 0.0 && rawLon != 0.0) {
            setState(() {
              _lokasiNelayan = LatLng(rawLat, rawLon);

              // Langsung terbangkan kamera ke lokasi terakhir ini
              if (!_isFirstLocationSet) {
                _isFirstLocationSet = true;
                _mapController.move(_lokasiNelayan, _currentZoom);
              }
            });
            return; // Hentikan pencarian karena lokasi terakhir sudah ketemu!
          }
        }
      }
    } catch (e) {
      print("Gagal mencari riwayat lokasi: $e");
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom++;
      _mapController.move(_lokasiNelayan, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom--;
      _mapController.move(_lokasiNelayan, _currentZoom);
    });
  }

  void _fokusKeKapal() {
    _mapController.move(_lokasiNelayan, _currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Noto Sans Georgian', fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('wavex').doc('latest').snapshots(),
              builder: (context, snapshot) {
                String txtTanggal = "Menunggu...";
                String txtWaktu = "--:-- WIB";
                String txtStatus = "Menunggu";
                Color colorStatus = const Color(0xFF797979);

                bool isGpsLost = false;

                if (snapshot.hasData && snapshot.data!.exists) {
                  Map<String, dynamic> dataTerbaru = snapshot.data!.data() as Map<String, dynamic>;

                  if (dataTerbaru.isNotEmpty) {

                    double? rawLat = dataTerbaru['LA']?.toDouble();
                    double? rawLon = dataTerbaru['LO']?.toDouble();

                    // LOGIKA GPS PUTUS (0 ATAU NULL)
                    if (rawLat == null || rawLon == null || (rawLat == 0.0 && rawLon == 0.0)) {
                      isGpsLost = true;
                      // JIKA GPS PUTUS, JANGAN UBAH _lokasiNelayan.
                      // Biarkan dia menggunakan hasil dari _cariLokasiTerakhirDiFirebase()
                    } else {
                      isGpsLost = false;
                      _lokasiNelayan = LatLng(rawLat, rawLon);

                      if (!_isFirstLocationSet) {
                        _isFirstLocationSet = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _mapController.move(_lokasiNelayan, _currentZoom);
                        });
                      }
                    }

                    dynamic rawSos = dataTerbaru['SOS'];
                    bool isSos = (rawSos == true || rawSos == 1 || rawSos == "1");

                    txtStatus = dataTerbaru['STATUS'] ?? dataTerbaru['SC'] ?? "AMAN";
                    if (isSos) txtStatus = "BAHAYA";

                    colorStatus = (txtStatus.toUpperCase() == "BAHAYA")
                        ? Colors.red
                        : (txtStatus.toUpperCase() == "WASPADA" ? Colors.orange : safeGreen);
                  }
                }

                DateTime dt = DateTime.now();
                List<String> namaBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
                txtTanggal = '${dt.day.toString().padLeft(2, '0')} ${namaBulan[dt.month - 1]} ${dt.year}';
                txtWaktu = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';

                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      width: double.infinity,
                      height: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _lokasiNelayan,
                          initialZoom: _currentZoom,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.simola.app',
                          ),

                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _lokasiNelayan,
                                width: 50,
                                height: 50,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: isGpsLost ? Colors.grey[300] : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                                        border: Border.all(color: isGpsLost ? Colors.grey : colorStatus, width: 2),
                                      ),
                                      child: Icon(
                                        Icons.sailing_rounded,
                                        color: isGpsLost ? Colors.grey : colorStatus,
                                        size: 20,
                                      ),
                                    ),

                                    if (isGpsLost)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.gps_off_rounded,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 24, left: 32, right: 32,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          color: bgLightBlue, borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(txtTanggal, style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(txtWaktu, style: TextStyle(color: textDark, fontSize: 13)),
                              ],
                            ),
                            Container(height: 40, width: 1, color: primaryBlue.withOpacity(0.3)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    isGpsLost ? "GPS LOST" : txtStatus.toUpperCase(),
                                    style: TextStyle(color: isGpsLost ? Colors.red : colorStatus, fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 4),
                                Text('Kondisi Nelayan', style: TextStyle(color: textDark, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 32, right: 32,
                      child: Container(
                        decoration: BoxDecoration(color: bgLightBlue, borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryBlue, width: 1)),
                        child: Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.my_location, color: primaryBlue),
                              onPressed: _fokusKeKapal,
                              tooltip: 'Fokus Lokasi Kapal',
                            ),
                            Container(height: 1, width: 30, color: primaryBlue),
                            IconButton(icon: Icon(Icons.add, color: primaryBlue), onPressed: _zoomIn),
                            Container(height: 1, width: 30, color: primaryBlue),
                            IconButton(icon: Icon(Icons.remove, color: primaryBlue), onPressed: _zoomOut),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}