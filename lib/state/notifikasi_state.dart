import 'package:flutter/widgets.dart';

import '/api/api_client.dart';
import '/services/push_notification_service.dart';
import 'session_state.dart';

/// Menyimpan jumlah notifikasi belum dibaca untuk lencana pada ikon notifikasi.
///
/// Menyegarkan angkanya lewat `GET /api/notifications/unread-count` saat
/// pengguna masuk, saat aplikasi kembali ke latar depan, dan saat pesan
/// dorong tiba selagi aplikasi terbuka.
class NotifikasiState extends ChangeNotifier {
  NotifikasiState(this._session) {
    _lifecycle = AppLifecycleListener(onResume: refresh);
    PushNotificationService.instance.onMessage = (_) => refresh();
  }

  SessionState _session;
  late final AppLifecycleListener _lifecycle;

  /// Menandai pemilik angka saat ini untuk mengenali pergantian akun.
  int? _userId;

  int _unread = 0;

  int get unread => _unread;

  /// Menyelaraskan dengan sesi aktif, memuat ulang hanya saat penggunanya berganti.
  void syncWith(SessionState session) {
    _session = session;
    final id = session.isLoggedIn ? session.user!.id : null;
    if (id == _userId) return;
    _userId = id;
    _unread = 0;
    // Memuat tanpa await karena pemanggilnya build; hasilnya diumumkan lewat notifyListeners.
    if (id != null) refresh();
  }

  /// Memakai angka yang sudah ikut terkirim, misalnya `meta.unreadCount` pada
  /// daftar notifikasi, tanpa permintaan tambahan.
  void setUnread(int count) {
    if (_userId == null || count == _unread) return;
    _unread = count;
    notifyListeners();
  }

  /// Mengambil ulang jumlah notifikasi belum dibaca dari server.
  ///
  /// Kegagalan diabaikan: lencana hanya pelengkap dan angka lama tetap dipakai.
  Future<void> refresh() async {
    final id = _userId;
    if (id == null) return;
    try {
      final count = await _session.api.unreadNotificationCount();
      // Mengabaikan balasan yang datang setelah akun berganti.
      if (id != _userId || count == _unread) return;
      _unread = count;
      notifyListeners();
    } on ApiException {
      // Dibiarkan; percobaan berikutnya datang dari pemicu lain.
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    PushNotificationService.instance.onMessage = null;
    super.dispose();
  }
}
