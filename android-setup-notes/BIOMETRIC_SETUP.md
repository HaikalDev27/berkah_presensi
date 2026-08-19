# Setup Native Android untuk local_auth (Fingerprint / Face ID)

File-file ini BELUM ada di project karena project belum pernah dijalankan
`flutter create .`. Setelah kamu jalankan itu (atau `flutter run` pertama
kali sehingga folder android/ ter-generate), lakukan 2 perubahan berikut.

## 1. android/app/src/main/AndroidManifest.xml

Tambahkan baris permission ini di dalam tag <manifest> (sejajar dengan
tag <application>, sebelum atau sesudahnya):

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

Contoh potongan lengkap:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />

    <application
        android:label="berkah_presensi"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

## 2. android/app/src/main/kotlin/.../MainActivity.kt

`local_auth` butuh Activity yang berbasis `FlutterFragmentActivity`
(bukan `FlutterActivity` default). Ubah isi file MainActivity.kt jadi:

```kotlin
package com.example.berkah_presensi   // sesuaikan dengan package aplikasimu

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

## 3. android/app/build.gradle

Pastikan minSdkVersion minimal 23 (biometric API butuh API level 23+):

```gradle
android {
    defaultConfig {
        minSdkVersion 23   // atau lebih tinggi
        ...
    }
}
```

Kalau memakai `flutter.minSdkVersion` bawaan template biasanya sudah 21 —
naikkan manual jadi minimal 23.

---

Setelah 3 hal di atas selesai, jalankan `flutter pub get` lalu `flutter run`
— fingerprint/Face ID siap dipakai lewat `lib/services/biometric_service.dart`.
