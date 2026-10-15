import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/app_theme.dart';
import '/pages/pages.dart';
import 'cart_bar.dart';
import 'notifikasi_badge.dart';

/// Tab yang tersedia pada navigasi bawah sisi mahasiswa.
enum StudentTab { beranda, jelajah, pesanan, profil }

/// Menampilkan navigasi bawah mahasiswa lewat `Scaffold.bottomNavigationBar`.
///
/// Menyembunyikan diri selama papan ketik terbuka karena jendela Android menyusut
/// dan membuat bar ini mengambang di atas papan ketik.
class StudentNavBar extends StatelessWidget {
  const StudentNavBar({super.key, required this.current});

  final StudentTab current;

  static const Color _activeBg = Color(0xFFFF7043);
  static const Color _activeFg = Color(0xFF641800);
  static const Color _inactiveFg = Color(0xFF59413A);

  void _go(BuildContext context, StudentTab tab) {
    if (tab == current) return;
    switch (tab) {
      case StudentTab.beranda:
        context.goNamed(BerandaPage.routeName);
      case StudentTab.jelajah:
        context.goNamed(DaftarKantinPage.routeName);
      case StudentTab.pesanan:
        context.goNamed(RiwayatPesananPage.routeName);
      case StudentTab.profil:
        context.goNamed(ProfilPembeliPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Meniadakan bar selama mengetik supaya tidak melompat ke tengah layar.
    if (MediaQuery.viewInsetsOf(context).bottom > 0.0) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ringkasan keranjang menempel di atas navigasi pada setiap tab.
        const CartBar(),
        _bar(context),
      ],
    );
  }

  Widget _bar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: 80.0,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9F8),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10.0,
              color: Color(0xFFE5E2E1),
              offset: Offset(0.0, -4.0),
            )
          ],
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE0BFB6), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(context, StudentTab.beranda, Icons.home, 'Beranda'),
            _item(context, StudentTab.jelajah, Icons.explore, 'Jelajah'),
            _item(context, StudentTab.pesanan, Icons.receipt_long, 'Pesanan'),
            _item(context, StudentTab.profil, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    StudentTab tab,
    IconData icon,
    String label,
  ) {
    final active = tab == current;
    final fg = active ? _activeFg : _inactiveFg;
    return Expanded(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4.0, 12.0, 4.0, 12.0),
        child: InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => _go(context, tab),
          child: Container(
            decoration: BoxDecoration(
              color: active ? _activeBg : null,
              borderRadius: BorderRadius.circular(12.0),
            ),
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Notifikasi dibuka dari Profil, jadi lencananya menempel di tab itu.
                  if (tab == StudentTab.profil)
                    NotifikasiBadge(child: Icon(icon, color: fg, size: 24.0))
                  else
                    Icon(icon, color: fg, size: 24.0),
                  const SizedBox(height: 4.0),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight:
                                AppTheme.of(context).labelMedium.fontWeight,
                            fontStyle:
                                AppTheme.of(context).labelMedium.fontStyle,
                          ),
                          color: fg,
                          letterSpacing: 0.0,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
