import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final Color primaryBlue = const Color(0xFF36ADFD);
  final Color textDark = const Color(0xFF103249);
  final Color bgLightBlue = const Color(0xFFEAF2FF);
  final Color safeGreen = const Color(0xFF0DB331);

  int _selectedTabIndex = 0;

  final List<String> _tabTitles = ['Gelombang', 'Angin', 'Suhu', 'Curah hujan'];
  final List<String> _dbFields = ['Hs', 'Angin', 'Suhu', 'Hujan'];

  DateTime _tanggalDipilih = DateTime.now();

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? tanggalBaru = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (tanggalBaru != null && tanggalBaru != _tanggalDipilih) {
      setState(() {
        _tanggalDipilih = tanggalBaru;
      });
    }
  }

  String _formatTanggalUI(DateTime date) {
    List<String> namaBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${namaBulan[date.month - 1]} ${date.year}';
  }

  // Format YYYY-MM-DD persis seperti ID Dokumen di Firebase
  String _formatTanggalDB(DateTime date) {
    String bulan = date.month.toString().padLeft(2, '0');
    String tanggal = date.day.toString().padLeft(2, '0');
    return '${date.year}-$bulan-$tanggal';
  }

  // Helper untuk mendapatkan waktu dari Timestamp atau format ISO
  DateTime? _ekstrakWaktuAsli(Map<String, dynamic> item, String keyId) {
    // Coba ambil dari field Waktu kalau ada di dalam object ts_
    if (item.containsKey('Waktu') && item['Waktu'] != null) {
      try {
        return DateTime.parse(item['Waktu']).toLocal();
      } catch (_) {}
    }
    // Jika tidak ada, ekstrak dari nama ts_1778910477_... (epoch time)
    try {
      String epochStr = keyId.split('_')[1]; // Mengambil angka setelah ts_
      int epoch = int.parse(epochStr);
      return DateTime.fromMillisecondsSinceEpoch(epoch * 1000).toLocal();
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    String docId = _formatTanggalDB(_tanggalDipilih);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderWithTabs(),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: StreamBuilder<DocumentSnapshot>(
                // PERUBAHAN: Membaca dari collection 'wavex' dengan docId = Tanggal (YYYY-MM-DD)
                stream: FirebaseFirestore.instance.collection('wavex').doc(docId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildEmptyState('Tidak ada data yang direkam pada tanggal ini.');
                  }

                  Map<String, dynamic> docData = snapshot.data!.data() as Map<String, dynamic>;

                  // 1. Kumpulkan semua data yang berawalan "ts_"
                  List<Map<String, dynamic>> rawDataList = [];
                  docData.forEach((key, value) {
                    if (value is Map && key.startsWith('ts_')) {
                      // Masukkan data ke list sekaligus simpan key aslinya
                      Map<String, dynamic> item = Map<String, dynamic>.from(value);
                      item['key_id'] = key;
                      rawDataList.add(item);
                    }
                  });

                  // 2. Urutkan dari yang terlama ke terbaru berdasarkan key/waktu
                  rawDataList.sort((a, b) => (a['key_id'] as String).compareTo(b['key_id'] as String));

                  // 3. FILTERING: Ambil hanya 1 data setiap 10 Menit
                  List<Map<String, dynamic>> dataTersaring = [];
                  String keranjangTerakhir = "";

                  for (var data in rawDataList) {
                    DateTime? dt = _ekstrakWaktuAsli(data, data['key_id']);

                    if (dt != null) {
                      // Buat keranjang per 10 menit (misal 12:47 jadi 12:40)
                      int menitKeranjang = (dt.minute ~/ 10) * 10;
                      String keranjangSaatIni = "${dt.hour}:$menitKeranjang";

                      // Kalau keranjang baru, masukkan ke daftar tersaring!
                      if (keranjangSaatIni != keranjangTerakhir) {
                        // Format jam rapi (Contoh: 12:47)
                        data['waktu_tampil'] = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                        dataTersaring.add(data);
                        keranjangTerakhir = keranjangSaatIni;
                      }
                    }
                  }

                  if (dataTersaring.isEmpty) {
                    return _buildEmptyState('Data riwayat kosong.');
                  }

                  // Balik datanya untuk tabel (yang terbaru tampil di paling atas)
                  List<Map<String, dynamic>> dataTabel = dataTersaring.reversed.toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real time Wave Data ( ${_tabTitles[_selectedTabIndex]} )',
                        style: TextStyle(color: textDark, fontSize: 12, fontFamily: 'Karla', fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // GRAFIK
                      _buildRealChart(dataTersaring),

                      const SizedBox(height: 24),
                      _buildTableHeader(),
                      const SizedBox(height: 12),

                      // TABEL
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: dataTabel.length,
                        itemBuilder: (context, index) {
                          var item = dataTabel[index];

                          // Helper mengubah apa pun dari ESP jadi double
                          double parseAngka(dynamic val) {
                            if (val == null) return 0.0;
                            if (val is num) return val.toDouble();
                            if (val is String) return double.tryParse(val) ?? 0.0;
                            return 0.0;
                          }

                          return _buildDataRowCard(
                            item['waktu_tampil'] ?? "--:--",
                            item['Status'] ?? "AMAN",
                            "${parseAngka(item['Hs']).toStringAsFixed(1)} m",
                            "${parseAngka(item['Angin']).toStringAsFixed(1)} m/s",
                            "${parseAngka(item['Suhu']).toStringAsFixed(1)} °C",
                            "${parseAngka(item['Hujan']).toStringAsFixed(1)} mm",
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET GRAFIK ---
  Widget _buildRealChart(List<Map<String, dynamic>> dataTersaring) {
    String selectedField = _dbFields[_selectedTabIndex];

    List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 0; i < dataTersaring.length; i++) {
      var itemData = dataTersaring[i];
      double value = 0.0;

      var rawValue = itemData[selectedField];
      if (rawValue != null) {
        if (rawValue is num) value = rawValue.toDouble();
        if (rawValue is String) value = double.tryParse(rawValue) ?? 0.0;
      }

      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
    }

    maxY = maxY == 0 ? 10 : maxY + (maxY * 0.3);

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 10),
      decoration: BoxDecoration(
        color: bgLightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: spots.isEmpty
          ? const Center(child: Text("Data tidak tersedia"))
          : LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: spots.length > 5 ? (spots.length / 5).ceilToDouble() : 1, // Agar jam di bawah tidak numpuk
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dataTersaring.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        dataTersaring[index]['waktu_tampil'] ?? '',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: primaryBlue.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHeaderWithTabs() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 190,
          padding: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const Text('Riwayat Cuaca', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Noto Sans Georgian', fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pilihTanggal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatTanggalUI(_tanggalDipilih), style: TextStyle(color: textDark, fontSize: 14, fontFamily: 'Karla', fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: safeGreen, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -16, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_tabTitles.length, (index) {
              bool isSelected = _selectedTabIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : bgLightBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 1.5),
                  ),
                  child: Text(_tabTitles[index], style: TextStyle(color: isSelected ? Colors.white : textDark, fontSize: 12, fontFamily: 'Karla')),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Kondisi', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Gelombang', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Angin', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Suhu', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Hujan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDataRowCard(String time, String status, String wave, String wind, String temp, String rain) {
    Color statusColor = (status.toUpperCase() == "BAHAYA")
        ? Colors.red
        : (status.toUpperCase() == "WASPADA" ? Colors.orange : safeGreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(color: bgLightBlue, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Waktu: $time', style: TextStyle(color: textDark, fontSize: 11)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(wave, style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(wind, style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(temp, style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(rain, style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}