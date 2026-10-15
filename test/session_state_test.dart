// Menguji dua hal yang paling mudah salah dan paling mahal akibatnya:
// kunci akses harus terpasang pada klien yang benar-benar dipakai, dan
// peran akun harus menentukan halaman awal yang tepat.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_itk/api/api_client.dart';
import 'package:kantin_itk/api/api_models.dart';
import 'package:kantin_itk/state/session_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyusun balasan sesuai amplop yang dipakai API.
http.Response _ok(Object data) => http.Response(
      jsonEncode({'success': true, 'message': 'ok', 'data': data}),
      200,
      headers: {'content-type': 'application/json'},
    );

Map<String, Object?> _user({required String role}) => {
      'id': 7,
      'name': 'Noel Ericson',
      'email': 'noel@student.itk.ac.id',
      'role': role,
      'roleLabel': role == 'penjual' ? 'Penjual' : 'Pembeli',
      'nim': '11231072',
      'faculty': 'Fakultas Sains dan Teknologi Informasi',
      'studyProgram': 'Informatika',
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('kunci akses terpasang pada klien yang dipakai untuk permintaan', () async {
    final seenAuthHeaders = <String?>[];

    final mock = MockClient((request) async {
      seenAuthHeaders.add(request.headers['Authorization']);
      if (request.url.path == '/api/auth/google') {
        return _ok({
          'user': _user(role: 'pembeli'),
          'accessToken': 'kunci-rahasia',
          'tokenType': 'Bearer',
        });
      }
      return _ok(_user(role: 'pembeli'));
    });

    final session = SessionState(client: ApiClient(httpClient: mock));
    await session.loginWithGoogle('idToken-palsu');

    // Permintaan berikutnya wajib membawa kunci dari proses masuk tadi.
    await session.api.me();

    expect(seenAuthHeaders.first, isNull, reason: 'masuk belum perlu kunci');
    expect(seenAuthHeaders.last, 'Bearer kunci-rahasia',
        reason: 'permintaan setelah masuk harus membawa kunci');
  });

  test('sesi tersimpan dipulihkan dengan kunci yang benar', () async {
    SharedPreferences.setMockInitialValues({
      'kantin_itk.access_token': 'kunci-tersimpan',
    });

    String? seenAuth;
    final mock = MockClient((request) async {
      seenAuth = request.headers['Authorization'];
      return _ok(_user(role: 'penjual'));
    });

    final session = SessionState(client: ApiClient(httpClient: mock));
    await session.restore();

    expect(seenAuth, 'Bearer kunci-tersimpan');
    expect(session.isLoggedIn, isTrue);
    expect(session.user?.name, 'Noel Ericson');
  });

  test('peran penjual membuka dasbor penjual', () async {
    final mock = MockClient((_) async => _ok({
          'user': _user(role: 'penjual'),
          'accessToken': 'k',
        }));

    final session = SessionState(client: ApiClient(httpClient: mock));
    await session.loginWithGoogle('t');

    expect(session.user?.role, 'penjual');
    expect(session.user?.isSeller, isTrue);
    expect(session.homeRouteName, 'DashboardPage');
  });

  test('peran pembeli membuka beranda mahasiswa', () async {
    final mock = MockClient((_) async => _ok({
          'user': _user(role: 'pembeli'),
          'accessToken': 'k',
        }));

    final session = SessionState(client: ApiClient(httpClient: mock));
    await session.loginWithGoogle('t');

    expect(session.user?.isSeller, isFalse);
    expect(session.homeRouteName, 'BerandaPage');
  });

  test('me() membaca User yang tidak dibungkus kunci "user"', () {
    // /api/auth/me mengembalikan User langsung pada `data`.
    final user = ApiUser.fromJson(_user(role: 'penjual').cast<String, dynamic>());
    expect(user.isSeller, isTrue);
    expect(user.subtitle, 'Fakultas Sains dan Teknologi Informasi - Informatika');
  });

  test('kunci kedaluwarsa membuat sesi dibersihkan', () async {
    SharedPreferences.setMockInitialValues({
      'kantin_itk.access_token': 'kunci-basi',
    });

    final mock = MockClient((_) async => http.Response(
          jsonEncode({
            'success': false,
            'message': 'Anda belum masuk. Silakan masuk terlebih dahulu.',
            'error': {'code': 'UNAUTHENTICATED'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        ));

    final session = SessionState(client: ApiClient(httpClient: mock));
    await session.restore();

    expect(session.isLoggedIn, isFalse);
    expect(session.user, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kantin_itk.access_token'), isNull,
        reason: 'kunci basi harus dibuang');
  });

  test('klien bawaan dipakai bersama, bukan dua objek berbeda', () {
    // Ini bug yang pernah terjadi: `client ?? ApiClient()` ditulis dua kali
    // pada daftar penginisialisasi, sehingga terbentuk dua klien. Kunci
    // akses dipasang di satu klien, permintaan dikirim lewat klien lain,
    // dan pemulihan sesi selalu berakhir 401.
    //
    // Sengaja tanpa menyuntikkan klien, karena hanya jalur bawaan inilah
    // yang memunculkan bug tersebut.
    final session = SessionState();
    expect(identical(session.client, session.api.client), isTrue,
        reason: 'SessionState dan KantinApi harus memakai klien yang sama');

    session.client.setToken('abc');
    expect(session.api.client.hasToken, isTrue,
        reason: 'kunci yang dipasang harus terlihat oleh lapisan endpoint');
  });
}
