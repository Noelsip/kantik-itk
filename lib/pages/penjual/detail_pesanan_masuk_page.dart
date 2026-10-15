import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/nomor_pesanan.dart';
import '/core/app_theme.dart';
import '/components/seller_order_actions.dart';
import '/pages/pages.dart';
import '/state/session_state.dart';

/// Menampilkan rincian satu pesanan masuk beserta tombol pemrosesannya.
class DetailPesananMasukPage extends StatefulWidget {
  const DetailPesananMasukPage({super.key, this.orderId});

  final String? orderId;

  static String routeName = 'DetailPesananMasukPage';
  static String routePath = '/detail-pesanan-masuk';

  @override
  State<DetailPesananMasukPage> createState() =>
      _DetailPesananMasukPageState();
}

class _DetailPesananMasukPageState
    extends State<DetailPesananMasukPage> {
  final _viewKey = GlobalKey<AsyncViewState<ApiOrder>>();
  bool _sibuk = false;

  Future<ApiOrder> _load() async {
    final api = context.read<SessionState>().api;
    final id = int.tryParse(widget.orderId ?? '');
    if (id == null) throw const FormatException('Pesanan tidak dikenal');
    return api.sellerOrder(id);
  }

  Future<void> _jalankan(ApiOrder order, SellerOrderAction aksi) async {
    setState(() => _sibuk = true);
    final berhasil = await jalankanAksiPesanan(context, order, aksi);
    if (!mounted) return;
    setState(() => _sibuk = false);
    if (berhasil) await _viewKey.currentState?.reload();
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
              : context.goNamed(PesananMasukPage.routeName),
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
          key: _viewKey,
          load: _load,
          builder: (context, order, refresh) {
            final aksi = aksiBerikutnya(order.status);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                    children: [
                      _kepala(context, order),
                      const SizedBox(height: 16.0),
                      _rincian(context, order),
                    ],
                  ),
                ),
                if (aksi != null)
                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
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
                      child: Row(
                        children: [
                          if (order.status ==
                              ApiOrderStatus.menungguKonfirmasi) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _sibuk
                                    ? null
                                    : () => _jalankan(
                                        order, SellerOrderAction.tolak),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFBA1A1A),
                                  side: const BorderSide(
                                      color: Color(0xFFBA1A1A)),
                                  minimumSize: const Size(0, 50.0),
                                ),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                          ],
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed:
                                  _sibuk ? null : () => _jalankan(order, aksi),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFAC3509),
                                disabledBackgroundColor:
                                    const Color(0xFFD9BFB6),
                                minimumSize: const Size(0, 50.0),
                              ),
                              child: Text(
                                _sibuk ? 'Memproses...' : labelAksi(aksi),
                                style: const TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kepala(BuildContext context, ApiOrder order) {
    return Container(
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
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
                  color: const Color(0xFFFFF3EF),
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: Text(
                  order.statusText,
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAC3509),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          NomorPesanan(order.orderNumber),
          const SizedBox(height: 10.0),
          if ((order.buyerName ?? '').isNotEmpty)
            _baris(context, Icons.person_outline, order.buyerName!),
          if ((order.buyerCampusId ?? '').isNotEmpty) ...[
            const SizedBox(height: 4.0),
            _baris(context, Icons.badge_outlined, order.buyerCampusId!),
          ],
          if ((order.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                'Catatan pembeli: ${order.note}',
                style: AppTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: const Color(0xFF7A5B1E),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _baris(BuildContext context, IconData ikon, String teks) => Row(
        children: [
          Icon(ikon, size: 15.0, color: const Color(0xFF59413A)),
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

  Widget _rincian(BuildContext context, ApiOrder order) {
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
          Text(
            'Menu Dipesan',
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
          const Divider(height: 20.0),
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
                        style: AppTheme.of(context).bodyMedium.override(
                              font:
                                  GoogleFonts.inter(fontWeight: FontWeight.w500),
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
                                color: const Color(0xFFAC3509),
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
          const Divider(height: 16.0),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              Text(
                order.totalLabel,
                style: AppTheme.of(context).titleLarge.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w800),
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
}
