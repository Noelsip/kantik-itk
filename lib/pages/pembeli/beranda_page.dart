import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/app_search_field.dart';
import '/components/async_view.dart';
import '/components/kantin_card.dart';
import '/components/menu_item_card.dart';
import '/components/skeleton.dart';
import '/components/student_nav_bar.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';
import '/state/session_state.dart';

/// Menampilkan beranda mahasiswa: sapaan, pencarian, penyaring kategori, daftar kantin, dan menu.
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  static String routeName = 'BerandaPage';
  static String routePath = '/beranda';

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _searchController = TextEditingController();
  final _viewKey = GlobalKey<AsyncViewState<_Beranda>>();

  ApiCategory? _category;
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Menunda pemanggilan API sampai ketikan berhenti sejenak.
  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _viewKey.currentState?.reload();
    });
  }

  void _onCategory(ApiCategory? value) {
    setState(() => _category = value);
    _viewKey.currentState?.reload();
  }

  void _clearFilters() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _category = null;
      _query = '';
    });
    _viewKey.currentState?.reload();
  }

  /// Mengambil kantin teratas dan menu tersaring dalam satu kali muat.
  ///
  /// Tanpa kata kunci, menu diurutkan dari yang paling banyak terjual
  /// (`sortBy=popular`); saat mencari, urutan bawaan server yang dipakai.
  Future<_Beranda> _load() async {
    final api = context.read<SessionState>().api;
    final state = context.read<AppState>();
    final results = await Future.wait([
      api.canteens(limit: 10, sortBy: 'menuCount', sortOrder: 'desc'),
      api.menu(
        limit: 20,
        search: _query.isEmpty ? null : _query,
        categoryId: _category?.id,
        sortBy: _query.isEmpty ? 'popular' : null,
      ),
    ]);
    // Menyegarkan kategori diam-diam agar chip mengikuti kategori bentukan penjual.
    unawaited(state.refreshCategories());
    return _Beranda(
      kantins: (results[0] as Paged<ApiCanteen>).items,
      menus: (results[1] as Paged<ApiMenuItem>).items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppState>().categories;
    final adaFilter = _category != null || _query.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.of(context).primaryBackground,
        bottomNavigationBar: const StudentNavBar(current: StudentTab.beranda),
        body: SafeArea(
          child: AsyncView<_Beranda>(
            key: _viewKey,
            load: _load,
            builder: (context, data, refresh) => ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
              children: [
                _header(context),
                const SizedBox(height: 16.0),
                AppSearchField(
                  controller: _searchController,
                  hintText: 'Cari menu atau kantin...',
                  height: 56.0,
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 16.0),
                if (categories.isNotEmpty)
                  _chipKategori(context, categories),
                if (adaFilter) ...[
                  const SizedBox(height: 10.0),
                  _barisFilter(context, data.menus.length),
                ],
                const SizedBox(height: 24.0),
                if (!adaFilter) ...[
                  _judulBagian(
                    context,
                    'Kumpulan Kantin',
                    onSeeAll: () =>
                        context.goNamed(DaftarKantinPage.routeName),
                  ),
                  const SizedBox(height: 12.0),
                  _daftarKantin(context, data.kantins),
                  const SizedBox(height: 24.0),
                ],
                _judulBagian(
                  context,
                  _category == null ? 'Menu Populer' : 'Menu ${_category!.name}',
                ),
                const SizedBox(height: 12.0),
                if (data.menus.isEmpty)
                  _kosong(context)
                else
                  for (final item in data.menus) ...[
                    MenuItemCard(
                      item: item,
                      onTap: () => context.pushNamed(
                        DetailMakananPage.routeName,
                        queryParameters: {'menuId': '${item.id}'},
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cartCount = context.watch<AppState>().cartCount;
    final user = context.watch<SessionState>().user;
    final firstName = (user?.name ?? '').split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang,',
                style: AppTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      color: const Color(0xFF59413A),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 2.0),
              Text(
                firstName.isEmpty ? 'Halo!' : 'Halo, $firstName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        _tombolKeranjang(context, cartCount),
        const SizedBox(width: 10.0),
        _tombolProfil(context, user?.profileImage),
      ],
    );
  }

  Widget _tombolKeranjang(BuildContext context, int count) {
    return Tooltip(
      message: 'Keranjang',
      child: SizedBox(
        width: 46.0,
        height: 46.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFE0BFB6)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.pushNamed(KeranjangPage.routeName),
                child: const SizedBox(
                  width: 46.0,
                  height: 46.0,
                  child: Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFFAC3509), size: 22.0),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: -2.0,
                top: -2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 1.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A),
                    borderRadius: BorderRadius.circular(999.0),
                    border: Border.all(color: const Color(0xFFFCF9F8), width: 1.5),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tombolProfil(BuildContext context, String? foto) {
    return Tooltip(
      message: 'Profil',
      child: Material(
        color: const Color(0xFFFFDBD0),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFFE0BFB6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.goNamed(ProfilPembeliPage.routeName),
          child: SizedBox(
            width: 46.0,
            height: 46.0,
            child: foto == null || foto.isEmpty
                ? const Icon(Icons.person, color: Color(0xFFAC3509), size: 24.0)
                : AppNetworkImage(
                    imageUrl: foto,
                    width: 46.0,
                    height: 46.0,
                    fallbackIcon: Icons.person,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _chipKategori(BuildContext context, List<ApiCategory> categories) {
    return SizedBox(
      height: 40.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10.0),
        itemBuilder: (context, i) {
          final category = categories[i];
          final active = _category?.id == category.id;
          return Material(
            color: active ? const Color(0xFFAC3509) : Colors.white,
            borderRadius: BorderRadius.circular(999.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(999.0),
              onTap: () => _onCategory(active ? null : category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.0),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFAC3509)
                        : const Color(0xFFE0BFB6),
                  ),
                ),
                child: Text(
                  category.name,
                  style: AppTheme.of(context).labelLarge.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color:
                            active ? Colors.white : const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _barisFilter(BuildContext context, int jumlah) {
    final bagian = [
      if (_category != null) _category!.name,
      if (_query.isNotEmpty) '"$_query"',
    ];
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 6.0, 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EF),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: const Color(0xFFE0BFB6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16.0, color: Color(0xFFAC3509)),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              '${bagian.join(' - ')} - $jumlah menu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.close, size: 15.0),
            label: const Text('Batal'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFAC3509),
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              minimumSize: const Size(0, 30.0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle:
                  const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _judulBagian(BuildContext context, String judul,
      {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            judul,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFAC3509),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Lihat Semua'),
          ),
      ],
    );
  }

  Widget _daftarKantin(BuildContext context, List<ApiCanteen> kantins) {
    if (kantins.isEmpty) {
      return _kotakKosong(context, 'Belum ada kantin yang terdaftar.');
    }
    return SizedBox(
      height: 224.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kantins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12.0),
        itemBuilder: (context, i) => KantinCard(
          kantin: kantins[i],
          width: 220.0,
          onTap: () => context.pushNamed(
            DetailKantinPage.routeName,
            queryParameters: {'canteenId': '${kantins[i].id}'},
          ),
        ),
      ),
    );
  }

  Widget _kosong(BuildContext context) => _kotakKosong(
        context,
        _query.isEmpty && _category == null
            ? 'Belum ada menu yang bisa ditampilkan.'
            : 'Tidak ada menu yang cocok dengan pencarianmu.',
      );

  Widget _kotakKosong(BuildContext context, String teks) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFEAE7E7)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 32.0, color: Color(0xFF9A8C87)),
            const SizedBox(height: 10.0),
            Text(
              teks,
              textAlign: TextAlign.center,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      );
}

/// Menyatukan hasil satu kali muat beranda: kantin teratas dan menu tersaring.
class _Beranda {
  const _Beranda({required this.kantins, required this.menus});

  final List<ApiCanteen> kantins;
  final List<ApiMenuItem> menus;
}
