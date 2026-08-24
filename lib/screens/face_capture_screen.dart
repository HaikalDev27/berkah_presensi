import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../theme/app_theme.dart';

/// Layar kamera khusus untuk ambil foto wajah sebelum absen dikirim.
/// Selalu pakai kamera depan. Setelah foto diambil dan dikonfirmasi user,
/// layar ini ditutup dan mengembalikan `File` foto lewat Navigator.pop().
///
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

  @override
  void initState() {
    super.initState();
    _setupCamera();
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
      );

      _initializeFuture = _controller!.initialize();
      await _initializeFuture;
      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membuka kamera. Pastikan izin kamera sudah '
            'diaktifkan lewat Pengaturan > Aplikasi > Berkah Presensi > Izin.';
      });
    }
  }

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

  void _fotoUlang() {
    setState(() {
      _capturedPhoto = null;
      _finalPhotoPath = null;
    });
  }

  void _gunakanFoto() {
    if (_finalPhotoPath == null) return;
    Navigator.of(context).pop(File(_finalPhotoPath!));
  }

  @override
  void dispose() {
    _controller?.dispose();
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

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraPreview(),
            // Panduan bingkai wajah oval di tengah layar.
            Center(
              child: Container(
                width: 240,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 3),
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
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Posisikan wajah di dalam bingkai',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _ambilFoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.gradientEnd,
                          width: 4,
                        ),
                      ),
                    ),
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
