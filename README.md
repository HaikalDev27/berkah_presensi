# Berkah Presensi

Aplikasi absensi (presensi) karyawan berbasis Flutter untuk **PT. Berkah Global Business**. Karyawan melakukan check-in/check-out dengan verifikasi biometrik (fingerprint/Face ID), verifikasi wajah, dan lokasi GPS, sementara pendaftaran akun divalidasi terhadap data karyawan yang sudah terdaftar di sistem HR.

## ✨ Fitur Utama

- **Sign Up bertahap** — verifikasi NIK ke tabel karyawan → isi username → buat password, baru akun dibuat.
- **Sign In** dengan username & password, plus opsi **login cepat via fingerprint/Face ID** (binding akun ke device).
- **Lupa password** dengan verifikasi wajah sebagai bukti identitas sebelum reset.
- **Absensi Check-in/Check-out** dengan status Hadir/Izin/Sakit, komentar, dan lampiran foto.
- **Verifikasi biometrik** (fingerprint/Face ID) wajib sebelum mengirim absensi.
- **Verifikasi wajah** (face detection on-device) khusus untuk status **Hadir**, memastikan yang absen benar-benar hadir secara fisik.
- **Lokasi GPS & peta** saat absen, menggunakan `geolocator` dan `flutter_map`.
- **Riwayat absensi** dan batas waktu pengiriman absen.
- **Notifikasi push** via Firebase Cloud Messaging + notifikasi lokal.
- **Pengecekan update aplikasi** otomatis saat dibuka, dengan opsi unduh & pasang APK terbaru.
- Mendukung banyak platform build: Android, iOS, Web, Windows, Linux, macOS.

## 🛠️ Tech Stack

| Kategori | Package |
|---|---|
| Framework | Flutter (Dart SDK `>=3.0.0 <4.0.0`) |
| Jaringan | `http`, `dio` |
| Autentikasi lokal & sesi | `local_auth`, `shared_preferences` |
| Kamera & Wajah | `camera`, `google_mlkit_face_detection`, `tflite_flutter`, `image`, `image_picker` |
| Lokasi & Peta | `geolocator`, `flutter_map`, `latlong2` |
| Notifikasi | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Konfigurasi & util | `flutter_dotenv`, `intl`, `permission_handler`, `path_provider`, `package_info_plus`, `open_filex` |
| Ikon aplikasi | `flutter_launcher_icons` |

Lihat `pubspec.yaml` untuk versi lengkap setiap dependency.

## 📁 Struktur Project (garis besar)

```
lib/
├── config/          # Konfigurasi API (base URL, endpoint) & environment
├── models/          # Model data: UserModel, LoginResponse, Absensi, dll.
├── network/         # ApiClient (wrapper HTTP) & ApiException
├── session/         # SessionManager — penyimpanan token & data user lokal
├── services/        # AuthService, BiometricService, BiometricLoginService,
│                     # NotifikasiService, UpdateService, dll.
├── screens/          # SignInScreen, SignUpScreen, MainNavigation,
│                     # ForgotPasswordScreen, dan halaman lainnya
├── widgets/          # LoadingDialog, StatusDialog, UpdateDialog, dll.
└── theme/            # AppTheme (warna, gradient, style teks)
```

## ✅ Prasyarat

- Flutter SDK (channel stable) dengan Dart `>=3.0.0`
- Android Studio dan/atau Xcode untuk build native
- Backend API (PHP) yang menyediakan endpoint auth, absensi, dan cek NIK karyawan
- Project Firebase (untuk notifikasi push): `google-services.json` (Android) dan/atau `GoogleService-Info.plist` (iOS)
- File `.env` di root project (sudah didaftarkan sebagai asset di `pubspec.yaml`) berisi konfigurasi seperti base URL API

## 🚀 Instalasi & Menjalankan

```bash
# 1. Clone repository
git clone https://github.com/HaikalDev27/berkah_presensi.git
cd berkah_presensi

# 2. Install dependencies
flutter pub get

# 3. Siapkan file .env di root project, contoh isi:
# API_BASE_URL=https://api.contoh.com
# (sesuaikan dengan variabel yang benar-benar dipakai di config/api_config.dart)

# 4. Tempatkan file konfigurasi Firebase:
#    - android/app/google-services.json
#    - ios/Runner/GoogleService-Info.plist

# 5. Jalankan aplikasi
flutter run
```

### Generate Ikon Aplikasi

Setelah mengganti gambar logo di `assets/images/logoapk.png`:

```bash
flutter pub run flutter_launcher_icons
```

## 🔐 Alur Autentikasi Singkat

1. **Sign Up**: NIK dicek ke tabel karyawan (harus terdaftar & berstatus aktif) → isi username → buat & konfirmasi password → akun dibuat.
2. **Sign In**: login dengan username/password, atau lewat fingerprint/Face ID kalau sebelumnya sudah diaktifkan di device tersebut.
3. **Absensi**: sebelum data terkirim ke server, sistem meminta verifikasi fingerprint/Face ID, dan untuk status **Hadir** juga meminta verifikasi wajah.
4. **Lupa Password**: verifikasi wajah digunakan sebagai bukti identitas untuk mendapatkan token reset password sementara.

## 📄 Lisensi

Aplikasi internal untuk **PT. Berkah Global Business**.