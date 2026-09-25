import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../theme/app_theme.dart';

/// Urutan instruksi liveness (dicek "sisi ke sisi" seperti face verification
/// di aplikasi perbankan) sebelum foto final diambil.
enum _HeadPose { left, right, center }

/// Layar kamera khusus untuk ambil foto wajah sebelum absen dikirim.
/// Selalu pakai kamera depan. User diminta mengikuti instruksi gerakan
/// kepala secara acak (liveness check) sebelum foto diambil otomatis —
/// ini mencegah orang memakai foto/video orang lain untuk absen.
///
/// Setelah foto diambil dan dikonfirmasi user, layar ini ditutup dan
/// mengembalikan `File` foto lewat Navigator.pop().
/// Return `null` kalau user membatalkan (tekan tombol back / silang).
class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _errorMessage;
  XFile? _capturedPhoto;
  String? _finalPhotoPath; // path hasil flip (bisa beda ekstensi dari _capturedPhoto)

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  // ---- State liveness detection ----
  late List<_HeadPose> _challenges; // urutan instruksi, diacak tiap sesi
  int _currentStep = 0;
  int _consecutivePass = 0; // hitung frame berturut-turut yang lolos threshold
  bool _isDetecting = false; // guard: cegah proses frame numpuk
  bool _isCapturing = false; // guard: cegah capture kepanggil dobel
  String? _hintMessage; // pesan status, mis. "Wajah tidak terdeteksi"

  // Threshold sudut (derajat) untuk anggap kepala "sudah nengok".
  static const double _yawThreshold = 15.0;
  static const double _centerTolerance = 10.0;
  // Berapa frame berturut-turut harus lolos sebelum lanjut ke instruksi
  // berikutnya. Ini buat jaga-jaga dari gerakan sekilas/jitter kamera,
  // bukan gerakan yang benar-benar disengaja ikutin instruksi.
  static const int _requiredConsecutiveFrames = 5;

  // PENTING — perlu dites di HP asli: ML Kit mengembalikan
  // `headEulerAngleY` positif/negatif tergantung arah hadap, tapi kamera
  // depan + preview mirror kadang bikin persepsi kiri/kanan user
  // kebalik dari nilai mentahnya. Kalau pas dites instruksi "hadap kiri"
  // malah lolos pas user hadap kanan (atau sebaliknya), tinggal ubah
  // konstanta ini jadi `true`.
  static const bool _invertYaw = false;

  static const Map<DeviceOrientation, int> _orientationToDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _generateChallenges();
    _setupCamera();
  }

  /// Acak urutan sisi (kiri/kanan), instruksi terakhir selalu "hadap
  /// depan" karena frame itu yang paling bagus buat dipakai matching.
  void _generateChallenges() {
    final sides = [_HeadPose.left, _HeadPose.right]..shuffle();
    _challenges = [...sides, _HeadPose.center];
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Kamera tidak ditemukan di device ini.');
        return;
      }

      // Cari kamera depan; fallback ke kamera pertama kalau tidak ada.
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        // Format ini yang langsung dipahami ML Kit tanpa konversi manual
        // YUV420 -> NV21 di sisi Dart (lebih ringan & lebih reliable).
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      _initializeFuture = _controller!.initialize();
      await _initializeFuture;
      if (!mounted) return;
      setState(() {});
      await _controller!.startImageStream(_onFrame);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membuka kamera. Pastikan izin kamera sudah '
            'diaktifkan lewat Pengaturan > Aplikasi > Berkah Presensi > Izin.';
      });
    }
  }

  // ---------------- Liveness: proses tiap frame kamera ----------------

  void _onFrame(CameraImage image) {
    if (_isDetecting || _isCapturing) return;
    _isDetecting = true;
    _detectFace(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _detectFace(CameraImage image) async {
    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted || _isCapturing) return;

      if (faces.isEmpty) {
        _consecutivePass = 0;
        _updateHint('Wajah tidak terdeteksi, posisikan wajah di dalam bingkai');
        return;
      }
      if (faces.length > 1) {
        _consecutivePass = 0;
        _updateHint('Terdeteksi lebih dari 1 wajah');
        return;
      }

      _updateHint(null);
      _evaluateChallenge(faces.first);
    } catch (_) {
      // Abaikan error di 1 frame, biarkan dicoba lagi di frame berikutnya.
    }
  }

  /// Konversi CameraImage (format nv21/bgra8888) jadi InputImage buat ML Kit.
  InputImage? _buildInputImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final deviceOrientation = _controller!.value.deviceOrientation;
      final degrees = _orientationToDegrees[deviceOrientation] ?? 0;
      // Kamera depan: arah rotasi kompensasi ditambah, bukan dikurang,
      // karena sensor kamera depan biasanya "menghadap" berlawanan.
      final rotationCompensation = (sensorOrientation + degrees) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (format != InputImageFormat.nv21 && format != InputImageFormat.bgra8888)) {
      return null; // format tak dikenal, lewati frame ini
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _evaluateChallenge(Face face) {
    final rawYaw = face.headEulerAngleY ?? 0;
    final yaw = _invertYaw ? -rawYaw : rawYaw;
    final challenge = _challenges[_currentStep];

    final bool passed;
    switch (challenge) {
      case _HeadPose.left:
        passed = yaw >= _yawThreshold;
        break;
      case _HeadPose.right:
        passed = yaw <= -_yawThreshold;
        break;
      case _HeadPose.center:
        passed = yaw.abs() <= _centerTolerance;
        break;
    }

    if (passed) {
      _consecutivePass++;
      if (_consecutivePass >= _requiredConsecutiveFrames) {
        _consecutivePass = 0;
        _advanceChallenge();
      }
    } else {
      _consecutivePass = 0;
    }
  }

  void _advanceChallenge() {
    if (_currentStep >= _challenges.length - 1) {
      _captureAfterLiveness();
    } else {
      if (mounted) setState(() => _currentStep++);
    }
  }

  void _updateHint(String? message) {
    if (!mounted) return;
    if (_hintMessage != message) setState(() => _hintMessage = message);
  }

  Future<void> _captureAfterLiveness() async {
    if (_isCapturing || _controller == null) return;
    setState(() => _isCapturing = true);
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _ambilFoto();
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ---------------- Ambil & proses foto akhir ----------------

  Future<void> _ambilFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final photo = await _controller!.takePicture();

      // Kamera depan secara alami menghasilkan gambar "mirror" (efek
      // cermin, kiri-kanan terbalik) — sama seperti yang tampil di
      // preview. Balik horizontal di sini supaya FILE foto yang dipakai
      // untuk enroll/verifikasi wajah sesuai orientasi asli, bukan
      // terbalik.
      final isFrontCamera = _controller!.description.lensDirection ==
          CameraLensDirection.front;

      String finalPath = photo.path;

      if (isFrontCamera) {
        final bytes = await File(photo.path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final flipped = img.flipHorizontal(decoded);

          // PENTING: simpan sebagai PNG, bukan JPEG. Re-encode ke JPEG
          // lewat package `image` bisa menyebabkan pergeseran warna
          // (foto jadi kekuningan/sepia) di beberapa device karena
          // konversi warna YCbCr-nya tidak selalu presisi. PNG bersifat
          // lossless dan tidak melalui proses itu sama sekali, jadi
          // warnanya tetap akurat.
          final pngPath = '${photo.path}_flipped.png';
          await File(pngPath).writeAsBytes(img.encodePng(flipped));
          finalPath = pngPath;
        }
      }

      setState(() {
        _capturedPhoto = photo;
        _finalPhotoPath = finalPath;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil foto, coba lagi.')),
      );
    }
  }

  Future<void> _fotoUlang() async {
    setState(() {
      _capturedPhoto = null;
      _finalPhotoPath = null;
      _currentStep = 0;
      _consecutivePass = 0;
      _hintMessage = null;
      _generateChallenges(); // acak ulang urutan instruksi tiap percobaan
    });
    if (_controller != null && !_controller!.value.isStreamingImages) {
      await _controller!.startImageStream(_onFrame);
    }
  }

  void _gunakanFoto() {
    if (_finalPhotoPath == null) return;
    Navigator.of(context).pop(File(_finalPhotoPath!));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _errorMessage != null
            ? _buildError()
            : _capturedPhoto != null
                ? _buildPreview()
                : _buildCameraView(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography, color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  /// Render preview kamera full-screen TANPA distorsi rasio.
  /// Pakai FittedBox(cover) + SizedBox seukuran resolusi asli sensor,
  /// bukan CameraPreview polos yang dipaksa stretch ke ukuran layar.
  ///
  /// CATATAN: preview TIDAK di-flip di sini. Sebagian besar device
  /// Android sudah menampilkan preview kamera depan tanpa efek mirror
  /// secara native — flip hanya diterapkan ke FILE hasil foto (lihat
  /// _ambilFoto) yang memang butuh dibalik.
  Widget _buildCameraPreview() {
    final previewSize = _controller!.value.previewSize;

    if (previewSize == null) {
      // Fallback kalau previewSize belum tersedia — tetap jaga rasio,
      // meski mungkin ada sedikit area hitam di tepi.
      return Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: CameraPreview(_controller!),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // previewSize dari sensor kamera berorientasi landscape (lebar
          // > tinggi) walau HP dipegang portrait — width & height ditukar
          // di sini supaya preview tampil tegak dengan proporsi yang benar.
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  String _instructionForChallenge(_HeadPose pose) {
    switch (pose) {
      case _HeadPose.left:
        return 'Hadapkan wajah ke kiri';
      case _HeadPose.right:
        return 'Hadapkan wajah ke kanan';
      case _HeadPose.center:
        return 'Hadap lurus ke depan';
    }
  }

  IconData _iconForChallenge(_HeadPose pose) {
    switch (pose) {
      case _HeadPose.left:
        return Icons.arrow_back_rounded;
      case _HeadPose.right:
        return Icons.arrow_forward_rounded;
      case _HeadPose.center:
        return Icons.face_retouching_natural;
    }
  }

  Widget _buildCameraView() {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            _controller == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final currentChallenge = _challenges[_currentStep];
        final framePassing = _consecutivePass > 0;

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraPreview(),
            // Panduan bingkai wajah oval di tengah layar — jadi hijau
            // sekilas saat gerakan mulai terdeteksi sesuai instruksi.
            Center(
              child: Container(
                width: 240,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: framePassing ? AppColors.success : Colors.white70,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(140),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _CircleIconButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(null),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _StepIndicator(
                total: _challenges.length,
                current: _currentStep,
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (_hintMessage == null) ...[
                    Icon(_iconForChallenge(currentChallenge),
                        color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _hintMessage ?? _instructionForChallenge(currentChallenge),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isCapturing)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    const Text(
                      'Verifikasi otomatis — ikuti instruksi di atas',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(_finalPhotoPath ?? _capturedPhoto!.path), fit: BoxFit.cover),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fotoUlang,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Foto Ulang'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _gunakanFoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Gunakan Foto'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int total;
  final int current;

  const _StepIndicator({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.success
                  : active
                      ? Colors.white
                      : Colors.white30,
            ),
          );
        }),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black45,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
