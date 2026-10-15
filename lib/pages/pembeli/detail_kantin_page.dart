import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/cart_bar.dart';
import '/components/skeleton.dart';
import '/components/stall_menu_card.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';
import '/state/session_state.dart';

/// Menampilkan profil sebuah kantin beserta seluruh menunya.
///
/// Cukup stateless: data dan status pemuatannya disimpan [AsyncView], dan
/// jumlah keranjang dibaca langsung dari [AppState].
class DetailKantinPage extends StatelessWidget {
  const DetailKantinPage({super.key, this.canteenId});

  final String? canteenId;

  static String routeName = 'DetailKantinPage';
  static String routePath = '/detail-kantin';

  /// Mengambil kantin beserta menunya; endpoint menu sudah menyertakan data kantinnya.
  Future<_DetailKantin> _load(BuildContext context) async {
    final api = context.read<SessionState>().api;
    final id = int.tryParse(canteenId ?? '');
    if (id == null) throw const FormatException('Kantin tidak dikenal');
    // Menu terlaris tampil paling atas agar pembeli langsung melihat andalan kantin.
    final hasil = await api.canteenMenu(id, limit: 100, sortBy: 'popular');
    return _DetailKantin(
      kantin: hasil.canteen ?? await api.canteen(id),
      menus: hasil.items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<AppState>().cartCount;

    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const SafeArea(top: false, child: CartBar()),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.goNamed(DaftarKantinPage.routeName),
        ),
        title: Text(
          'Detail Kantin',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Keranjang',
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFFAC3509)),
                onPressed: () =>
                    context.pushNamed(KeranjangPage.routeName),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6.0,
                  top: 6.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 1.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncView<_DetailKantin>(
          load: () => _load(context),
          builder: (context, data, refresh) => ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
            children: [
              _sampul(context, data.kantin),
              const SizedBox(height: 16.0),
              if (!data.kantin.isOpen) ...[
                _peringatanTutup(context),
                const SizedBox(height: 16.0),
              ],
              Text(
                'Menu (${data.menus.length})',
                style: AppTheme.of(context).titleMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 12.0),
              if (data.menus.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFEAE7E7)),
                  ),
                  child: Text(
                    'Kantin ini belum menambahkan menu.',
                    style: AppTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                          color: const Color(0xFF59413A),
                          letterSpacing: 0.0,
                        ),
                  ),
                )
              else
                for (final item in data.menus) ...[
                  StallMenuCard(
                    item: item,
                    onTap: () => context.pushNamed(
                      DetailMakananPage.routeName,
                      queryParameters: {'menuId': '${item.id}'},
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sampul(BuildContext context, ApiCanteen kantin) {
    final foto = kantin.imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: foto == null || foto.isEmpty
              ? Container(
                  width: double.infinity,
                  height: 180.0,
                  color: const Color(0xFFF0EDED),
                  child: const Icon(Icons.storefront,
                      size: 48.0, color: Color(0xFF9A8C87)),
                )
              : AppNetworkImage(
                  imageUrl: foto,
                  width: double.infinity,
                  height: 180.0,
                ),
        ),
        const SizedBox(height: 14.0),
        Row(
          children: [
            Expanded(
              child: Text(
                kantin.name,
                style: AppTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: kantin.isOpen
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF757575),
                borderRadius: BorderRadius.circular(999.0),
              ),
              child: Text(
                kantin.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        _baris(context, Icons.place_outlined,
            kantin.location ?? 'Lokasi belum diisi'),
        if ((kantin.whatsapp ?? '').isNotEmpty) ...[
          const SizedBox(height: 4.0),
          _baris(context, Icons.chat_outlined, kantin.whatsapp!),
        ],
        if ((kantin.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 10.0),
          Text(
            kantin.description!,
            style: AppTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  color: const Color(0xFF59413A),
                  letterSpacing: 0.0,
                ),
          ),
        ],
      ],
    );
  }

  Widget _baris(BuildContext context, IconData icon, String teks) => Row(
        children: [
          Icon(icon, size: 15.0, color: const Color(0xFF59413A)),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              teks,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ],
      );

  Widget _peringatanTutup(BuildContext context) => Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFE8C99B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18.0, color: Color(0xFF7A5B1E)),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                'Kantin sedang tutup, pesanan baru belum bisa dibuat.',
                style: AppTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: const Color(0xFF7A5B1E),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          ],
        ),
      );
}

/// Menyatukan kantin dan menunya dalam satu hasil muat.
class _DetailKantin {
  const _DetailKantin({required this.kantin, required this.menus});

  final ApiCanteen kantin;
  final List<ApiMenuItem> menus;
}
