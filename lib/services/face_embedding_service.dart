import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// services/face_embedding_service.dart
///
/// Mengubah foto wajah menjadi "face embedding" — vector 192 angka yang
/// merepresentasikan wajah orang tersebut secara unik, dihitung SEPENUHNYA
/// di HP (on-device), tanpa perlu internet.
///
/// Alur:
///   1. Deteksi wajah di foto (google_mlkit_face_detection)
///   2. Crop foto ke area wajah saja (+ sedikit margin)
///   3. Resize ke 112x112 & normalisasi pixel ke rentang -1..1
///   4. Jalankan inference model MobileFaceNet (tflite_flutter)
///   5. Hasil: List<double> berisi 192 angka (embedding)
///
/// Embedding inilah yang dikirim ke server untuk didaftarkan (enrollment)
/// atau dicocokkan (verifikasi) — BUKAN foto mentahnya.
///
/// PENTING — model belum termasuk di project ini:
/// Download file "mobilefacenet.tflite" dari:
///   https://github.com/MCarlomagno/FaceRecognitionAuth/blob/master/assets/mobilefacenet.tflite
/// lalu taruh di: assets/models/mobilefacenet.tflite
/// (folder assets/models/ sudah didaftarkan di pubspec.yaml)
class FaceEmbeddingService {
  FaceEmbeddingService._();
  static final FaceEmbeddingService instance = FaceEmbeddingService._();

  static const int _inputSize = 112; // model butuh gambar 112x112
  static const int _embeddingLength = 192; // panjang vector output model

  Interpreter? _interpreter;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  Future<void> _ensureModelLoaded() async {
    if (_interpreter != null) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
      );
    } catch (e) {
      throw FaceEmbeddingException(
        'Model face recognition belum tersedia. Pastikan file '
        'assets/models/mobilefacenet.tflite sudah didownload dan '
        'ditaruh di folder yang benar (lihat komentar di '
        'face_embedding_service.dart untuk link download).',
      );
    }
  }

  /// Proses [fotoFile] menjadi face embedding (192 angka).
  ///
  /// Melempar [FaceEmbeddingException] kalau:
  /// - tidak ada wajah terdeteksi di foto
  /// - ada lebih dari 1 wajah terdeteksi (ambigu, minta foto ulang)
  /// - model gagal dimuat / gagal inference
  Future<List<double>> extractEmbedding(File fotoFile) async {
    await _ensureModelLoaded();

    // 1. Deteksi wajah di foto pakai ML Kit
    final inputImage = InputImage.fromFile(fotoFile);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      throw FaceEmbeddingException(
        'Wajah tidak terdeteksi di foto. Pastikan wajah terlihat jelas '
        'dan pencahayaan cukup, lalu coba lagi.',
      );
    }

    if (faces.length > 1) {
      throw FaceEmbeddingException(
        'Terdeteksi lebih dari 1 wajah di foto. Pastikan hanya wajah '
        'Anda sendiri yang ada di frame kamera.',
      );
    }

    final face = faces.first;

    // 2. Decode foto asli & crop ke area wajah (+ margin 25% di tiap sisi
    //    supaya tidak terlalu ketat memotong dagu/dahi)
    final bytes = await fotoFile.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) {
      throw FaceEmbeddingException('Gagal membaca file foto.');
    }

    final box = face.boundingBox;
    final marginX = box.width * 0.25;
    final marginY = box.height * 0.25;

    final cropX = math.max(0, (box.left - marginX)).round();
    final cropY = math.max(0, (box.top - marginY)).round();
    final cropRight = math.min(original.width, (box.right + marginX)).round();
    final cropBottom =
        math.min(original.height, (box.bottom + marginY)).round();

    final cropped = img.copyCrop(
      original,
      x: cropX,
      y: cropY,
      width: math.max(1, cropRight - cropX),
      height: math.max(1, cropBottom - cropY),
    );

    // 3. Resize ke 112x112 (ukuran input model)
    final resized = img.copyResize(
      cropped,
      width: _inputSize,
      height: _inputSize,
    );

    // 4. Normalisasi pixel: model butuh nilai float32 di rentang -1..1
    //    Format input: [1, 112, 112, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        }),
      ),
    );

    // 5. Siapkan buffer output: [1, 192]
    final output = List.generate(1, (_) => List.filled(_embeddingLength, 0.0));

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      throw FaceEmbeddingException(
          'Gagal memproses wajah (inference error): $e');
    }

    final embedding = (output[0] as List).cast<double>();
    return embedding;
  }

  /// Panggil saat aplikasi ditutup / tidak butuh lagi, supaya resource
  /// model & face detector dilepas dengan benar.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _faceDetector.close();
  }
}

/// Exception khusus untuk kegagalan proses ekstraksi wajah — pesan di
/// dalamnya sudah ramah ditampilkan langsung ke user lewat StatusDialog.
class FaceEmbeddingException implements Exception {
  final String message;
  const FaceEmbeddingException(this.message);

  @override
  String toString() => message;
}
