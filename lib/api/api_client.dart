/// Klien HTTP untuk Kantin ITK API.
///
/// Seluruh respons API dibungkus amplop `{ success, message, data, meta }`
/// untuk keberhasilan dan `{ success: false, message, error }` untuk
/// kegagalan. Kelas ini membuka amplop tersebut dan mengubah kegagalan
/// menjadi [ApiException] yang membawa pesan siap tampil dalam bahasa
/// Indonesia dari server.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime_type/mime_type.dart';

import 'api_models.dart';

/// Alamat dasar API. Bisa ditimpa saat menjalankan aplikasi:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api-kantinitk.noelsipayung.me',
);

/// Kegagalan yang berasal dari API atau dari jaringan.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  /// Pesan siap tampil. Diambil dari `message` milik server bila ada.
  final String message;

  final int? statusCode;

  /// Kode galat mesin, misalnya `UNAUTHENTICATED` atau `NOT_FOUND`.
  final String? code;

  /// Pesan galat per kolom untuk kegagalan validasi.
  final Map<String, String> fieldErrors;

  /// Sesi habis atau belum masuk, pemanggil sebaiknya meminta login ulang.
  bool get isUnauthenticated =>
      statusCode == 401 || code == 'UNAUTHENTICATED';

  bool get isNotFound => statusCode == 404 || code == 'NOT_FOUND';

  /// Gagal menghubungi server, bukan penolakan dari server.
  bool get isNetworkIssue => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Dipanggil ketika server menolak kunci akses, agar sesi dibersihkan.
typedef UnauthorizedHandler = void Function();

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  })  : baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  final Duration timeout;

  String? _accessToken;
  UnauthorizedHandler? onUnauthorized;

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  void setToken(String? token) => _accessToken = token;

  void close() => _http.close();

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (hasToken) 'Authorization': 'Bearer $_accessToken',
      };

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final cleaned = <String, String>{};
    query?.forEach((k, v) {
      if (v == null) return;
      final s = v.toString();
      if (s.isEmpty) return;
      cleaned[k] = s;
    });
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: cleaned.isEmpty ? null : cleaned);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final uri = _uri(path, query);
    final hasBody = body != null;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(_headers(json: hasBody));
      if (hasBody) request.body = jsonEncode(body);

      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      return _unwrap(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Server terlalu lama merespons. Periksa koneksi internetmu lalu '
        'coba lagi.',
      );
    } on SocketException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internetmu.',
      );
    } on http.ClientException {
      throw ApiException(
        'Sambungan ke server terputus. Coba lagi sebentar lagi.',
      );
    } on FormatException {
      throw ApiException('Balasan server tidak dapat dibaca.');
    }
  }

  /// Membuka amplop respons dan melempar [ApiException] bila gagal.
  ///
  /// Mengembalikan `data`, atau seluruh badan respons bila `data` tidak
  /// ada. Ketika ada `meta`, keduanya dikembalikan sebagai satu map agar
  /// pemanggil bisa membaca cacah halaman.
  dynamic _unwrap(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map) decoded = raw.cast<String, dynamic>();
      } on FormatException {
        // Ditangani di bawah lewat pemeriksaan status.
      }
    }

    if (status >= 200 && status < 300 && decoded?['success'] != false) {
      if (decoded == null) return null;
      if (decoded.containsKey('meta') && decoded['meta'] != null) {
        return {'data': decoded['data'], 'meta': decoded['meta']};
      }
      return decoded.containsKey('data') ? decoded['data'] : decoded;
    }

    if (status == 401) onUnauthorized?.call();

    final error = decoded?['error'];
    String? code;
    final fields = <String, String>{};
    if (error is Map) {
      code = error['code'] as String?;
      final issues = error['issues'] ?? error['details'];
      if (issues is List) {
        for (final issue in issues) {
          if (issue is Map) {
            final field = (issue['path'] ?? issue['field'])?.toString();
            final msg = issue['message']?.toString();
            if (field != null && msg != null) fields[field] = msg;
          }
        }
      }
    }

    throw ApiException(
      (decoded?['message'] as String?) ?? _fallbackMessage(status),
      statusCode: status,
      code: code,
      fieldErrors: fields,
    );
  }

  String _fallbackMessage(int status) => switch (status) {
        400 => 'Permintaan tidak valid.',
        401 => 'Anda belum masuk. Silakan masuk terlebih dahulu.',
        403 => 'Anda tidak berhak melakukan tindakan ini.',
        404 => 'Data yang diminta tidak ditemukan.',
        409 => 'Permintaan bertentangan dengan data yang ada.',
        422 => 'Data yang dikirim belum lengkap atau salah.',
        429 => 'Terlalu banyak permintaan. Coba lagi sebentar lagi.',
        >= 500 => 'Server sedang bermasalah. Coba lagi nanti.',
        _ => 'Terjadi kesalahan (kode $status).',
      };

  /// Mengunggah satu berkas sebagai `multipart/form-data`.
  ///
  /// [fieldName] mengikuti nama field yang diminta API, yaitu `file`.
  Future<dynamic> upload(
    String path,
    String filePath, {
    String fieldName = 'file',
  }) async {
    final uri = _uri(path);
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers())
        ..files.add(await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          contentType: _jenisGambar(filePath),
        ));

      final streamed = await _http.send(request).timeout(
            // Unggahan gambar butuh waktu lebih lama daripada permintaan biasa.
            timeout * 3,
          );
      return _unwrap(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Unggahan terlalu lama. Periksa koneksi internetmu lalu coba lagi.',
      );
    } on SocketException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internetmu.',
      );
    } on http.ClientException {
      throw ApiException('Unggahan terputus. Coba lagi sebentar lagi.');
    } on FileSystemException {
      throw ApiException('Berkas gambar tidak dapat dibaca.');
    }
  }

  /// Menebak jenis gambar dari nama berkas untuk dipasang pada unggahan multipart.
  ///
  /// Tanpa jenis ini berkas terkirim sebagai `application/octet-stream` dan ditolak server.
  MediaType _jenisGambar(String filePath) {
    const didukung = {'image/jpeg', 'image/png', 'image/webp', 'image/jpg'};
    final jenis = mime(filePath.toLowerCase());
    if (jenis == null || !didukung.contains(jenis)) {
      throw ApiException(
        'Jenis berkas tidak didukung. Gunakan gambar JPG, PNG, atau WebP.',
      );
    }
    final bagian = jenis.split('/');
    return MediaType(bagian.first, bagian.last);
  }

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body ?? const <String, Object?>{});

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body ?? const <String, Object?>{});

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body ?? const <String, Object?>{});

  Future<dynamic> delete(String path) => _send('DELETE', path);
}

/// Membaca hasil yang mungkin berbentuk `{data, meta}` menjadi [Paged].
Paged<T> pagedFrom<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) parse,
) {
  if (raw is Map && raw.containsKey('data')) {
    final meta = raw['meta'];
    return Paged<T>.fromJson(
      (raw['data'] as List?) ?? const [],
      meta is Map ? meta.cast<String, dynamic>() : null,
      parse,
    );
  }
  return Paged<T>.fromJson((raw as List?) ?? const [], null, parse);
}

/// Mengambil map dari hasil yang mungkin masih terbungkus `{data, meta}`.
Map<String, dynamic> mapFrom(dynamic raw) {
  if (raw is Map && raw.containsKey('data') && raw.containsKey('meta')) {
    return (raw['data'] as Map).cast<String, dynamic>();
  }
  return (raw as Map).cast<String, dynamic>();
}
