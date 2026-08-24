# Model Face Recognition

Folder ini HARUS berisi 1 file: `mobilefacenet.tflite`

Anthropic (Claude) tidak punya akses internet untuk download file binary,
jadi file model ini perlu kamu download sendiri:

## Cara download

1. Buka: https://github.com/MCarlomagno/FaceRecognitionAuth/blob/master/assets/mobilefacenet.tflite
2. Klik tombol "Download raw file" (ikon panah ke bawah)
3. Rename file yang terdownload jadi persis: `mobilefacenet.tflite`
4. Taruh di folder ini: `assets/models/mobilefacenet.tflite`

## Spesifikasi model (untuk referensi, sudah dihandle otomatis oleh
## `lib/services/face_embedding_service.dart`)

- Input: `[1, 112, 112, 3]` — gambar wajah 112x112 piksel RGB,
  dinormalisasi ke rentang -1.0 sampai 1.0
- Output: `[1, 192]` — vector 192 angka (face embedding)
- Ukuran file: sekitar 5 MB

## Cara cek apakah sudah benar

Setelah taruh filenya, jalankan:
```
flutter pub get
flutter run
```
Coba tombol "DAFTARKAN WAJAH" di halaman Profil. Kalau muncul pesan error
"Model face recognition belum tersedia...", berarti file belum ada / salah
nama / salah lokasi — cek lagi 3 hal itu.
