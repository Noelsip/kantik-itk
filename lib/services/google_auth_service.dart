/// Mengambil `idToken` dari akun Google pengguna.
///
/// API Kantin ITK menerima idToken tersebut pada `POST /api/auth/google`
/// dan menukarnya dengan kunci akses miliknya sendiri.
///
/// Dua nilai wajib disiapkan di Google Cloud Console sebelum ini bekerja:
///
/// 1. **Client ID Android** — mengikat aplikasi ke proyek Google. Tidak
///    dipakai di kode; cukup didaftarkan dengan nama paket dan sidik jari
///    SHA-1 aplikasi.
/// 2. **Client ID Web** — inilah yang dipakai sebagai [serverClientId],
///    dan harus sama dengan yang diverifikasi server.
///
/// Tanpa `serverClientId`, Google memang tetap mengembalikan akun tetapi
/// tanpa idToken, sehingga API akan menolak permintaan masuk.
///
/// Di Android nilainya tidak perlu diketik sendiri. `android/app/`
/// `google-services.json` sudah memuat client Web (`client_type` 3), dan
/// plugin `com.google.gms.google-services` mengubahnya menjadi sumber
/// daya `default_web_client_id`. google_sign_in membaca sumber daya itu
/// sendiri, tetapi hanya ketika `serverClientId` yang dikirim bernilai
/// null — string kosong tetap dianggap nilai yang dipilih pemakai dan
/// membuat pencarian itu dilewati.
library;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Client ID Web pengganti, bila ingin memakai client selain yang ada di
/// `google-services.json`.
///
/// Biasanya dibiarkan kosong. Untuk menimpanya:
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);

/// Hasil percobaan masuk lewat Google.
sealed class GoogleAuthResult {
  const GoogleAuthResult();
}

/// Berhasil memperoleh idToken, siap ditukar ke API.
class GoogleAuthSuccess extends GoogleAuthResult {
  const GoogleAuthSuccess(this.idToken, {this.email, this.displayName});

  final String idToken;
  final String? email;
  final String? displayName;
}

/// Pengguna menutup pemilih akun.
class GoogleAuthCancelled extends GoogleAuthResult {
  const GoogleAuthCancelled();
}

/// Gagal, dengan pesan yang bisa langsung ditampilkan.
class GoogleAuthFailure extends GoogleAuthResult {
  const GoogleAuthFailure(this.message);

  final String message;
}

class GoogleAuthService {
  GoogleAuthService({String? serverClientId})
      : serverClientId = _orNull(serverClientId ?? kGoogleServerClientId);

  /// Client ID Web yang dipasang manual, atau null bila memakai nilai
  /// bawaan yang ikut terbawa aplikasi.
  final String? serverClientId;

  bool _initialized = false;

  /// Mengubah nilai kosong menjadi null.
  ///
  /// Pembedaan ini yang menentukan: null berarti "pakai bawaan dari
  /// `google-services.json`", sedangkan string kosong berarti "pakai
  /// client ID kosong" dan selalu berujung gagal masuk.
  static String? _orNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Aplikasi sudah membawa client ID-nya sendiri.
  ///
  /// Android mengambilnya dari `google-services.json` yang ikut dibundel,
  /// jadi hanya platform lain yang masih menuntut nilai lewat
  /// `--dart-define`.
  bool get isConfigured =>
      serverClientId != null ||
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // null dikirim apa adanya: itulah isyarat bagi google_sign_in untuk
    // mengambil client ID dari google-services.json.
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  /// Menampilkan pemilih akun Google lalu mengembalikan idToken-nya.
  Future<GoogleAuthResult> signIn() async {
    if (!isConfigured) {
      return const GoogleAuthFailure(
        'Client ID Google belum tersedia di platform ini. Jalankan '
        'aplikasi dengan --dart-define=GOOGLE_SERVER_CLIENT_ID=<client '
        'id web>.',
      );
    }

    try {
      await _ensureInitialized();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return const GoogleAuthFailure(
          'Masuk dengan Google tidak didukung di perangkat ini.',
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        // Google memilih akun tanpa menyertakan idToken. Penyebabnya hampir
        // selalu pengaturan, bukan kode: Client ID Web salah, atau sidik
        // jari SHA-1 build ini belum terdaftar pada Client ID Android.
        return const GoogleAuthFailure(
          'Google tidak memberikan idToken. Periksa Client ID Web, dan '
          'pastikan SHA-1 build ini sudah terdaftar pada Client ID Android.',
        );
      }

      return GoogleAuthSuccess(
        idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleAuthCancelled();
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        return const GoogleAuthFailure(
          'Pengaturan Google belum benar. Periksa nama paket '
          '(ac.id.itk.kantinitk), sidik jari SHA-1, dan keberadaan client '
          'Web pada android/app/google-services.json.',
        );
      }
      return GoogleAuthFailure(
        e.description ?? 'Masuk dengan Google gagal (${e.code.name}).',
      );
    } catch (e) {
      return GoogleAuthFailure('Masuk dengan Google gagal: $e');
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Sesi lokal tetap dibersihkan oleh pemanggil.
    }
  }
}
