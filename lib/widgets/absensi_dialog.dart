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
  final String? batasWaktu;

  const AbsensiDialog({super.key, required this.onConfirm, this.batasWaktu});

  static Future<void> show(
    BuildContext context, {
    required void Function(String status, String comment, File? photo)
        onConfirm,
    String? batasWaktu,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          AbsensiDialog(onConfirm: onConfirm, batasWaktu: batasWaktu),
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

  bool get _lewatBatasWaktu {
    if (widget.batasWaktu == null) return false;
    final now = TimeOfDay.now();
    final parts = widget.batasWaktu!.split(':');
    final batas =
        TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final nowMinutes = now.hour * 60 + now.minute;
    final batasMinutes = batas.hour * 60 + batas.minute;
    return nowMinutes > batasMinutes;
  }

  @override
  void initState() {
    super.initState();
    if (_lewatBatasWaktu) {
      _selected = 'Izin';
    }
  }

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
      source:
          ImageSource.camera, // kamera langsung, cocok untuk "bukti" real-time
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
        SnackBar(
            content: Text('Foto bukti wajib dilampirkan untuk $_selected')),
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
                (option) {
                  final isHadir = option == 'Hadir';
                  final disabled = isHadir && _lewatBatasWaktu;

                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: disabled
                          ? AppTextStyles.label.copyWith(color: Colors.grey)
                          : AppTextStyles.label,
                    ),
                    value: option,
                    groupValue: _selected,
                    activeColor: AppColors.gradientEnd,
                    onChanged: disabled
                        ? null
                        : (value) {
                            setState(() {
                              _selected = value!;
                              _commentErrorText = null;
                            });
                          },
                  );
                },
              ),
              if (_lewatBatasWaktu) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sudah melewati batas waktu absen Hadir (${widget.batasWaktu}). '
                          'Silakan pilih Izin/Sakit.',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Text(
                _isCommentRequired
                    ? 'Comments (wajib diisi) :'
                    : 'Comments (opsional) :',
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
                                Text('Ambil Foto',
                                    style: TextStyle(color: Colors.grey)),
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
