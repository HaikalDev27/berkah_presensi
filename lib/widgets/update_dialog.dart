import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

/// widgets/update_dialog.dart
///
/// Panggil showUpdateDialog(context, update, updateService) begitu
/// UpdateService.checkForUpdate() mengembalikan UpdateInfo (bukan null).
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo update,
  UpdateService updateService,
) {
  return showDialog(
    context: context,
    // Kalau is_mandatory true, user tidak bisa menutup dialog ini
    // dengan tap di luar / tombol back — harus update dulu.
    barrierDismissible: !update.isMandatory,
    builder: (context) => AlertDialog(
      title: const Text('Update tersedia'),
      content: Text(
        'Versi ${update.versionName} tersedia.\n\n${update.changelog}',
      ),
      actions: [
        if (!update.isMandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _DownloadProgressDialog(
                apkUrl: update.apkUrl,
                updateService: updateService,
              ),
            );
          },
          child: const Text('Update sekarang'),
        ),
      ],
    ),
  );
}

class _DownloadProgressDialog extends StatefulWidget {
  final String apkUrl;
  final UpdateService updateService;

  const _DownloadProgressDialog({
    required this.apkUrl,
    required this.updateService,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.updateService.downloadAndInstall(
        widget.apkUrl,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      // Installer Android sudah kebuka di sini; tutup dialog progress.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Gagal mengunduh update. Coba lagi nanti.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mengunduh update'),
      content: _error != null
          ? Text(_error!, style: const TextStyle(color: AppColors.textGrey))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 12),
                Text('${(_progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
      actions: [
        if (_error != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
      ],
    );
  }
}
