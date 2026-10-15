/// Menyiapkan notifikasi dorong lewat Firebase Cloud Messaging.
///
/// Tugas kelas ini hanya tiga: meminta izin, mengambil token perangkat,
/// dan meneruskan pesan yang masuk. Pengiriman token ke server sengaja
/// dipisah lewat [onToken] karena endpoint pendaftaran perangkat belum
/// tersedia di API; begitu ada, cukup sambungkan di satu tempat.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Ditangani saat aplikasi sedang tidak berjalan di latar depan.
///
/// Harus berupa fungsi tingkat atas: Flutter menjalankannya pada isolate
/// terpisah yang tidak punya akses ke state aplikasi.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notifikasi latar: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? _messaging;
  String? _token;
  bool _ready = false;

  /// Token perangkat ini, null bila belum siap atau izin ditolak.
  String? get token => _token;

  bool get isReady => _ready;

  /// Dipanggil setiap kali token didapat atau diperbarui oleh Firebase.
  ///
  /// Token bisa berubah sewaktu-waktu, jadi pendaftaran ke server harus
  /// mengikuti panggilan ini, bukan hanya sekali saat aplikasi dibuka.
  void Function(String token)? onToken;

  /// Dipanggil ketika pesan tiba saat aplikasi terbuka.
  void Function(RemoteMessage message)? onMessage;

  /// Dipanggil ketika pengguna menekan notifikasi hingga aplikasi terbuka.
  void Function(RemoteMessage message)? onMessageOpened;

  /// Menyiapkan Firebase dan langganan pesan.
  ///
  /// Kegagalan sengaja tidak dilempar: notifikasi adalah pelengkap, dan
  /// aplikasi harus tetap bisa dipakai walau Firebase bermasalah.
  Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;

      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

      final settings = await messaging.requestPermission();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        debugPrint('Izin notifikasi tidak diberikan.');
        _ready = true;
        return;
      }

      _token = await messaging.getToken();
      if (_token != null) {
        _logToken(_token!);
        onToken?.call(_token!);
      }

      messaging.onTokenRefresh.listen((value) {
        _token = value;
        _logToken(value);
        onToken?.call(value);
      });

      FirebaseMessaging.onMessage.listen((message) {
        onMessage?.call(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onMessageOpened?.call(message);
      });

      // Aplikasi dibuka dari keadaan mati karena notifikasi ditekan.
      final initial = await messaging.getInitialMessage();
      if (initial != null) onMessageOpened?.call(initial);

      _ready = true;
    } catch (e) {
      debugPrint('Notifikasi dorong gagal disiapkan: $e');
      _ready = true;
    }
  }

  /// Mencetak token ke konsol hanya saat mode debug.
  ///
  /// Token dipotong menjadi beberapa baris karena logcat memangkas baris
  /// yang terlalu panjang, padahal token FCM lebih dari 150 karakter dan
  /// harus disalin utuh untuk menguji pengiriman dari server.
  void _logToken(String token) {
    if (kReleaseMode) return;
    debugPrint('--- Token FCM perangkat ini (${token.length} karakter) ---');
    for (var i = 0; i < token.length; i += 100) {
      debugPrint(token.substring(i, i + 100 > token.length ? token.length : i + 100));
    }
    debugPrint('--- akhir token FCM ---');
  }

  /// Melepas token perangkat, dipakai saat pengguna keluar agar
  /// notifikasi tidak lagi terkirim ke perangkat ini.
  Future<void> clearToken() async {
    try {
      await _messaging?.deleteToken();
      _token = null;
    } catch (e) {
      debugPrint('Gagal menghapus token notifikasi: $e');
    }
  }
}
