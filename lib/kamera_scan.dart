import 'dart:io';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kamera_scan/hasil_scan.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_v2/tflite_v2.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first);

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: "assets/best_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;

    final directory = await getTemporaryDirectory();
    final imagePath = "${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final XFile file = await _controller!.takePicture();
    final File imgFile = File(imagePath);
    await file.saveTo(imgFile.path);

    final recognition = await Tflite.runModelOnImage(
      path: imgFile.path,
      numResults: 1,
      threshold: 0.5,
    );

    if (!mounted) return;

    if (recognition != null && recognition.isNotEmpty) {
      final label = recognition[0]['label'];
      final confidence = recognition[0]['confidence'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HasilScanPage(
            imagePath: imgFile.path,
            label: label,
            confidence: confidence,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deteksi gagal. Coba lagi.")),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text("Scan"),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _takePicture,
            child: const Text("Ambil Gambar & Deteksi"),
          ),
        ],
      ),
    );
  }
}
