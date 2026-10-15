import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/app_toast.dart';
import '/components/async_view.dart';
import '/components/nomor_pesanan.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';
import '/state/session_state.dart';

/// Menampilkan rincian pesanan yang sudah selesai dan menyalin isinya ke keranjang.
class DetailRiwayatPage extends StatefulWidget {
  const DetailRiwayatPage({super.key, this.orderId});

  final String? orderId;

  static String routeName = 'DetailRiwayatPage';
  static String routePath = '/detail-riwayat';

  @override
  State<DetailRiwayatPage> createState() =>
      _DetailRiwayatPageState();
}

class _DetailRiwayatPageState
    extends State<DetailRiwayatPage> {
  bool _memesanUlang = false;

  Future<ApiOrder> _load() async {
    final api = context.read<SessionState>().api;
    final id = int.tryParse(widget.orderId ?? '');
    if (id == null) throw const FormatException('Pesanan tidak dikenal');
    return api.order(id);
  }

  /// Menambahkan kembali seluruh menu pesanan ini ke keranjang.
  Future<void> _pesanLagi(ApiOrder order) async {
    setState(() => _memesanUlang = true);
    final state = context.read<AppState>();
    final navigator = GoRouter.of(context);

    var gagal = 0;
    for (final item in order.items) {
      final ok = await state.addToCart(
        item.menuItemId,
        quantity: item.quantity,
        note: item.note,
      );
      if (!ok) gagal++;
    }
    if (!mounted) return;
    setState(() => _memesanUlang = false);

    if (gagal == order.items.length) {
      showToast(
        state.error ?? 'Menu tidak bisa ditambahkan lagi',
        galat: true,
      );
      return;
    }

    showToast(
      gagal == 0
          ? 'Semua menu ditambahkan ke keranjang'
          : '$gagal menu tidak tersedia lagi dan dilewati',
    );
    navigator.pushNamed(KeranjangPage.routeName);
  }

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
              : context.goNamed(RiwayatPesananPage.routeName),
        ),
        title: Text(
          'Detail Pesanan',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
      ),
      body: SafeArea(
        child: AsyncView<ApiOrder>(
          load: _load,
          builder: (context, order, refresh) => ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            children: [
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFEAE7E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order.judul,
                            style: AppTheme.of(context).titleLarge.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                  color: const Color(0xFF1B1C1C),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(999.0),
                          ),
                          child: Text(
                            order.statusText,
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF59413A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      order.stall,
                      style: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            color: const Color(0xFF59413A),
                            letterSpacing: 0.0,
                          ),
                    ),
                    const SizedBox(height: 2.0),
                    NomorPesanan(order.orderNumber),
                    if ((order.rejectReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10.0),
                      Text(
                        'Alasan penolakan: ${order.rejectReason}',
                        style: AppTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500),
                              color: const Color(0xFFBA1A1A),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                    const Divider(height: 24.0),
                    for (final item in order.items) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.menuName}',
                                  style: AppTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w400),
                                        color: const Color(0xFF1B1C1C),
                                        letterSpacing: 0.0,
                                      ),
                                ),
                                if ((item.note ?? '').isNotEmpty)
                                  Text(
                                    item.note!,
                                    style: AppTheme.of(context)
                                        .bodySmall
                                        .override(
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
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                  color: const Color(0xFF1B1C1C),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                    ],
                    if ((order.note ?? '').isNotEmpty) ...[
                      const Divider(height: 16.0),
                      Text(
                        'Catatan: ${order.note}',
                        style: AppTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400),
                              color: const Color(0xFF59413A),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                    const Divider(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTheme.of(context).bodyLarge.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                                color: const Color(0xFF1B1C1C),
                                letterSpacing: 0.0,
                              ),
                        ),
                        Text(
                          order.totalLabel,
                          style: AppTheme.of(context).titleLarge.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800),
                                color: const Color(0xFFAC3509),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              FilledButton.icon(
                onPressed: _memesanUlang ? null : () => _pesanLagi(order),
                icon: const Icon(Icons.replay),
                label: Text(_memesanUlang ? 'Menambahkan...' : 'Pesan Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAC3509),
                  disabledBackgroundColor: const Color(0xFFD9BFB6),
                  minimumSize: const Size(double.infinity, 50.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
