import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/nomor_pesanan.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/session_state.dart';

/// Memastikan pesanan tersimpan lalu menunjukkan menu dan ringkasannya.
///
/// Cukup stateless: halaman ini hanya menampilkan, dan data serta status
/// pemuatannya disimpan [AsyncView].
class PesananBerhasilPage extends StatelessWidget {
  const PesananBerhasilPage({super.key, this.orderId});

  final String? orderId;

  static String routeName = 'PesananBerhasilPage';
  static String routePath = '/pesanan-berhasil';

  Future<ApiOrder> _load(BuildContext context) async {
    final api = context.read<SessionState>().api;
    final id = int.tryParse(orderId ?? '');
    if (id == null) throw const FormatException('Pesanan tidak dikenal');
    return api.order(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: SafeArea(
        child: AsyncView<ApiOrder>(
          load: () => _load(context),
          pullToRefresh: false,
          builder: (context, order, refresh) => ListView(
            padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 24.0),
            children: [
              Center(
                child: Container(
                  width: 96.0,
                  height: 96.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      size: 56.0, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 22.0),
              Text(
                'Pesanan Berhasil Dibuat',
                textAlign: TextAlign.center,
                style: AppTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Pantau statusnya, lalu ambil pesananmu di kantin saat sudah siap.',
                textAlign: TextAlign.center,
                style: AppTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      color: const Color(0xFF59413A),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 24.0),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFEAE7E7)),
                ),
                child: Column(
                  children: [
                    Text(
                      order.judul,
                      textAlign: TextAlign.center,
                      style: AppTheme.of(context).titleLarge.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            color: const Color(0xFF1B1C1C),
                            letterSpacing: 0.0,
                          ),
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
                    const Divider(height: 28.0),
                    for (final item in order.items) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.menuName}',
                              style: AppTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w400),
                                    color: const Color(0xFF1B1C1C),
                                    letterSpacing: 0.0,
                                  ),
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
                      const SizedBox(height: 8.0),
                    ],
                    const Divider(height: 16.0),
                    const SizedBox(height: 8.0),
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
              const SizedBox(height: 28.0),
              FilledButton(
                onPressed: () => context.goNamed(
                  StatusPesananPage.routeName,
                  queryParameters: {'orderId': '${order.id}'},
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAC3509),
                  minimumSize: const Size(double.infinity, 52.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Lihat Status Pesanan',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12.0),
              OutlinedButton(
                onPressed: () =>
                    context.goNamed(BerandaPage.routeName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFAC3509),
                  side: const BorderSide(color: Color(0xFFAC3509)),
                  minimumSize: const Size(double.infinity, 52.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
