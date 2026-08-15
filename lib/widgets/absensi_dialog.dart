import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Popup "Keterangan Absensi": pilih status (Sakit/Izin/Tanpa Keterangan/
/// Cuti/Hadir) + kolom komentar, dengan tombol Cancel & Confirm.
class AbsensiDialog extends StatefulWidget {
  final void Function(String status, String comment) onConfirm;

  const AbsensiDialog({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required void Function(String status, String comment) onConfirm,
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
    'Sakit',
    'Izin',
    'Hadir',
  ];

  String _selected = 'Hadir';
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                onChanged: (value) => setState(() => _selected = value!),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comments :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConfirm(_selected, _commentController.text);
                    },
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
    );
  }
}
