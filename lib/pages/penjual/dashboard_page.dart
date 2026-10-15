import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/nomor_pesanan.dart';
import '/components/notifikasi_badge.dart';
import '/components/seller_nav_bar.dart';
import '/components/skeleton.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/session_state.dart';

/// Menampilkan ringkasan kantin penjual: status buka, jumlah pesanan per tahap, dan pesanan terbaru.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static String routeName = 'DashboardPage';
  static String routePath = '/dashboard';

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _viewKey = GlobalKey<AsyncViewState<_Dasbor>>();
  bool _switching = false;

  Future<_Dasbor> _load() async {
    final api = context.read<SessionState>().api;
    try {
      return _Dasbor.fromJson(await api.sellerDashboard());
    } on ApiException catch (e) {
      // Memperlakukan kantin yang belum dibuat sebagai langkah awal, bukan galat.
      if (e.isNotFound) return const _Dasbor.belumAdaKantin();
      rethrow;
    }
  }

  /// Membuka atau menutup kantin lewat PATCH lalu memuat ulang ringkasannya.
  Future<void> _setOpen(bool open) async {
    setState(() => _switching = true);
    final api = context.read<SessionState>().api;
    try {
      await api.updateMyCanteen({'isOpen': open});
      await _viewKey.currentState?.reload();
      if (mounted) {
        _pesan(open ? 'Kantin dibuka.' : 'Kantin ditutup.', galat: false);
      }
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  void _pesan(String teks, {required bool galat}) {
    showToast(teks, galat: galat);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionState>().user;

    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const SellerNavBar(current: SellerTab.dashboard),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Dasbor Penjual',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const NotifikasiBadge(
              child:
                  Icon(Icons.notifications_none, color: Color(0xFFAC3509)),
            ),
            onPressed: () =>
                context.pushNamed(NotifikasiPenjualPage.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncView<_Dasbor>(
          key: _viewKey,
          load: _load,
          builder: (context, data, refresh) => ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            children: [
              Text(
                'Halo, ${user?.name ?? 'Penjual'}',
                style: AppTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 16.0),
              if (data.kantin == null)
                _kantinBelumAda(context)
              else ...[
                _kartuKantin(context, data.kantin!),
                const SizedBox(height: 20.0),
                _ringkasan(context, data.ringkasan),
                const SizedBox(height: 24.0),
                _judul(context, 'Pesanan Terbaru'),
                const SizedBox(height: 12.0),
                if (data.pesananTerbaru.isEmpty)
                  _kosong(context, 'Belum ada pesanan masuk.')
                else
                  for (final order in data.pesananTerbaru) ...[
                    _barisPesanan(context, order),
                    const SizedBox(height: 10.0),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _judul(BuildContext context, String teks) => Text(
        teks,
        style: AppTheme.of(context).titleMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: const Color(0xFF1B1C1C),
              letterSpacing: 0.0,
            ),
      );

  Widget _kantinBelumAda(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE0BFB6)),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront, size: 40.0, color: Color(0xFFAC3509)),
          const SizedBox(height: 12.0),
          Text(
            'Kantin belum disiapkan',
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Buat kantinmu dulu agar menu dan pesanan bisa dikelola.',
            textAlign: TextAlign.center,
            style: AppTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  color: const Color(0xFF59413A),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 16.0),
          FilledButton.icon(
            onPressed: () async {
              await context
                  .pushNamed(PengaturanWarungPage.routeName);
              await _viewKey.currentState?.reload();
            },
            icon: const Icon(Icons.add_business),
            label: const Text('Siapkan Kantin'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAC3509),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuKantin(BuildContext context, ApiCanteen kantin) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: kantin.imageUrl == null || kantin.imageUrl!.isEmpty
                    ? Container(
                        width: 56.0,
                        height: 56.0,
                        color: const Color(0xFFFFDBD0),
                        child: const Icon(Icons.storefront,
                            color: Color(0xFFAC3509)),
                      )
                    : AppNetworkImage(
                        imageUrl: kantin.imageUrl!,
                        width: 56.0,
                        height: 56.0,
                      ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kantin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.of(context).titleMedium.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.w700),
                            color: const Color(0xFF1B1C1C),
                            letterSpacing: 0.0,
                          ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      kantin.location ?? 'Lokasi belum diisi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.of(context).bodySmall.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.w400),
                            color: const Color(0xFF59413A),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pengaturan warung',
                icon: const Icon(Icons.settings, color: Color(0xFF59413A)),
                onPressed: () async {
                  await context
                      .pushNamed(PengaturanWarungPage.routeName);
                  await _viewKey.currentState?.reload();
                },
              ),
            ],
          ),
          const Divider(height: 24.0),
          Row(
            children: [
              Icon(
                kantin.isOpen ? Icons.check_circle : Icons.pause_circle_filled,
                size: 18.0,
                color: kantin.isOpen
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF9A8C87),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  kantin.isOpen
                      ? 'Kantin buka, pembeli bisa memesan'
                      : 'Kantin tutup, pesanan baru ditolak',
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
              Switch(
                value: kantin.isOpen,
                activeThumbColor: const Color(0xFFAC3509),
                onChanged: _switching ? null : _setOpen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ringkasan(BuildContext context, Map<String, int> angka) {
    final kartu = [
      ('Pesanan Baru', angka['pesananBaru'] ?? 0, const Color(0xFFAC3509)),
      ('Diproses', angka['diproses'] ?? 0, const Color(0xFF1565C0)),
      ('Siap Diambil', angka['siapDiambil'] ?? 0, const Color(0xFF2E7D32)),
      ('Selesai', angka['selesai'] ?? 0, const Color(0xFF59413A)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 1.9,
      children: [
        for (final (label, nilai, warna) in kartu)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFFEAE7E7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$nilai',
                  style: AppTheme.of(context).headlineSmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        color: warna,
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _barisPesanan(BuildContext context, ApiOrder order) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.0),
      onTap: () async {
        await context.pushNamed(
          DetailPesananMasukPage.routeName,
          queryParameters: {'orderId': '${order.id}'},
        );
        await _viewKey.currentState?.reload();
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFEAE7E7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: const Color(0xFF1B1C1C),
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${order.itemCount} item - ${order.totalLabel}',
                    style: AppTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                          color: const Color(0xFF59413A),
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 2.0),
                  NomorPesanan(order.orderNumber),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
      ),
    );
  }

  Widget _kosong(BuildContext context, String teks) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFEAE7E7)),
        ),
        child: Text(
          teks,
          style: AppTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                color: const Color(0xFF9A8C87),
                letterSpacing: 0.0,
              ),
        ),
      );
}

/// Memilah isi `GET /api/seller/dashboard` menjadi bagian yang dipakai halaman.
class _Dasbor {
  const _Dasbor({
    required this.kantin,
    required this.ringkasan,
    required this.pesananTerbaru,
  });

  const _Dasbor.belumAdaKantin()
      : kantin = null,
        ringkasan = const {},
        pesananTerbaru = const [];

  final ApiCanteen? kantin;
  final Map<String, int> ringkasan;
  final List<ApiOrder> pesananTerbaru;

  factory _Dasbor.fromJson(Map<String, dynamic> j) {
    final rawKantin = j['canteen'];
    final rawRingkasan = j['summary'];
    return _Dasbor(
      kantin: rawKantin is Map
          ? ApiCanteen.fromJson(rawKantin.cast<String, dynamic>())
          : null,
      ringkasan: rawRingkasan is Map
          ? {
              for (final e in rawRingkasan.entries)
                e.key.toString(): (e.value as num?)?.toInt() ?? 0,
            }
          : const {},
      pesananTerbaru: ((j['recentOrders'] as List?) ?? const [])
          .map((e) => ApiOrder.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
