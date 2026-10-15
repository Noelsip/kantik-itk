import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/nomor_pesanan.dart';
import '/components/seller_nav_bar.dart';
import '/core/app_theme.dart';
import '/components/seller_order_actions.dart';
import '/pages/pages.dart';
import '/state/session_state.dart';

/// Menampilkan pesanan yang masuk ke kantin dan memprosesnya sampai selesai.
class PesananMasukPage extends StatefulWidget {
  const PesananMasukPage({super.key});

  static String routeName = 'PesananMasukPage';
  static String routePath = '/pesanan-masuk';

  @override
  State<PesananMasukPage> createState() =>
      _PesananMasukPageState();
}

class _PesananMasukPageState
    extends State<PesananMasukPage>
    with SingleTickerProviderStateMixin {
  final _viewKey = GlobalKey<AsyncViewState<List<ApiOrder>>>();
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(_saatTabBerpindah);

  int _tab = 0;
  int? _sedangDiproses;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _saatTabBerpindah() {
    if (_tabs.indexIsChanging || _tabs.index == _tab) return;
    setState(() => _tab = _tabs.index);
    _viewKey.currentState?.reload();
  }

  /// Mengambil pesanan untuk tab yang sedang terbuka; penyaringan dikerjakan server.
  ///
  /// Tab Diproses memakai `scope=active` yang ikut memuat pesanan baru, jadi
  /// pesanan yang masih menunggu konfirmasi dibuang di sini karena sudah
  /// tampil di tab Baru.
  Future<List<ApiOrder>> _load() async {
    final api = context.read<SessionState>().api;
    return switch (_tab) {
      0 => (await api.sellerOrders(
              limit: 100, status: ApiOrderStatus.menungguKonfirmasi.value))
          .items,
      1 => (await api.sellerOrders(limit: 100, scope: 'active'))
          .items
          .where((o) => o.status != ApiOrderStatus.menungguKonfirmasi)
          .toList(),
      _ => (await api.sellerOrders(limit: 100, scope: 'history')).items,
    };
  }

  /// Menjalankan satu tindakan penjual lalu menyegarkan daftar.
  Future<void> _jalankan(ApiOrder order, SellerOrderAction aksi) async {
    setState(() => _sedangDiproses = order.id);
    final hasil = await jalankanAksiPesanan(context, order, aksi);
    if (!mounted) return;
    setState(() => _sedangDiproses = null);
    if (hasil) await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const SellerNavBar(current: SellerTab.pesanan),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Pesanan Masuk',
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
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFAC3509),
          unselectedLabelColor: const Color(0xFF59413A),
          indicatorColor: const Color(0xFFAC3509),
          tabs: const [
            Tab(text: 'Baru'),
            Tab(text: 'Diproses'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: SafeArea(
        child: AsyncView<List<ApiOrder>>(
          key: _viewKey,
          load: _load,
          builder: (context, orders, refresh) => orders.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80.0),
                    const Icon(Icons.receipt_long,
                        size: 40.0, color: Color(0xFF9A8C87)),
                    const SizedBox(height: 12.0),
                    Text(
                      switch (_tab) {
                        0 => 'Belum ada pesanan baru.',
                        1 => 'Tidak ada pesanan yang sedang diproses.',
                        _ => 'Belum ada pesanan yang selesai.',
                      },
                      textAlign: TextAlign.center,
                      style: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                            color: const Color(0xFF59413A),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (context, i) => _kartu(context, orders[i]),
                ),
        ),
      ),
    );
  }

  Widget _kartu(BuildContext context, ApiOrder order) {
    final sibuk = _sedangDiproses == order.id;
    final aksi = aksiBerikutnya(order.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: () async {
        await context.pushNamed(
          DetailPesananMasukPage.routeName,
          queryParameters: {'orderId': '${order.id}'},
        );
        await _viewKey.currentState?.reload();
      },
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.of(context).bodyLarge.override(
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
                    color: order.status.isFinished
                        ? const Color(0xFFEFEFEF)
                        : const Color(0xFFFFF3EF),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: order.status.isFinished
                          ? const Color(0xFF59413A)
                          : const Color(0xFFAC3509),
                    ),
                  ),
                ),
              ],
            ),
            if ((order.buyerName ?? '').isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                '${order.buyerName}${order.buyerCampusId == null ? '' : ' - ${order.buyerCampusId}'}',
                style: AppTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      color: const Color(0xFF59413A),
                      letterSpacing: 0.0,
                    ),
              ),
            ],
            const SizedBox(height: 2.0),
            NomorPesanan(order.orderNumber),
            const Divider(height: 20.0),
            for (final item in order.items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '${item.quantity}x ${item.menuName}',
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
            if (order.items.length > 3)
              Text(
                '+${order.items.length - 3} menu lainnya',
                style: AppTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      color: const Color(0xFF9A8C87),
                      letterSpacing: 0.0,
                    ),
              ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.totalLabel,
                  style: AppTheme.of(context).titleMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        color: const Color(0xFFAC3509),
                        letterSpacing: 0.0,
                      ),
                ),
                if (aksi != null)
                  Row(
                    children: [
                      if (order.status == ApiOrderStatus.menungguKonfirmasi)
                        TextButton(
                          onPressed: sibuk
                              ? null
                              : () =>
                                  _jalankan(order, SellerOrderAction.tolak),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFBA1A1A),
                          ),
                          child: const Text('Tolak'),
                        ),
                      FilledButton(
                        onPressed: sibuk ? null : () => _jalankan(order, aksi),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFAC3509),
                          disabledBackgroundColor: const Color(0xFFD9BFB6),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          minimumSize: const Size(0, 38.0),
                        ),
                        child: Text(
                          sibuk ? '...' : labelAksi(aksi),
                          style: const TextStyle(
                              fontSize: 12.0, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
