# Pengaturan aplikasi

`dart_defines.json` berisi nilai yang disuntikkan saat aplikasi dijalankan.

| Kunci | Isi |
|---|---|
| `GOOGLE_SERVER_CLIENT_ID` | **Opsional di Android.** Client ID **Web** dari Google Cloud Console — nilai yang sama dengan yang dipakai backend untuk memverifikasi idToken. Di Android nilai ini sudah ikut terbawa lewat `android/app/google-services.json`, jadi aplikasi tetap bisa masuk walau dijalankan tanpa berkas ini. Isi hanya bila ingin memakai client lain, atau saat membangun untuk platform selain Android. Client ID **Android** tidak ditulis di sini; Google mencocokkannya lewat nama paket dan sidik jari SHA-1. |
| `API_BASE_URL` | Alamat server API. Ganti ke `http://10.0.2.2:3000` bila menjalankan backend di komputer sendiri lewat emulator Android. |

Menjalankan aplikasi dengan berkas ini:

```
flutter run --dart-define-from-file=config/dart_defines.json
```

Di VS Code, konfigurasi "Kantin ITK" pada Run and Debug sudah memakainya, jadi
cukup tekan F5.

`flutter run` polos juga tetap jalan di Android: masuk dengan Google memakai
client ID dari `google-services.json`, dan alamat API memakai nilai bawaan
`https://api-kantinitk.noelsipayung.me` yang tertulis di `lib/api/api_client.dart`.
Berkas ini diperlukan hanya ketika salah satu nilai itu ingin diganti, misalnya
menunjuk backend di komputer sendiri.

Client ID Web bukan rahasia — nilainya memang tertanam di dalam aplikasi dan
bisa dibaca siapa pun. Yang wajib dirahasiakan adalah *client secret*, dan itu
hanya dipakai di sisi backend.
