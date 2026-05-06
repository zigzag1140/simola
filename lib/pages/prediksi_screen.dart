import 'package:flutter/material.dart';
import 'dart:ui';

class PrediksiScreen extends StatelessWidget {
  const PrediksiScreen({super.key});

  final Color textDark = const Color(0xFF103249);
  final Color bgLightBlue = const Color(0xFFEAF2FF);
  final Color textGreen = const Color(0xFF0DB331);
  final Color primaryBlue = const Color(0xFF36ADFD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Biru Solid + Card Kaca (Sama dengan Beranda)
            _buildHeaderSection(),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Kondisi Lengkap (Grid 2x2 Persegi Besar)
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

                  const SizedBox(height: 32),

                  // 3. Rekomendasi
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
                    subtitle: 'Buka aplikasi secara berkala untuk memastikan kondisi di laut.',
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

  // --- WIDGET KOMPONEN ---

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
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
              const Text(
                'Jumat, 02/01/2026',
                style: TextStyle(color: Colors.white, fontSize: 15),
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
                style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(height: 1.5, color: Colors.white.withOpacity(0.8)),
              const SizedBox(height: 8),
              Text(
                'Aman',
                style: TextStyle(color: textGreen, fontSize: 20, fontWeight: FontWeight.bold),
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

  // Grid Responsive (Otomatis bagi layar jadi 2 kolom persegi)
  Widget _buildResponsiveGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lebar layar dikurangi jarak tengah (16px), lalu dibagi 2
        double itemSize = (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildGridBox('Tinggi Gelombang', '0.5 m', itemSize),
            _buildGridBox('Angin', '2 m/s', itemSize),
            _buildGridBox('Suhu', '25°C', itemSize),
            _buildGridBox('Hujan', '5 mm/jam', itemSize),
          ],
        );
      },
    );
  }

  // Kotak Grid
  Widget _buildGridBox(String title, String value, double size) {
    return Container(
      width: size,
      height: size, // Menggunakan size yang sama agar bentuknya persegi presisi (mirip 162x162 di Figma)
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
            style: TextStyle(color: textDark, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            // Font disesuaikan jadi 24px sesuai dengan Figma
            style: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgLightBlue,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: textDark, fontSize: 11),
          ),
        ],
      ),
    );
  }
}