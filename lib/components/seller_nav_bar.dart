import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/app_theme.dart';
import '/pages/pages.dart';
import 'notifikasi_badge.dart';

enum SellerTab { dashboard, pesanan, menu, profil }

/// Menampilkan navigasi bawah penjual lewat `Scaffold.bottomNavigationBar`.
///
/// Menggantikan bar lama yang menjadi anak terakhir `Column` di `body` dan ikut naik
/// ke atas ketika isi di atasnya gagal terbentuk.
class SellerNavBar extends StatelessWidget {
  const SellerNavBar({super.key, required this.current});

  final SellerTab current;

  static const Color _activeBg = Color(0xFFFF7043);
  static const Color _activeFg = Color(0xFF641800);
  static const Color _inactiveFg = Color(0xFF59413A);

  void _go(BuildContext context, SellerTab tab) {
    if (tab == current) return;
    switch (tab) {
      case SellerTab.dashboard:
        context.goNamed(DashboardPage.routeName);
      case SellerTab.pesanan:
        context.goNamed(PesananMasukPage.routeName);
      case SellerTab.menu:
        context.goNamed(KelolaMenuPage.routeName);
      case SellerTab.profil:
        context.goNamed(ProfilPenjualPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menyembunyikan bar selama mengetik karena jendela Android ikut menyusut.
    if (MediaQuery.viewInsetsOf(context).bottom > 0.0) {
      return const SizedBox.shrink();
    }

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
            _item(context, SellerTab.dashboard, Icons.dashboard, 'Dashboard'),
            _item(context, SellerTab.pesanan, Icons.receipt_long, 'Pesanan'),
            _item(context, SellerTab.menu, Icons.restaurant_menu, 'Menu'),
            _item(context, SellerTab.profil, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    SellerTab tab,
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
              padding: const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Notifikasi dibuka dari Profil, jadi lencananya menempel di tab itu.
                  if (tab == SellerTab.profil)
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
