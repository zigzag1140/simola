  import 'package:flutter/material.dart';
  import 'dart:ui'; // Wajib ditambahkan untuk efek Glassmorphism

  // Pastikan import ini sesuai dengan nama folder kamu
  import 'pages/lokasi_screen.dart';
  import 'pages/riwayat_screen.dart';
  import 'pages/prediksi_screen.dart';

  void main() {
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'SiMoLa App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Karla',
          scaffoldBackgroundColor: Colors.white,
        ),
        // 1. SOLUSI PERTAMA: Pintu masuk diubah ke MainWrapper
        home: const MainWrapper(),
      );
    }
  }

  // =========================================================
  // WIDGET PENGONTROL BOTTOM BAR (Main Wrapper)
  // =========================================================
  class MainWrapper extends StatefulWidget {
    const MainWrapper({super.key});

    @override
    State<MainWrapper> createState() => _MainWrapperState();
  }

  class _MainWrapperState extends State<MainWrapper> {
    int _selectedIndex = 0;
    final Color primaryBlue = const Color(0xFF36ADFD);

    // Daftar halaman untuk navigasi
    final List<Widget> _pages = [
      const SimolaHomeScreen(), // Index 0: Beranda
      const PrediksiScreen(), // Index 1: Prediksi (Dummy)
      const LokasiScreen(), // Index 2: Lokasi (Dari lokasi_screen.dart)
      const RiwayatScreen(), // Index 3: Riwayat (Dummy)
    ];

    // Fungsi untuk memindahkan halaman saat bottom bar diklik
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        // Body akan otomatis memuat halaman sesuai urutan index
        body: _pages[_selectedIndex],

        // 2. SOLUSI KEDUA: Bottom Bar diletakkan di sini, bukan di Beranda
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryBlue,
          unselectedItemColor: const Color(0xFF797979),
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          currentIndex: _selectedIndex, // Harus ada ini biar nyala
          onTap: _onItemTapped, // Harus ada ini biar bisa diklik
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded),
              label: 'Prediksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: 'Lokasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
          ],
        ),
      );
    }
  }

  // =========================================================
  // HALAMAN BERANDA (SiMoLa Home Screen)
  // =========================================================
  class SimolaHomeScreen extends StatelessWidget {
    const SimolaHomeScreen({super.key});

    final Color textDark = const Color(0xFF103249);
    final Color bgLightBlue = const Color(0xFFEAF2FF);
    final Color textGreen = const Color(0xFF0DB331);
    final Color primaryBlue = const Color(0xFF36ADFD);

    // --- LOGIKA "BACKEND" TANGGAL ---
    String _dapatkanTanggalHariIni() {
      DateTime now = DateTime.now();
      List<String> namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

      String hari = namaHari[now.weekday - 1];
      String tanggal = now.day.toString().padLeft(2, '0');
      String bulan = now.month.toString().padLeft(2, '0');
      String tahun = now.year.toString();

      return '$hari, $tanggal/$bulan/$tahun';
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        // Di sini sudah TIDAK ADA bottomNavigationBar lagi, biar gak bentrok
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kondisi Lengkap',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildResponsiveGrid(),
                    const SizedBox(height: 24),
                    _buildFishermanStatusCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Rekomendasi untuk kamu',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendationCard(
                      title: 'Tetap pantau nelayan',
                      subtitle:
                          'Buka aplikasi secara berkala untuk memastikan kondisi di laut.',
                    ),
                    _buildRecommendationCard(
                      title: 'Kondisi aman melaut',
                      subtitle: 'Gelombang dan angin masih dalam batas aman.',
                    ),
                    _buildRecommendationCard(
                      title: 'Cek ulang cuaca',
                      subtitle: 'Periksa pembaruan cuaca setiap 30–60 menit.',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildHeaderSection() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 191,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SiMoLa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Sans Georgian',
                  ),
                ),
                const SizedBox(height: 4),
                // --- PANGGIL FUNGSI TANGGAL DI SINI ---
                Text(
                  _dapatkanTanggalHariIni(),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 24),
                _buildGlassStatusCard(),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildGlassStatusCard() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xC1EAF2FF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Kondisi Cuaca di Laut',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1.5, color: Colors.white.withOpacity(0.8)),
                const SizedBox(height: 8),
                Text(
                  'Aman',
                  style: TextStyle(
                    color: textGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lokasi Sistem',
                  style: TextStyle(color: textDark, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildResponsiveGrid() {
      return LayoutBuilder(
        builder: (context, constraints) {
          double itemWidth = (constraints.maxWidth - 24.5) / 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              _buildGridBox('Tinggi\nGelombang', '0.5 m', itemWidth),
              _buildGridBox('Arah\nGelombang', 'Selatan', itemWidth),
              _buildGridBox('Angin', '2 m/s', itemWidth),
              _buildGridBox('Suhu', '25°C', itemWidth),
              _buildGridBox('Hujan', '5 mm/jam', itemWidth),
            ],
          );
        },
      );
    }

    Widget _buildGridBox(String title, String value, double width) {
      return Container(
        width: width,
        height: 102,
        decoration: BoxDecoration(
          color: bgLightBlue,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: textDark, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildFishermanStatusCard() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgLightBlue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Kondisi Nelayan',
              style: TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aman',
              style: TextStyle(
                color: textGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildRecommendationCard({
      required String title,
      required String subtitle,
    }) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgLightBlue,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: textDark, fontSize: 11)),
          ],
        ),
      );
    }
  }