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

/// Melacak kemajuan satu pesanan sekaligus menyediakan pembatalan.
class StatusPesananPage extends StatefulWidget {
  const StatusPesananPage({super.key, this.orderId});

  final String? orderId;

  static String routeName = 'StatusPesananPage';
  static String routePath = '/status-pesanan';

  @override
  State<StatusPesananPage> createState() =>
      _StatusPesananPageState();
}

class _StatusPesananPageState extends State<StatusPesananPage> {
  final _viewKey = GlobalKey<AsyncViewState<ApiOrder>>();
  bool _membatalkan = false;

  Future<ApiOrder> _load() async {
    final api = context.read<SessionState>().api;
    final id = int.tryParse(widget.orderId ?? '');
    if (id == null) throw const FormatException('Pesanan tidak dikenal');
    return api.order(id);
  }

  /// Membatalkan pesanan setelah dikonfirmasi lalu memuat ulang statusnya.
  Future<void> _batalkan(ApiOrder order) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text('Pesanan ${order.judul} akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    setState(() => _membatalkan = true);
    final state = context.read<AppState>();
    final ok = await state.cancelOrder(order.id);
    if (!mounted) return;
    setState(() => _membatalkan = false);
    await _viewKey.currentState?.reload();
    showToast(
      ok ? 'Pesanan dibatalkan.' : state.error ?? 'Pesanan gagal dibatalkan',
      galat: !ok,
    );
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
          'Status Pesanan',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh, color: Color(0xFFAC3509)),
            onPressed: () => _viewKey.currentState?.reload(),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncView<ApiOrder>(
          key: _viewKey,
          load: _load,
          builder: (context, order, refresh) => ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            children: [
              _kepala(context, order),
              const SizedBox(height: 20.0),
              _tahapan(context, order),
              const SizedBox(height: 20.0),
              _rincian(context, order),
              if (order.isCancellable) ...[
                const SizedBox(height: 20.0),
                OutlinedButton.icon(
                  onPressed: _membatalkan ? null : () => _batalkan(order),
                  icon: const Icon(Icons.close),
                  label: Text(
                      _membatalkan ? 'Membatalkan...' : 'Batalkan Pesanan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFBA1A1A)),
                    minimumSize: const Size(double.infinity, 50.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
          Text(
            order.judul,
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
          const SizedBox(height: 12.0),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EF),
              borderRadius: BorderRadius.circular(999.0),
            ),
            child: Text(
              order.statusText,
              style: const TextStyle(
                color: Color(0xFFAC3509),
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if ((order.rejectReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Text(
              'Alasan penolakan: ${order.rejectReason}',
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    color: const Color(0xFFBA1A1A),
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menggambar urutan tahapan pesanan dan menandai yang sudah dilewati.
  Widget _tahapan(BuildContext context, ApiOrder order) {
    const urutan = [
      ApiOrderStatus.menungguKonfirmasi,
      ApiOrderStatus.diterima,
      ApiOrderStatus.diproses,
      ApiOrderStatus.siapDiambil,
      ApiOrderStatus.selesai,
    ];
    if (order.status == ApiOrderStatus.ditolak ||
        order.status == ApiOrderStatus.dibatalkan) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFE8A0A0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Color(0xFFBA1A1A)),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                'Pesanan ${order.statusText.toLowerCase()}.',
                style: AppTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: const Color(0xFFBA1A1A),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final posisi = urutan.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < urutan.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22.0,
                    height: 22.0,
                    decoration: BoxDecoration(
                      color: i <= posisi
                          ? const Color(0xFFAC3509)
                          : const Color(0xFFE0BFB6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      i <= posisi ? Icons.check : Icons.circle_outlined,
                      size: 14.0,
                      color: Colors.white,
                    ),
                  ),
                  if (i != urutan.length - 1)
                    Container(
                      width: 2.0,
                      height: 28.0,
                      color: i < posisi
                          ? const Color(0xFFAC3509)
                          : const Color(0xFFE0BFB6),
                    ),
                ],
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Text(
                    urutan[i].label,
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight:
                                i <= posisi ? FontWeight.w600 : FontWeight.w400,
                          ),
                          color: i <= posisi
                              ? const Color(0xFF1B1C1C)
                              : const Color(0xFF9A8C87),
                          letterSpacing: 0.0,
                        ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

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
            'Rincian Pesanan',
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
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400),
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
          if ((order.note ?? '').isNotEmpty) ...[
            const Divider(height: 16.0),
            Text(
              'Catatan: ${order.note}',
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
          ],
          const Divider(height: 20.0),
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
