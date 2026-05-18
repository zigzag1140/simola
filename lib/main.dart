import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'firebase_options.dart';

import 'pages/lokasi_screen.dart';
import 'pages/riwayat_screen.dart';
import 'pages/prediksi_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.data['tipe'] == 'SOS') {
    _nyalakanAlarmSirene(
      title: message.data['title'] ?? "Nelayan dalam BAHAYA",
      body: message.data['body'] ?? "Segera cek lokasi nelayan dan lakukan bantuan darurat",
    );
  } else if (message.data['tipe'] == 'BAHAYA') {
    _nyalakanNotifikasiBiasa(
      title: message.data['title'] ?? "Peringatan Kondisi Cuaca di Laut",
      body: message.data['body'] ?? "Kondisi cuaca di laut dalam keadaan BAHAYA!",
    );
  }
}

void _nyalakanAlarmSirene({required String title, required String body}) async {
  final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'simola_sos_channel_v2',
    'Sinyal Darurat SOS',
    channelDescription: 'Alarm sirene SOS nelayan',
    importance: Importance.max,
    priority: Priority.high,
    sound: const RawResourceAndroidNotificationSound('sos'),
    playSound: true,
    styleInformation: BigTextStyleInformation(body),
    // Flag 4 membuat suara looping terus menerus sampai di-cancel
    additionalFlags: Int32List.fromList([4]),
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: const DarwinNotificationDetails(sound: 'sos.wav'),
  );

  await flutterLocalNotificationsPlugin.show(911, title, body, platformChannelSpecifics);
}

void _nyalakanNotifikasiBiasa({required String title, required String body}) async {
  final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'simola_weather_channel',
    'Peringatan Cuaca Laut',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    styleInformation: BigTextStyleInformation(body),
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: const DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.show(112, title, body, platformChannelSpecifics);
}

// Background Service
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_kapal');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  String statusTerakhir = "Aman";
  bool sosTerakhir = false; // Mencegah spam alarm looping dari Firebase

  FirebaseFirestore.instance.collection('wavex').doc('latest').snapshots().listen((snapshot) {
    if (snapshot.exists) {
      Map<String, dynamic> dataTerbaru = snapshot.data() as Map<String, dynamic>;

      if (dataTerbaru.isNotEmpty) {
        String statusBaru = dataTerbaru['SC'] ?? "Aman";
        bool isSos = dataTerbaru['SOS'] ?? false;

        double hs = dataTerbaru['HS']?.toDouble() ?? 0.0;
        double angin = dataTerbaru['WS']?.toDouble() ?? 0.0;

        // Logika Darurat SOS (Hanya memicu 1x saat baru ditekan)
        if (isSos == true && sosTerakhir == false) {
          _nyalakanAlarmSirene(
            title: "Nelayan dalam BAHAYA",
            body: "Segera cek lokasi nelayan dan lakukan bantuan darurat.",
          );
          sosTerakhir = true;
        } else if (isSos == false) {
          sosTerakhir = false; // Reset jika status di ESP32 sudah balik aman
        }

        // Logika Cuaca (Tidak jalan jika SOS sedang aktif)
        if (isSos == false) {
          if (statusBaru == "BAHAYA" && statusTerakhir != "BAHAYA") {
            _nyalakanNotifikasiBiasa(
              title: "Peringatan Kondisi Cuaca di Laut",
              body: "Kondisi cuaca di laut dalam keadaan BAHAYA dengan Tinggi gelombang : ${hs.toStringAsFixed(2)} m | Angin : ${angin.toStringAsFixed(1)} km/h",
            );
            statusTerakhir = statusBaru;
          }
          else if (statusBaru != "BAHAYA") {
            statusTerakhir = statusBaru;
          }
        }
      }
    }
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'simola_weather_channel',
      initialNotificationTitle: 'SiMoLa Aktif',
      initialNotificationContent: 'Memantau keselamatan nelayan di laut...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
  );

  service.startService();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'simola_weather_channel',
    'Peringatan Cuaca Laut',
    description: 'Channel untuk memantau keselamatan nelayan',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_kapal');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      await flutterLocalNotificationsPlugin.cancel(911); // Matikan alarm saat notif diklik
    },
  );

  try {
    await initializeService();
  } catch (e) {
    print("Gagal mengaktifkan Background Service: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiMoLa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Karla', scaffoldBackgroundColor: Colors.white),
      home: const MainWrapper(),
    );
  }
}

