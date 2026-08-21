import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

/// Popup "Keterangan Absensi": pilih status (Hadir/Sakit/Izin) + kolom
/// komentar (wajib kalau bukan Hadir) + opsi upload foto bukti
/// (wajib kalau bukan Hadir), dengan tombol Cancel & Confirm.
///
/// CATATAN: parameter `photo` di onConfirm BARU sebatas dikirim ke
/// pemanggil (belum ada logic upload ke server) — menunggu keputusan
/// backend soal penyimpanan foto (lihat diskusi terkait kolom database).
class AbsensiDialog extends StatefulWidget {
  final void Function(String status, String comment, File? photo) onConfirm;

  const AbsensiDialog({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required void Function(String status, String comment, File? photo) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AbsensiDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<AbsensiDialog> createState() => _AbsensiDialogState();
}

class _AbsensiDialogState extends State<AbsensiDialog> {
  final List<String> _options = const [
    'Hadir',
    'Sakit',
    'Izin',
  ];

  String _selected = 'Hadir';
  final TextEditingController _commentController = TextEditingController();
  String? _commentErrorText;
  File? _selectedPhoto;

  /// Comment wajib diisi kalau status BUKAN Hadir.
  bool get _isCommentRequired => _selected != 'Hadir';

  /// Foto wajib diisi kalau status BUKAN Hadir.
  bool get _isPhotoRequired => _selected != 'Hadir';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera, // kamera langsung, cocok untuk "bukti" real-time
      imageQuality: 70, // kompres supaya ukuran file tidak terlalu besar
    );

    if (picked != null) {
      setState(() => _selectedPhoto = File(picked.path));
    }
  }

  void _handleConfirm() {
    final comment = _commentController.text.trim();

    // Validasi: comment wajib diisi kalau bukan Hadir
    if (_isCommentRequired && comment.isEmpty) {
      setState(() {
        _commentErrorText = 'Keterangan wajib diisi untuk $_selected';
      });
      return;
    }

    // Validasi: foto wajib diisi kalau bukan Hadir
    if (_isPhotoRequired && _selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto bukti wajib dilampirkan untuk $_selected')),
      );
      return;
    }

    Navigator.of(context).pop();
    widget.onConfirm(_selected, comment, _selectedPhoto);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Keterangan Absensi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._options.map(
                (option) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option, style: AppTextStyles.label),
                  value: option,
                  groupValue: _selected,
                  activeColor: AppColors.gradientEnd,
                  onChanged: (value) {
                    setState(() {
                      _selected = value!;
                      // Reset pesan error comment tiap ganti pilihan,
                      // supaya tidak nyangkut pesan error lama yang
                      // sudah tidak relevan (misal setelah pindah ke Hadir).
                      _commentErrorText = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isCommentRequired ? 'Comments (wajib diisi) :' : 'Comments (opsional) :',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                onChanged: (_) {
                  // Hilangkan pesan error begitu user mulai mengetik lagi.
                  if (_commentErrorText != null) {
                    setState(() => _commentErrorText = null);
                  }
                },
                decoration: InputDecoration(
                  errorText: _commentErrorText,
                  hintText: _isCommentRequired
                      ? 'Jelaskan alasan $_selected...'
                      : 'Opsional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gradientEnd),
                  ),
                ),
              ),

              // Bagian upload foto HANYA muncul untuk Sakit/Izin.
              if (_isPhotoRequired) ...[
                const SizedBox(height: 16),
                const Text(
                  'Foto Bukti (wajib) :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _selectedPhoto == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Ambil Foto', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedPhoto!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _handleConfirm,
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
