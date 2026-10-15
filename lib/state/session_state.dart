/// Menyimpan sesi masuk: kunci akses dan identitas pengguna.
///
/// Kunci akses disimpan di `shared_preferences` agar pengguna tidak perlu
/// masuk ulang setiap membuka aplikasi. Kunci dianggap tidak berlaku lagi
/// begitu server membalas 401, dan sesi langsung dibersihkan.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/api/kantin_api.dart';
import '/services/push_notification_service.dart';

const String _kTokenKey = 'kantin_itk.access_token';

enum SessionStatus {
  /// Belum diketahui, kunci tersimpan sedang diperiksa.
  memeriksa,

  /// Tidak ada sesi, pengguna perlu masuk.
  keluar,

  /// Sesi aktif.
  masuk,
}

class SessionState extends ChangeNotifier {
  /// Dibuat lewat konstruktor pribadi agar [client] dan [_api] dijamin
  /// memakai satu objek yang sama.
  ///
  /// Sebelumnya `client ?? ApiClient()` ditulis dua kali pada daftar
  /// penginisialisasi, sehingga terbentuk dua klien berbeda: kunci akses
  /// dipasang pada yang satu, tetapi permintaan dikirim lewat yang lain.
  factory SessionState({ApiClient? client}) =>
      SessionState._(client ?? ApiClient());

