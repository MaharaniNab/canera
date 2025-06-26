import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class HasilScanPage extends StatefulWidget {
  final String imagePath;
  const HasilScanPage({super.key, required this.imagePath});

  @override
  State<HasilScanPage> createState() => _HasilScanPageState();
}

class _HasilScanPageState extends State<HasilScanPage> {
  late Interpreter _interpreter;
  String _predictionResult = "Menganalisis...";
  double _confidence = 0.0;
  bool _isLoading = true;

  // Daftar label sesuai dengan urutan output model Anda
  final List<String> _labels = ['acne', 'dry', 'normal', 'oily'];

  @override
  void initState() {
    super.initState();
    _loadModelAndPredict();
  }
// Di dalam class _HasilScanPageState

@override
void dispose() {
  // Penting: Selalu lepaskan interpreter saat tidak digunakan untuk membebaskan memori
  _interpreter.close();
  super.dispose();
}

Future<void> _loadModelAndPredict() async {
  try {
    // 1. Muat Model TFLite
    _interpreter = await Interpreter.fromAsset('best_model.tflite');

    // 2. Pra-pemrosesan Gambar
    var inputTensor = _preprocessImage(widget.imagePath);

    // 3. Siapkan Tensor Output
    // --- PERBAIKAN UTAMA DI SINI ---
    // Gunakan 0.0 untuk membuat List<double>, bukan List<int>
    var outputTensor = List.filled(1 * 4, 0.0).reshape([1, 4]);

    // 4. Jalankan Prediksi
    _interpreter.run(inputTensor, outputTensor);

    // 5. Proses Hasil Prediksi
    List<double> output = outputTensor[0]; // Tidak perlu .cast<double>() lagi
    
    double maxConfidence = 0;
    int bestIndex = -1;

    for (int i = 0; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        bestIndex = i;
      }
    }

    // Pastikan bestIndex valid sebelum mengakses _labels
    if (bestIndex != -1) {
      setState(() {
        _predictionResult = _labels[bestIndex];
        _confidence = maxConfidence;
        _isLoading = false;
      });
    } else {
       throw Exception("Tidak dapat menemukan prediksi terbaik.");
    }

  } catch (e) {
    // Ini akan mencetak error yang sebenarnya ke konsol debug Anda
    print("Gagal memuat model atau melakukan prediksi: $e");
    setState(() {
      _predictionResult = "Error: Gagal Memprediksi";
      _isLoading = false;
    });
  }
}
  // Fungsi untuk pra-pemrosesan gambar
  dynamic _preprocessImage(String path) {
    // Baca gambar dari file
    final File imageFile = File(path);
    img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

    if (originalImage == null) {
      throw Exception("Gagal membaca gambar dari path: $path");
    }

    // PENTING: Ukuran input harus sama persis dengan yang diharapkan model Anda
    // Misalnya, model MobileNetV2 biasanya menggunakan 224x224
    int inputSize = 224; 
    img.Image resizedImage = img.copyResize(originalImage, width: inputSize, height: inputSize);

    // Normalisasi gambar. Nilai ini juga tergantung pada saat model dilatih.
    // Umumnya (pixel - 127.5) / 127.5
    var inputBytes = List.generate(1, (index) => 
      List.generate(inputSize, (y) => 
        List.generate(inputSize, (x) {
          var pixel = resizedImage.getPixel(x, y);
          return [(pixel.r - 127.5) / 127.5, (pixel.g - 127.5) / 127.5, (pixel.b - 127.5) / 127.5];
        })
      )
    );

    return inputBytes;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Analisis Kulit Wajah'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Gambar yang Dianalisis:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Tampilkan gambar yang diambil
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        const Text(
                          'Hasil Prediksi:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _predictionResult.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tingkat Kepercayaan: ${(_confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 18),
                        )
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}