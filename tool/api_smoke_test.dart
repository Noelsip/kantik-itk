// Uji cepat klien API tanpa menjalankan aplikasi:
//   dart run tool/api_smoke_test.dart
//
// Menguji jalur yang bisa dicapai tanpa kunci akses: cek kesehatan server,
// penolakan 401, dan penanganan alamat yang tidak ada.
import 'package:kantin_itk/api/api_client.dart';
import 'package:kantin_itk/api/kantin_api.dart';

Future<void> main() async {
  final client = ApiClient();
  final api = KantinApi(client);
  print('Alamat API: ${client.baseUrl}\n');

  print('1. Cek kesehatan server');
  print('   hidup: ${await api.health()}\n');

  print('2. Endpoint terlindungi tanpa kunci akses');
  try {
    await api.canteens();
    print('   TIDAK DIHARAPKAN: permintaan lolos tanpa kunci');
  } on ApiException catch (e) {
    print('   status         : ${e.statusCode}');
    print('   kode           : ${e.code}');
    print('   belum masuk    : ${e.isUnauthenticated}');
    print('   pesan          : ${e.message}\n');
  }

  print('3. Alamat yang tidak ada');
  try {
    await client.get('/api/tidak-ada');
  } on ApiException catch (e) {
    print('   tidak ditemukan: ${e.isNotFound}');
    print('   pesan          : ${e.message}\n');
  }

  print('4. Server yang tidak bisa dihubungi');
  final offline = ApiClient(baseUrl: 'https://tidak-ada-server.invalid');
  try {
    await offline.get('/api/health');
  } on ApiException catch (e) {
    print('   masalah jaringan: ${e.isNetworkIssue}');
    print('   pesan           : ${e.message}');
  }
  offline.close();
  client.close();
}

// Catatan: untuk memeriksa pengaturan Google, jalankan dengan berkas config:
//   dart run --define-from-file=config/dart_defines.json tool/api_smoke_test.dart
