import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '/components/notifikasi_list.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';

/// Menampilkan notifikasi mahasiswa dan membuka pesanan yang dirujuknya.
class NotifikasiPembeliPage extends StatefulWidget {
  const NotifikasiPembeliPage({super.key});

  static String routeName = 'NotifikasiPembeliPage';
  static String routePath = '/notifikasi';

  @override
  State<NotifikasiPembeliPage> createState() =>
      _NotifikasiPembeliPageState();
}

class _NotifikasiPembeliPageState extends State<NotifikasiPembeliPage> {
  final _listKey = GlobalKey<NotifikasiListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.goNamed(BerandaPage.routeName),
        ),
        title: Text(
          'Notifikasi',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => _listKey.currentState?.tandaiSemuaTerbaca(),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFAC3509)),
            child: const Text('Tandai Dibaca'),
          ),
        ],
      ),
      body: SafeArea(
        child: NotifikasiList(
          key: _listKey,
          onTapOrder: (orderId) => context.pushNamed(
            StatusPesananPage.routeName,
            queryParameters: {'orderId': '$orderId'},
          ),
        ),
      ),
    );
  }
}