// =========================================================
// WIDGET PENGONTROL BOTTOM BAR DENGAN DETEKSI LIFECYCLE
// =========================================================
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  // MENAMBAHKAN WidgetsBindingObserver UNTUK MELACAK APP DIBUKA
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final Color primaryBlue = const Color(0xFF36ADFD);

  final List<Widget> _pages = [
    const SimolaHomeScreen(),
    const PrediksiScreen(),
    const LokasiScreen(),
    const RiwayatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Daftarkan sensor aplikasi
    _matikanAlarmSOS(); // Matikan alarm jaga-jaga kalau app baru di-start
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // FUNGSI INI AKAN JALAN OTOMATIS SAAT APP KEMBALI KE LAYAR UTAMA (FOREGROUND)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _matikanAlarmSOS();
    }
  }

  // FUNGSI MEMBUNUH SUARA ALARM LOOPING
  void _matikanAlarmSOS() async {
    await flutterLocalNotificationsPlugin.cancel(911); // ID Alarm SOS
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: const Color(0xFF797979),
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Prediksi'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Lokasi'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
        ],
      ),
    );
  }
}

class SimolaHomeScreen extends StatelessWidget {
  const SimolaHomeScreen({super.key});

  final Color textDark = const Color(0xFF103249);
  final Color bgLightBlue = const Color(0xFFEAF2FF);
  final Color textGreen = const Color(0xFF0DB331);
  final Color primaryBlue = const Color(0xFF36ADFD);

