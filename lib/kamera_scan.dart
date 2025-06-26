import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kamera_scan/hasil_scan.dart';

class KameraScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const KameraScanPage({super.key, required this.cameras});

  @override
  State<KameraScanPage> createState() => _KameraScanPageState();
}

class _KameraScanPageState extends State<KameraScanPage> {
  late CameraController _controller;
  late CameraDescription _selectedCamera; // Ubah nama variabel agar lebih jelas
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      print("Tidak ada kamera ditemukan!");
    } else {
      // --- LOGIKA YANG DIPERBAIKI ADA DI SINI ---
      // Cari indeks kamera dengan arah 'front'
      int frontCameraIndex = widget.cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (frontCameraIndex != -1) {
        // Jika kamera depan ditemukan (indeks bukan -1), gunakan kamera itu.
        print("Kamera depan ditemukan, menggunakan kamera depan.");
        _selectedCamera = widget.cameras[frontCameraIndex];
      } else {
        // Jika tidak ada kamera depan, gunakan kamera pertama yang tersedia (biasanya belakang).
        print("Kamera depan tidak ditemukan. Menggunakan kamera pertama yang tersedia.");
        _selectedCamera = widget.cameras.first;
      }
      
      // Lanjutkan inisialisasi dengan kamera yang sudah terpilih
      _initializeCameraController();
    }
  }

  void _initializeCameraController() {
    _controller = CameraController(
      _selectedCamera, // Gunakan kamera yang sudah terpilih
      ResolutionPreset.high,
      enableAudio: false,
      // Penting untuk Android agar gambar tidak terbalik
      imageFormatGroup: ImageFormatGroup.jpeg, 
    );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = true;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        print("Error initializing camera: ${e.code} ${e.description}");
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) {
      return;
    }

    try {
      // Pastikan flash tidak aktif jika tidak diperlukan
      await _controller.setFlashMode(FlashMode.off);
      
      final XFile imageFile = await _controller.takePicture();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HasilScanPage(imagePath: imageFile.path),
        ),
      );
    } on CameraException catch (e) {
      print("Error mengambil gambar: ${e.description}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Menginisialisasi kamera..."),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Wajah Anda'),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            // Gunakan widget AspectRatio agar preview kamera tidak penyok/stretch
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            ),
          ),
          Positioned(
            bottom: 50,
            child: FloatingActionButton(
              onPressed: _takePicture,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}