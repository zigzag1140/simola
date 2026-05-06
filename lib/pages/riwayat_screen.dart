import 'package:flutter/material.dart';

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

  // Index tab yang sedang aktif
  int _selectedTabIndex = 0;

  final List<String> _tabTitles = [
    'Gelombang',
    'Angin',
    'Suhu',
    'Curah hujan'
  ];

  // State Tanggal
  DateTime _tanggalDipilih = DateTime.now();

  // FUNGSI MEMUNCULKAN KALENDER
  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? tanggalBaru = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  // FUNGSI FORMAT TANGGAL
  String _formatTanggal(DateTime date) {
    List<String> namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${namaBulan[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Biru) + DATE PICKER + TAB CHIPS
            _buildHeaderWithTabs(),

            // Jarak dijauhin dikit biar nggak mepet sama tab di atasnya
            const SizedBox(height: 40),

            // 2. KONTEN UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle dinamis
                  Text(
                    'Real time Wave Data ( ${_tabTitles[_selectedTabIndex]} )',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontFamily: 'Karla',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Placeholder Grafik
                  _buildChartPlaceholder(),

                  const SizedBox(height: 24),

                  // Header Tabel Data
                  _buildTableHeader(),

                  const SizedBox(height: 12),

                  // List Data History
                  _buildDataRowCard('12.33', 'Aman', '0,3 m', '5 km/h', '25 °C', '25 mm'),
                  _buildDataRowCard('13.00', 'Aman', '0,3 m', '5 km/h', '25 °C', '25 mm'),
                  _buildDataRowCard('14.00', 'Aman', '0,3 m', '5 km/h', '25 °C', '25 mm'),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildHeaderWithTabs() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Biru
        Container(
          width: double.infinity,
          height: 190,
          padding: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Riwayat Cuaca',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Noto Sans Georgian',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Box Tanggal (Bisa Diklik memunculkan kalender)
              GestureDetector(
                onTap: () => _pilihTanggal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTanggal(_tanggalDipilih), // Menampilkan tanggal dinamis
                        style: TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontFamily: 'Karla',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: safeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Deretan Tab (Gelombang, Angin, dll) melayang di bawah biru
        Positioned(
          bottom: -16,
          left: 0,
          right: 0,
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
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _tabTitles[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : textDark,
                      fontSize: 12,
                      fontFamily: 'Karla',
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // Placeholder untuk grafik
  Widget _buildChartPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgLightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Icon(
                Icons.show_chart_rounded,
                size: 100,
                color: primaryBlue.withOpacity(0.5),
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[400],
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('23:30', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('20:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('16:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('13:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('09:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: bgLightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: TextStyle(color: safeGreen, fontSize: 14, fontWeight: FontWeight.bold)),
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