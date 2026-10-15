import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Menggantikan widget yang gagal terbentuk dengan panel berketerangan, bukan kotak kosong bawaan mode rilis.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({super.key, required this.details});

  final FlutterErrorDetails details;

  /// Mengambil baris pertama galat dan memotongnya agar muat di panel.
  String get _summary {
    final text = details.exception.toString().trim();
    if (text.isEmpty) return 'Galat tidak dikenal.';
    final firstLine = text.split('\n').first;
    return firstLine.length > 300
        ? '${firstLine.substring(0, 300)}...'
        : firstLine;
  }

  @override
  Widget build(BuildContext context) {
    // Menyediakan Directionality dan Material sendiri karena bisa terpasang di atas MaterialApp.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFFCF9F8),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFDBD0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 32.0,
                      color: Color(0xFFAC3509),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Bagian ini gagal ditampilkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C1C),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Isi halaman tidak dapat dibentuk. Kembali ke halaman '
                    'sebelumnya lalu buka lagi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.0,
                      height: 1.4,
                      color: Color(0xFF59413A),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EF),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFE0BFB6)),
                    ),
                    child: Text(
                      _summary,
                      style: const TextStyle(
                        fontSize: 11.0,
                        height: 1.5,
                        fontFamily: 'monospace',
                        color: Color(0xFF7A3B1E),
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 10.0),
                    const Text(
                      'Rincian lengkap tercetak di konsol.',
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Color(0xFF9A8C87),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