  String _dapatkanTanggalUI() {
    DateTime now = DateTime.now();
    List<String> namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${namaHari[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _konversiArah(double derajat) {
    if (derajat >= 337.5 || derajat < 22.5) return "Utara";
    if (derajat >= 22.5 && derajat < 67.5) return "Timur Laut";
    if (derajat >= 67.5 && derajat < 112.5) return "Timur";
    if (derajat >= 112.5 && derajat < 157.5) return "Tenggara";
    if (derajat >= 157.5 && derajat < 202.5) return "Selatan";
    if (derajat >= 202.5 && derajat < 247.5) return "Barat Daya";
    if (derajat >= 247.5 && derajat < 292.5) return "Barat";
    if (derajat >= 292.5 && derajat < 337.5) return "Barat Laut";
    return "--";
  }

  List<Widget> _dapatkanRekomendasi(String statusCuaca, bool isSos) {
    if (isSos) {
      return [
        _buildRecommendationCard(title: 'TINDAKAN DARURAT!', subtitle: 'Nelayan menekan tombol SOS darurat. Abaikan kondisi cuaca dan segera lakukan kontak!'),
        _buildRecommendationCard(title: 'Lacak Lokasi', subtitle: 'Buka menu Lokasi dan lihat koordinat terakhir kapal nelayan saat ini juga.'),
        _buildRecommendationCard(title: 'Hubungi Bantuan', subtitle: 'Segera siagakan tim penyelamat atau kapal terdekat ke titik koordinat.'),
      ];
    }

    String s = statusCuaca.toUpperCase();
    if (s == "BAHAYA") {
      return [
        _buildRecommendationCard(title: 'Kondisi Laut Ekstrem', subtitle: 'Kondisi laut sangat ekstrem. Jika waktu kepulangan melampaui batas wajar di tengah badai, segera aktifkan pencarian darurat.'),
        _buildRecommendationCard(title: 'Siagakan Bantuan', subtitle: 'Segera cari bantuan dan rencanakan penyelamatan.'),
        _buildRecommendationCard(title: 'Terus Pantau', subtitle: 'Tetap pantau aplikasi secara berkala.'),
      ];
    } else if (s == "WASPADA") {
      return [
        _buildRecommendationCard(title: 'Cuaca Memburuk', subtitle: 'Cuaca mulai memburuk. Aktif pantau kondisi fisik laut dari pinggir pantai.'),
        _buildRecommendationCard(title: 'Cek Kepulangan', subtitle: 'Tetap pantau waktu kepulangan yang wajar.'),
        _buildRecommendationCard(title: 'Terus Pantau', subtitle: 'Tetap pantau aplikasi secara berkala.'),
      ];
    } else {
      return [
        _buildRecommendationCard(title: 'Kondisi Aman', subtitle: 'Cuaca aman dan dalam keadaan bersahabat.'),
        _buildRecommendationCard(title: 'Cek Kepulangan', subtitle: 'Tetap pantau waktu kepulangan yang wajar.'),
        _buildRecommendationCard(title: 'Terus Pantau', subtitle: 'Tetap pantau aplikasi secara berkala.'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('wavex').doc('latest').snapshots(),
        builder: (context, snapshot) {

          String statusCuacaTxt = "Menunggu...";
          Color statusCuacaWarna = const Color(0xFF797979);

          String statusNelayanTxt = "Menunggu...";
          Color statusNelayanWarna = const Color(0xFF797979);
          bool isSosActive = false;

          String valGelombang = "- m";
          String valArah = "-";
          String valAngin = "- km/h";
          String valSuhu = "- °C";
          String valHujan = "- mm";

          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic> dataTerbaru = snapshot.data!.data() as Map<String, dynamic>;

            if (dataTerbaru.isNotEmpty) {
              // 1. KONDISI CUACA
              statusCuacaTxt = dataTerbaru['SC'] ?? "Aman";
              statusCuacaWarna = (statusCuacaTxt.toUpperCase() == "BAHAYA") ? Colors.red : (statusCuacaTxt.toUpperCase() == "WASPADA" ? Colors.orange : textGreen);

              // 2. KONDISI NELAYAN
              isSosActive = dataTerbaru['SOS'] ?? false;
              if (isSosActive) {
                statusNelayanTxt = "BAHAYA";
                statusNelayanWarna = Colors.red;
              } else {
                statusNelayanTxt = "Aman";
                statusNelayanWarna = textGreen;
              }

              // 3. PARAMETER CUACA
              valGelombang = "${(dataTerbaru['HS']?.toDouble() ?? 0.0).toStringAsFixed(2)} m";
              valArah = _konversiArah((dataTerbaru['DR']?.toDouble() ?? 0.0));
              valAngin = "${(dataTerbaru['WS']?.toDouble() ?? 0.0).toStringAsFixed(1)} km/h";
              valSuhu = "${(dataTerbaru['TM']?.toDouble() ?? 0.0).toStringAsFixed(1)} °C";
              valHujan = "${(dataTerbaru['RN']?.toDouble() ?? 0.0).toStringAsFixed(1)} mm";
            }
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(statusCuacaTxt, statusCuacaWarna),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kondisi Lengkap', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildResponsiveGrid(valGelombang, valArah, valAngin, valSuhu, valHujan),
                      const SizedBox(height: 24),

                      _buildFishermanStatusCard(statusNelayanTxt, statusNelayanWarna),

                      const SizedBox(height: 24),
                      Text('Rekomendasi untuk kamu', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ..._dapatkanRekomendasi(statusCuacaTxt, isSosActive),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(String statusTxt, Color statusWarna) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 191,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SiMoLa', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Georgian')),
              const SizedBox(height: 4),
              Text(_dapatkanTanggalUI(), style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 24),
              _buildGlassStatusCard(statusTxt, statusWarna),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassStatusCard(String statusTxt, Color statusWarna) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xC1EAF2FF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Kondisi Cuaca di Laut', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(height: 1.5, color: Colors.white.withOpacity(0.8)),
              const SizedBox(height: 8),
              Text(statusTxt, style: TextStyle(color: statusWarna, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Lokasi Sistem', style: TextStyle(color: textDark, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(String gel, String arah, String angin, String suhu, String hujan) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth = (constraints.maxWidth - 24.5) / 3;
        return Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.start,
          children: [
            _buildGridBox('Tinggi\nGelombang', gel, itemWidth),
            _buildGridBox('Arah\nGelombang', arah, itemWidth),
            _buildGridBox('Angin', angin, itemWidth),
            _buildGridBox('Suhu', suhu, itemWidth),
            _buildGridBox('Hujan', hujan, itemWidth),
          ],
        );
      },
    );
  }

  Widget _buildGridBox(String title, String value, double width) {
    return Container(
      width: width, height: 102,
      decoration: BoxDecoration(color: bgLightBlue, borderRadius: BorderRadius.circular(11)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: textDark, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFishermanStatusCard(String statusTxt, Color statusWarna) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgLightBlue, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Kondisi Nelayan', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(statusTxt, style: TextStyle(color: statusWarna, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bgLightBlue, borderRadius: BorderRadius.circular(11)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: textDark, fontSize: 11)),
        ],
      ),
    );
  }
}