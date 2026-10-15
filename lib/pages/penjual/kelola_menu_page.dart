import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/menu_item_card.dart';
import '/components/seller_nav_bar.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/session_state.dart';

/// Mengelola katalog menu penjual: menambah, menyunting, menghapus, dan mengatur ketersediaan.
class KelolaMenuPage extends StatefulWidget {
  const KelolaMenuPage({super.key});

  static String routeName = 'KelolaMenuPage';
  static String routePath = '/kelola-menu';

  @override
  State<KelolaMenuPage> createState() => _KelolaMenuPageState();
}

class _KelolaMenuPageState extends State<KelolaMenuPage> {
  final _viewKey = GlobalKey<AsyncViewState<List<ApiMenuItem>?>>();
  int? _sedangDiubah;
  bool _adaKantin = true;

  /// Mengambil menu kantin sendiri; null berarti kantinnya belum dibuat.
  Future<List<ApiMenuItem>?> _load() async {
    final api = context.read<SessionState>().api;
    try {
      final hasil = await api.sellerMenu(limit: 100);
      if (mounted) setState(() => _adaKantin = hasil.canteen != null);
      return hasil.canteen == null ? null : hasil.items;
    } on ApiException catch (e) {
      if (!e.isNotFound) rethrow;
      if (mounted) setState(() => _adaKantin = false);
      return null;
    }
  }

  void _pesan(String teks, {required bool galat}) {
    showToast(teks, galat: galat);
  }

  /// Menyalakan atau mematikan ketersediaan satu menu lewat PATCH.
  Future<void> _ubahKetersediaan(ApiMenuItem item, bool tersedia) async {
    setState(() => _sedangDiubah = item.id);
    final api = context.read<SessionState>().api;
    try {
      await api.updateMenu(item.id, {'isAvailable': tersedia});
      await _viewKey.currentState?.reload();
      if (mounted) {
        _pesan(tersedia ? '${item.name} tersedia lagi.' : '${item.name} ditandai habis.',
            galat: false);
      }
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    } finally {
      if (mounted) setState(() => _sedangDiubah = null);
    }
  }

  /// Menghapus menu setelah dikonfirmasi, termasuk dari keranjang pembeli.
  Future<void> _hapus(ApiMenuItem item) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus menu?'),
        content: Text(
          '${item.name} akan dihapus dari katalog dan dari keranjang pembeli '
          'yang sudah memilihnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    setState(() => _sedangDiubah = item.id);
    final api = context.read<SessionState>().api;
    try {
      await api.deleteMenu(item.id);
      await _viewKey.currentState?.reload();
      if (mounted) _pesan('${item.name} dihapus.', galat: false);
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    } finally {
      if (mounted) setState(() => _sedangDiubah = null);
    }
  }

  /// Membuka formulir menu lalu memuat ulang daftar begitu formulir ditutup.
  Future<void> _bukaFormulir({int? menuId}) async {
    await context.pushNamed(
      FormMenuPage.routeName,
      queryParameters: {if (menuId != null) 'menuId': '$menuId'},
    );
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const SellerNavBar(current: SellerTab.menu),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Kelola Menu',
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
      floatingActionButton: _adaKantin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFAC3509),
              foregroundColor: Colors.white,
              onPressed: () => _bukaFormulir(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Menu'),
            )
          : null,
      body: SafeArea(
        child: AsyncView<List<ApiMenuItem>?>(
          key: _viewKey,
          load: _load,
          builder: (context, menus, refresh) => menus == null
              ? _kantinBelumAda(context)
              : menus.isEmpty
              ? _kosong(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0),
                  itemCount: menus.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (context, i) => _kartu(context, menus[i]),
                ),
        ),
      ),
    );
  }

  Widget _kartu(BuildContext context, ApiMenuItem item) {
    final sibuk = _sedangDiubah == item.id;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEAE7E7)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuFoto(url: item.imageUrl, size: 76.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.of(context).titleMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            color: const Color(0xFF1B1C1C),
                            letterSpacing: 0.0,
                          ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      item.category?.name ?? 'Tanpa kategori',
                      style: AppTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                            color: const Color(0xFF9A8C87),
                            letterSpacing: 0.0,
                          ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      item.priceLabel,
                      style: AppTheme.of(context).titleMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            color: const Color(0xFFAC3509),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20.0),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: item.isAvailable,
                      activeThumbColor: const Color(0xFFAC3509),
                      onChanged: sibuk
                          ? null
                          : (value) => _ubahKetersediaan(item, value),
                    ),
                    Flexible(
                      child: Text(
                        item.isAvailable ? 'Tersedia' : 'Habis',
                        style: AppTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500),
                              color: item.isAvailable
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF9A8C87),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ubah menu',
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF59413A)),
                onPressed: sibuk ? null : () => _bukaFormulir(menuId: item.id),
              ),
              IconButton(
                tooltip: 'Hapus menu',
                icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A)),
                onPressed: sibuk ? null : () => _hapus(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mengarahkan penjual membuat kantin lebih dulu karena menu bergantung padanya.
  Widget _kantinBelumAda(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
        children: [
          const Icon(Icons.storefront, size: 44.0, color: Color(0xFF9A8C87)),
          const SizedBox(height: 14.0),
          Text(
            'Kantin belum dibuat',
            textAlign: TextAlign.center,
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Menu menempel pada kantin, jadi buat kantinmu lebih dulu.',
            textAlign: TextAlign.center,
            style: AppTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  color: const Color(0xFF59413A),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 20.0),
          Center(
            child: FilledButton.icon(
              onPressed: () async {
                await context.pushNamed(PengaturanWarungPage.routeName);
                await _viewKey.currentState?.reload();
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Buat Kantin'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAC3509),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22.0, vertical: 12.0),
              ),
            ),
          ),
        ],
      );

  Widget _kosong(BuildContext context) => ListView(
        children: [
          const SizedBox(height: 70.0),
          const Icon(Icons.restaurant_menu, size: 44.0, color: Color(0xFF9A8C87)),
          const SizedBox(height: 14.0),
          Text(
            'Katalogmu masih kosong',
            textAlign: TextAlign.center,
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Tambahkan menu pertamamu agar muncul di aplikasi pembeli.',
            textAlign: TextAlign.center,
            style: AppTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  color: const Color(0xFF59413A),
                  letterSpacing: 0.0,
                ),
          ),
        ],
      );
}
