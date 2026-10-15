import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/app_toast.dart';
import '/components/async_view.dart';
import '/components/menu_item_card.dart';
import '/components/qty_stepper.dart';
import '/components/skeleton.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';
import '/state/session_state.dart';

/// Menampilkan detail satu menu dan menambahkannya ke keranjang beserta catatan.
class DetailMakananPage extends StatefulWidget {
  const DetailMakananPage({super.key, this.menuId});

  final String? menuId;

  static String routeName = 'DetailMakananPage';
  static String routePath = '/detail-makanan';

  @override
  State<DetailMakananPage> createState() =>
      _DetailMakananPageState();
}

class _DetailMakananPageState extends State<DetailMakananPage> {
  final _noteController = TextEditingController();
  int _jumlah = 1;
  bool _mengirim = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<ApiMenuItem> _load() async {
    final api = context.read<SessionState>().api;
    final id = int.tryParse(widget.menuId ?? '');
    if (id == null) throw const FormatException('Menu tidak dikenal');
    return api.menuItem(id);
  }

  /// Mengirim menu ke keranjang beserta jumlah dan catatannya.
  Future<void> _tambah(ApiMenuItem item) async {
    setState(() => _mengirim = true);
    final state = context.read<AppState>();
    final ok = await state.addToCart(
      item.id,
      quantity: _jumlah,
      note: _noteController.text,
    );
    if (!mounted) return;
    setState(() => _mengirim = false);
    showToast(
      ok
          ? '${item.name} ditambahkan ke keranjang'
          : state.error ?? 'Gagal menambah ke keranjang',
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
              : context.goNamed(BerandaPage.routeName),
        ),
        title: Text(
          'Detail Menu',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
      ),
      body: SafeArea(
        child: AsyncView<ApiMenuItem>(
          load: _load,
          builder: (context, item, refresh) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                          ? Container(
                              height: 220.0,
                              color: const Color(0xFFF0EDED),
                              child: const Icon(Icons.restaurant,
                                  size: 48.0, color: Color(0xFF9A8C87)),
                            )
                          : AppNetworkImage(
                              imageUrl: item.imageUrl!,
                              width: double.infinity,
                              height: 220.0,
                            ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                  color: const Color(0xFF1B1C1C),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                        Consumer<AppState>(
                          builder: (context, state, _) => FavoriteButton(
                            isFavorite: state.isFavorite(item.id),
                            onTap: () => state.toggleFavorite(item.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    InkWell(
                      onTap: () => context.pushNamed(
                        DetailKantinPage.routeName,
                        queryParameters: {'canteenId': '${item.canteenId}'},
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront,
                              size: 16.0, color: Color(0xFFAC3509)),
                          const SizedBox(width: 6.0),
                          // Flexible agar nama kantin yang panjang terpotong, bukan meluap.
                          Flexible(
                            child: Text(
                              item.stallName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500),
                                    color: const Color(0xFFAC3509),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      item.priceLabel,
                      style: AppTheme.of(context).headlineSmall.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                            color: const Color(0xFFAC3509),
                            letterSpacing: 0.0,
                          ),
                    ),
                    if (item.category != null) ...[
                      const SizedBox(height: 10.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDBD0),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                        child: Text(
                          item.category!.name,
                          style: const TextStyle(
                            color: Color(0xFFAC3509),
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16.0),
                      Text(
                        item.description!,
                        style: AppTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400),
                              color: const Color(0xFF59413A),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20.0),
                    Text(
                      'Catatan untuk penjual',
                      style: AppTheme.of(context).titleMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            color: const Color(0xFF1B1C1C),
                            letterSpacing: 0.0,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _noteController,
                      maxLength: 255,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Contoh: pedas sedikit, tanpa sambal',
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
              _bilahBawah(context, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bilahBawah(BuildContext context, ApiMenuItem item) {
    final bisa = item.canOrder && !_mengirim;
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
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
            QtyStepper(
              quantity: _jumlah,
              onChanged: (value) => setState(() => _jumlah = value),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: FilledButton(
                onPressed: bisa ? () => _tambah(item) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAC3509),
                  disabledBackgroundColor: const Color(0xFFD9BFB6),
                  minimumSize: const Size(0, 50.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  !item.isAvailable
                      ? 'Menu Habis'
                      : !item.canteenIsOpen
                          ? 'Kantin Tutup'
                          : _mengirim
                              ? 'Menambahkan...'
                              : 'Tambah ke Keranjang',
                  style: const TextStyle(
                      fontSize: 15.0, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