  SessionState._(ApiClient client)
      : client = client,
        _api = KantinApi(client) {
    // Satu titik penanganan ketika server menolak kunci akses.
    client.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient client;
  final KantinApi _api;

  KantinApi get api => _api;

  SessionStatus _status = SessionStatus.memeriksa;
  ApiUser? _user;
  String? _token;
  String? _error;
  bool _busy = false;
  bool _restoring = false;

  SessionStatus get status => _status;
  ApiUser? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  /// Menyatakan sesi aktif sekaligus identitas penggunanya sudah diketahui.
  ///
  /// Memeriksa keduanya karena status masuk tanpa identitas membuat penjual
  /// diarahkan ke tampilan mahasiswa.
  bool get isLoggedIn => _status == SessionStatus.masuk && _user != null;

  /// Menandai pemulihan sesi berhenti karena galat, bukan karena masih berjalan.
  ///
  /// Menjadi isyarat bagi layar pembuka untuk menawarkan percobaan ulang.
  bool get restoreFailed =>
      _status == SessionStatus.memeriksa && _error != null && !_restoring;

  /// Memberi tahu navigasi bahwa sesi gugur di tengah pemakaian, misalnya kunci akses ditolak.
  void Function()? onSessionExpired;

  /// Membaca kunci akses tersimpan lalu memastikannya masih berlaku.
  ///
  /// Dipanggil saat aplikasi dijalankan, dan boleh dipanggil lagi untuk
  /// mencoba ulang. Bila kunci sudah kedaluwarsa server akan membalas 401
  /// dan sesi otomatis dibersihkan.
  ///
  /// Gangguan jaringan tidak mengeluarkan pengguna, tetapi juga tidak
  /// meloloskannya masuk: status bertahan di [SessionStatus.memeriksa]
  /// dengan [error] terisi. Tanpa balasan `me()` peran akun belum
  /// diketahui, dan menebaknya membuat penjual mendarat di tampilan
  /// mahasiswa. Layar pembuka yang menampilkan galatnya beserta tombol
  /// coba lagi.
  Future<void> restore() async {
    // Tombol coba lagi bisa ditekan berkali-kali; hanya satu pemulihan
    // yang boleh berjalan, kalau tidak balasan yang datang belakangan
    // menimpa hasil yang lebih baru.
    if (_restoring) return;
    _restoring = true;
    _status = SessionStatus.memeriksa;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kTokenKey);
      if (saved == null || saved.isEmpty) {
        _setLoggedOut();
        return;
      }

      _token = saved;
      client.setToken(saved);
      _setUser(await _api.me());
      _status = SessionStatus.masuk;
      _error = null;
      _bindPushToken();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await _clearToken();
        _setLoggedOut();
        return;
      }
      _error = e.message;
      notifyListeners();
    } catch (e) {
      // Penyimpanan lokal dan penguraian balasan bisa gagal dengan galat
      // di luar ApiException. Tanpa penangkap ini status tidak pernah
      // beranjak dari `memeriksa`, dan aplikasi berhenti di layar
      // pembuka tanpa pesan apa pun.
      debugPrint('Pemulihan sesi gagal: $e');
      _error = 'Sesi gagal disiapkan. Coba lagi.';
      notifyListeners();
    } finally {
      _restoring = false;
    }
  }

  /// Menukar idToken Google dengan kunci akses API lalu menyimpannya.
  Future<bool> loginWithGoogle(String idToken) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _api.loginWithGoogle(idToken);
      _token = session.accessToken;
      _setUser(session.user);
      client.setToken(_token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, session.accessToken);
      _status = SessionStatus.masuk;
      _bindPushToken();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _busy = true;
    notifyListeners();

    // Lepas perangkat lebih dulu, selagi kunci akses masih berlaku.
    final push = PushNotificationService.instance;
    push.onToken = null;
    final deviceToken = push.token;
    if (deviceToken != null) {
      try {
        await _api.unregisterDevice(deviceToken);
      } on ApiException {
        // Gagal melepas tidak boleh menghalangi pengguna keluar.
      }
    }

    try {
      await _api.logout();
    } on ApiException {
      // Kunci tetap dibuang meski server tidak bisa dihubungi.
    }
    await _clearToken();
    _busy = false;
    _setLoggedOut();
  }

  /// Memperbarui profil.
  ///
  /// Hanya kolom yang disertakan yang dikirim, karena API menolak badan
  /// permintaan kosong. Untuk mengosongkan nomor WhatsApp, kirim
  /// [clearWhatsapp] bernilai true.
  Future<bool> updateProfile({
    String? name,
    String? profileImage,
    String? whatsapp,
    bool clearWhatsapp = false,
  }) async {
    final changes = <String, Object?>{
      if (name != null) 'name': name,
      if (profileImage != null) 'profileImage': profileImage,
      if (clearWhatsapp) 'whatsapp': null
      else if (whatsapp != null) 'whatsapp': whatsapp,
    };
    if (changes.isEmpty) return true;

    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _setUser(await _api.updateProfile(changes));
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Mengambil ulang identitas pengguna dari server tanpa menyentuh status sesi.
  Future<bool> refreshUser() async {
    try {
      _setUser(await _api.me());
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Mengirim seluruh isi formulir profil sekaligus lewat PUT.
  Future<bool> replaceProfile(Map<String, Object?> profile) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _setUser(await _api.replaceProfile(profile));
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Mengunggah berkas gambar sebagai foto profil dan langsung memakai
  /// hasilnya. Server yang menyimpan berkas dan memasangnya, jadi tidak
  /// perlu mengurus alamat gambar secara manual.
  Future<bool> uploadProfilePhoto(String filePath) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _setUser(await _api.uploadProfilePhoto(filePath));
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Menyambungkan token perangkat ke server.
  ///
  /// Dipasang sebagai callback, bukan dipanggil sekali, karena Firebase
  /// bisa memperbarui token sewaktu-waktu. Token yang sudah ada saat ini
  /// langsung didaftarkan agar tidak menunggu pembaruan berikutnya.
  void _bindPushToken() {
    final push = PushNotificationService.instance;
    push.onToken = (token) {
      // Kegagalan pendaftaran tidak boleh mengganggu pemakaian aplikasi;
      // token akan dicoba lagi saat Firebase memperbaruinya.
      _api.registerDevice(token).catchError((_) {});
    };
    final current = push.token;
    if (current != null) _api.registerDevice(current).catchError((_) {});
  }

  /// Menyimpan pengguna yang baru diterima dari server lewat satu pintu.
  ///
  /// Melewatkan semua jalur yang mengembalikan [ApiUser] ke sini agar peran dan
  /// identitas tidak pernah setengah diperbarui.
  void _setUser(ApiUser user) => _user = user;

  /// Nama rute beranda sesuai peran akun.
  ///
  /// Akun `penjual` masuk ke dasbor penjual, selain itu ke beranda
  /// mahasiswa. Ditaruh di sini agar hanya ada satu sumber kebenaran;
  /// sebelumnya setiap halaman menebak sendiri dan penjual selalu
  /// terlempar ke tampilan pembeli.
  /// Tanpa identitas pengguna perannya tidak bisa ditebak: yang
  /// dikembalikan halaman masuk, bukan beranda mahasiswa.
  String get homeRouteName {
    final user = _user;
    if (user == null) return 'LoginPage';
    return user.isSeller ? 'DashboardPage' : 'BerandaPage';
  }

  void _handleUnauthorized() {
    // Dipanggil dari dalam penanganan respons, jadi pembersihan ditunda
    // agar tidak mengubah state di tengah pembacaan.
    Future.microtask(() async {
      if (_status == SessionStatus.keluar) return;
      await _clearToken();
      _error = 'Sesi berakhir. Silakan masuk lagi.';
      _setLoggedOut();
      // Membersihkan sesi saja membuat pengguna tertinggal di halaman
      // yang datanya tidak bisa lagi diambil, jadi navigasi ikut diberi
      // tahu supaya kembali ke halaman masuk.
      onSessionExpired?.call();
    });
  }

  Future<void> _clearToken() async {
    _token = null;
    client.setToken(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
    } catch (e) {
      // Kunci sudah dilepas dari klien, jadi sesi tetap berakhir walau
      // penyimpanan lokal bermasalah. Sisa kunci di penyimpanan akan
      // ditolak server dan dibersihkan lagi pada percobaan berikutnya.
      debugPrint('Kunci akses gagal dihapus: $e');
    }
  }

  void _setLoggedOut() {
    _user = null;
    _status = SessionStatus.keluar;
    notifyListeners();
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}
