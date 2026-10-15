import 'package:flutter/material.dart';

import '/api/api_client.dart';
import 'skeleton.dart';

/// Memuat data API sambil menyediakan kerangka pemuatan, pesan galat, coba lagi, dan tarik-segarkan.
///
/// Menyatukan ketiga keadaan itu agar tidak ditulis ulang di tiap halaman dan tidak ada
/// halaman yang berakhir kosong tanpa keterangan.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.loading,
    this.onRetryFailed,
    this.pullToRefresh = true,
  });

  /// Mengambil data; dipanggil ulang saat coba lagi atau tarik-segarkan.
  final Future<T> Function() load;

  /// Membentuk tampilan setelah data tiba, sekaligus menyerahkan penyegar ke halaman.
  final Widget Function(BuildContext context, T data, Future<void> Function() refresh)
      builder;

  /// Menampilkan kerangka selama pemuatan pertama; memakai kerangka daftar bila null.
  final Widget? loading;

  /// Memberi tahu halaman bahwa pemuatan pertama gagal, misalnya untuk menutup halaman.
  final VoidCallback? onRetryFailed;

  final bool pullToRefresh;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;

  /// Menandai pemuatan pernah berhasil, karena data bernilai null pun sah.
  bool _termuat = false;

  ApiException? _apiError;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = !_termuat);
    try {
      final result = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = result;
        _termuat = true;
        _apiError = null;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = e;
        _error = e.message;
        _loading = false;
      });
      if (!_termuat) widget.onRetryFailed?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = null;
        _error = 'Terjadi kesalahan tak terduga: $e';
        _loading = false;
      });
    }
  }

  /// Memuat ulang dari luar setelah halaman menyimpan perubahan.
  Future<void> reload() => _load();

  @override
  Widget build(BuildContext context) {
    if (!_termuat && _loading) {
      return widget.loading ?? const SkeletonList(count: 4);
    }

    if (!_termuat) {
      final galat = _apiError;
      // Tanpa ApiException berarti kegagalan datang dari aplikasi sendiri, bukan dari jaringan.
      final dariAplikasi = galat == null;
      final jaringan = galat != null && galat.isNetworkIssue;
      return NetworkErrorView(
        title: dariAplikasi
            ? 'Aplikasi Bermasalah'
            : jaringan
                ? 'Koneksi Bermasalah'
                : 'Permintaan Ditolak Server',
        icon: dariAplikasi
            ? Icons.bug_report_outlined
            : jaringan
                ? Icons.wifi_off
                : Icons.report_gmailerrorred,
        message: _error ?? 'Data gagal dimuat.',
        detail: galat == null || jaringan
            ? null
            : 'HTTP ${galat.statusCode}${galat.code == null ? '' : ' - ${galat.code}'}',
        onRetry: _load,
      );
    }

    final content = widget.builder(context, _data as T, _load);
    if (!widget.pullToRefresh) return content;

    return RefreshIndicator(
      color: const Color(0xFFAC3509),
      onRefresh: _load,
      child: content,
    );
  }
}
