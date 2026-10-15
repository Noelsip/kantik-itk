import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/cart_line_item.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';

/// Menampilkan isi keranjang per kantin sekaligus jalan menuju checkout.
class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  static String routeName = 'KeranjangPage';
  static String routePath = '/keranjang';

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  @override
  void initState() {
    super.initState();
    // Menyegarkan keranjang saat halaman dibuka agar cocok dengan isi di server.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refreshCart();
    });
  }

  /// Mengosongkan keranjang setelah dikonfirmasi pengguna.
  Future<void> _kosongkan() async {
    final state = context.read<AppState>();
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua menu di keranjang akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (setuju != true) return;
    final ok = await state.clearCart();
    if (ok) return;
    showToast(state.error ?? 'Gagal mengosongkan keranjang', galat: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

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
          'Keranjang',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          if (!state.isCartEmpty)
            IconButton(
              tooltip: 'Kosongkan keranjang',
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Color(0xFFBA1A1A)),
              onPressed: _kosongkan,
            ),
        ],
      ),
      body: SafeArea(
        child: state.isCartEmpty
            ? _kosong(context)
            : RefreshIndicator(
                color: const Color(0xFFAC3509),
                onRefresh: () => state.refreshCart(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                        children: [
                          if (state.cartIsMixed) ...[
                            _catatan(
                              context,
                              'Keranjangmu berisi menu dari '
                              '${state.cartGroups.length} kantin. Checkout akan '
                              'membuat satu pesanan untuk tiap kantin.',
                            ),
                            const SizedBox(height: 12.0),
                          ],
                          if (state.cartHasUnavailable) ...[
                            _catatan(
                              context,
                              'Ada menu yang sedang tidak tersedia. Hapus dulu '
                              'agar pesanan bisa dibuat.',
                              galat: true,
                            ),
                            const SizedBox(height: 12.0),
                          ],
                          for (final grup in state.cartGroups) ...[
                            _judulKantin(context, grup),
                            const SizedBox(height: 10.0),
                            for (final item in grup.items) ...[
                              CartLineItem(item: item),
                              const SizedBox(height: 12.0),
                            ],
                            const SizedBox(height: 8.0),
                          ],
                        ],
                      ),
                    ),
                    _bilahTotal(context, state),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _judulKantin(BuildContext context, ApiCartGroup grup) {
    return Row(
      children: [
        const Icon(Icons.storefront, size: 16.0, color: Color(0xFFAC3509)),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            grup.canteenName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
        ),
        if (!grup.canteenIsOpen)
          const Text(
            'Tutup',
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFFBA1A1A),
            ),
          ),
      ],
    );
  }

  Widget _catatan(BuildContext context, String teks, {bool galat = false}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: galat ? const Color(0xFFFFEBEE) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: galat ? const Color(0xFFE8A0A0) : const Color(0xFFE8C99B),
        ),
      ),
      child: Row(
        children: [
          Icon(
            galat ? Icons.error_outline : Icons.info_outline,
            size: 18.0,
            color: galat ? const Color(0xFFBA1A1A) : const Color(0xFF7A5B1E),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              teks,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    color: galat
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF7A5B1E),
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilahTotal(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F8),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Color(0xFFE5E2E1),
            offset: Offset(0.0, -4.0),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${state.cartCount} item)',
                  style: AppTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  state.totalLabel,
                  style: AppTheme.of(context).titleLarge.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        color: const Color(0xFFAC3509),
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            FilledButton(
              onPressed: state.cartHasUnavailable
                  ? null
                  : () => context.pushNamed(CheckoutPage.routeName),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAC3509),
                disabledBackgroundColor: const Color(0xFFD9BFB6),
                minimumSize: const Size(double.infinity, 52.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Lanjut ke Checkout',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kosong(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.0,
              height: 96.0,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDBD0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 44.0, color: Color(0xFFAC3509)),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Keranjangmu masih kosong',
              style: AppTheme.of(context).titleLarge.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: const Color(0xFF1B1C1C),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Yuk pilih menu favoritmu dari kantin kampus.',
              textAlign: TextAlign.center,
              style: AppTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 24.0),
            FilledButton.icon(
              onPressed: () =>
                  context.goNamed(BerandaPage.routeName),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Jelajahi Menu'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAC3509),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
