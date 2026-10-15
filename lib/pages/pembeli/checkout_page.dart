import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/menu_item_card.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';

/// Meringkas isi keranjang lalu mengubahnya menjadi pesanan lewat API.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  static String routeName = 'CheckoutPage';
  static String routePath = '/checkout';

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _noteController = TextEditingController();
  bool _mengirim = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Mengirim keranjang menjadi pesanan lalu berpindah ke halaman keberhasilan.
  Future<void> _pesan() async {
    setState(() => _mengirim = true);
    final state = context.read<AppState>();
    final navigator = GoRouter.of(context);
    final dibuat = await state.placeOrder(note: _noteController.text);
    if (!mounted) return;
    setState(() => _mengirim = false);

    if (dibuat == null || dibuat.isEmpty) {
      showToast(state.error ?? 'Pesanan gagal dibuat', galat: true);
      return;
    }

    navigator.goNamed(
      PesananBerhasilPage.routeName,
      queryParameters: {'orderId': '${dibuat.first.id}'},
    );
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
              : context.goNamed(KeranjangPage.routeName),
        ),
        title: Text(
          'Checkout',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
      ),
      body: SafeArea(
        child: state.isCartEmpty
            ? _kosong(context)
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
                      children: [
                        _infoAmbilSendiri(context),
                        const SizedBox(height: 20.0),
                        if (state.cartIsMixed) ...[
                          Text(
                            'Keranjangmu dipecah menjadi '
                            '${state.cartGroups.length} pesanan, satu untuk '
                            'tiap kantin.',
                            style: AppTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500),
                                  color: const Color(0xFF7A5B1E),
                                  letterSpacing: 0.0,
                                ),
                          ),
                          const SizedBox(height: 14.0),
                        ],
                        for (final grup in state.cartGroups) ...[
                          _kartuKantin(context, grup),
                          const SizedBox(height: 14.0),
                        ],
                        const SizedBox(height: 6.0),
                        Text(
                          'Catatan pesanan',
                          style: AppTheme.of(context).titleMedium.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                                color: const Color(0xFF1B1C1C),
                                letterSpacing: 0.0,
                              ),
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          controller: _noteController,
                          maxLength: 500,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Contoh: tolong pisahkan sambalnya, ambil pukul 12.00',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0BFB6)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0BFB6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _bilahBayar(context, state),
                ],
              ),
      ),
    );
  }

  Widget _infoAmbilSendiri(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EF),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE0BFB6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42.0,
            height: 42.0,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDBD0),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.storefront, color: Color(0xFFAC3509), size: 22.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ambil Sendiri di Kantin',
                  style: AppTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  'Tunjukkan nomor pesanan saat mengambil.',
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuKantin(BuildContext context, ApiCartGroup grup) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEAE7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const Divider(height: 20.0),
          for (final item in grup.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MenuFoto(url: item.imageUrl, size: 44.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}x ${item.menuName}',
                        style: AppTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500),
                              color: const Color(0xFF1B1C1C),
                              letterSpacing: 0.0,
                            ),
                      ),
                      if ((item.note ?? '').isNotEmpty)
                        Text(
                          item.note!,
                          style: AppTheme.of(context).bodySmall.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400),
                                color: const Color(0xFF9A8C87),
                                letterSpacing: 0.0,
                              ),
                        ),
                    ],
                  ),
                ),
                Text(
                  item.subtotalLabel,
                  style: AppTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
          ],
          const Divider(height: 8.0),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal kantin ini',
                style: AppTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: const Color(0xFF59413A),
                      letterSpacing: 0.0,
                    ),
              ),
              Text(
                grup.totalLabel,
                style: AppTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: const Color(0xFFAC3509),
                      letterSpacing: 0.0,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bilahBayar(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 16.0),
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
                  'Total bayar',
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
              onPressed: _mengirim || state.cartHasUnavailable ? null : _pesan,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAC3509),
                disabledBackgroundColor: const Color(0xFFD9BFB6),
                minimumSize: const Size(double.infinity, 52.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                _mengirim ? 'Mengirim pesanan...' : 'Buat Pesanan',
                style: const TextStyle(
                    fontSize: 15.0, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kosong(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 44.0, color: Color(0xFFAC3509)),
              const SizedBox(height: 16.0),
              Text(
                'Tidak ada yang bisa dipesan',
                style: AppTheme.of(context).titleMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 20.0),
              FilledButton(
                onPressed: () =>
                    context.goNamed(BerandaPage.routeName),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAC3509),
                ),
                child: const Text('Cari Menu'),
              ),
            ],
          ),
        ),
      );
}
