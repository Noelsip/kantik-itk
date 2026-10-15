import 'package:flutter/material.dart';

/// Menampilkan nomor pesanan sebagai keterangan kecil di bawah nama menu.
///
/// Nomornya tetap terlihat untuk dicocokkan saat mengambil pesanan, tetapi
/// tidak lagi menjadi judul karena pembeli dan penjual lebih mudah
/// mengenali pesanan dari isinya.
class NomorPesanan extends StatelessWidget {
  const NomorPesanan(this.nomor, {super.key});

  final String nomor;

  @override
  Widget build(BuildContext context) {
    return Text(
      'No. $nomor',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: Color(0xFF9A8C87),
        letterSpacing: 0.2,
      ),
    );
  }
}
