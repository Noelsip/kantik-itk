import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/nomor_pesanan.dart';
import '/components/skeleton.dart';
import '/components/student_nav_bar.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';

/// Memisahkan pesanan mahasiswa menjadi yang sedang berjalan dan yang sudah selesai.
class RiwayatPesananPage extends StatefulWidget {
  const RiwayatPesananPage({super.key});

  static String routeName = 'RiwayatPesananPage';
  static String routePath = '/pesanan';

  @override
  State<RiwayatPesananPage> createState() =>
      _RiwayatPesananPageState();
}

class _RiwayatPesananPageState extends State<RiwayatPesananPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    // Mengambil pesanan terbaru dari server setiap halaman dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refreshOrders();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const StudentNavBar(current: StudentTab.pesanan),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Pesanan Saya',
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
            onPressed: () => context.read<AppState>().refreshOrders(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFAC3509),
          unselectedLabelColor: const Color(0xFF59413A),
          indicatorColor: const Color(0xFFAC3509),
          tabs: [
            Tab(text: 'Berjalan (${state.activeOrders.length})'),
            Tab(text: 'Riwayat (${state.finishedOrders.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: state.loading && state.orders.isEmpty
            ? const SkeletonList(count: 3)
            : TabBarView(
                controller: _tabs,
                children: [
                  _daftar(context, state.activeOrders, berjalan: true),
                  _daftar(context, state.finishedOrders, berjalan: false),
                ],
              ),
      ),
    );
  }

  Widget _daftar(BuildContext context, List<ApiOrder> orders,
      {required bool berjalan}) {
    return RefreshIndicator(
      color: const Color(0xFFAC3509),
      onRefresh: () => context.read<AppState>().refreshOrders(),
      child: orders.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80.0),
                Icon(
                  berjalan ? Icons.receipt_long : Icons.history,
                  size: 40.0,
                  color: const Color(0xFF9A8C87),
                ),
                const SizedBox(height: 12.0),
                Text(
                  berjalan
                      ? 'Belum ada pesanan yang berjalan.'
                      : 'Belum ada riwayat pesanan.',
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
              itemBuilder: (context, i) => _kartu(context, orders[i], berjalan),
            ),
    );
  }

  Widget _kartu(BuildContext context, ApiOrder order, bool berjalan) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: () => context.pushNamed(
        berjalan
            ? StatusPesananPage.routeName
            : DetailRiwayatPage.routeName,
        queryParameters: {'orderId': '${order.id}'},
      ),
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
            const SizedBox(height: 6.0),
            Text(
              order.stall,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 2.0),
            NomorPesanan(order.orderNumber),
            const Divider(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount} item',
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  order.totalLabel,
                  style: AppTheme.of(context).titleMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        color: const Color(0xFFAC3509),
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
