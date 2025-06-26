import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kamera_scan/kamera_scan.dart';

// Variabel global untuk menampung daftar kamera
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Pastikan semua plugin terinisialisasi sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();

  // Dapatkan daftar kamera yang tersedia di perangkat
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan Kondisi Wajah',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: Scan(cameras: cameras),
      home: const ScanPage(),);
  }
}