import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/app_search_field.dart';
import '/components/async_view.dart';
import '/components/kantin_card.dart';
import '/components/student_nav_bar.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';
import '/state/session_state.dart';

/// Menampilkan seluruh kantin dengan pencarian, penyaring buka, dan pengurutan.
class DaftarKantinPage extends StatefulWidget {
  const DaftarKantinPage({super.key});

  static String routeName = 'DaftarKantinPage';
  static String routePath = '/daftar-kantin';

  @override
  State<DaftarKantinPage> createState() => _DaftarKantinPageState();
}

class _DaftarKantinPageState extends State<DaftarKantinPage> {
  final _searchController = TextEditingController();
  final _viewKey = GlobalKey<AsyncViewState<List<ApiCanteen>>>();

  String _query = '';
  bool _hanyaBuka = false;
  String _urut = 'name';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Menunda pencarian sampai ketikan berhenti agar tidak membanjiri API.
  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _viewKey.currentState?.reload();
    });
  }

  Future<List<ApiCanteen>> _load() async {
    final api = context.read<SessionState>().api;
    final hasil = await api.canteens(
      limit: 50,
      search: _query.isEmpty ? null : _query,
      isOpen: _hanyaBuka ? true : null,
      sortBy: _urut,
      sortOrder: _urut == 'menuCount' ? 'desc' : 'asc',
    );
    return hasil.items;
  }

  /// Membuka lembar penyaring lalu memuat ulang daftar bila pilihannya berubah.
  Future<void> _bukaFilter() async {
    final sebelum = (_hanyaBuka, _urut);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saring & Urutkan',
                style: AppTheme.of(context).titleMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 12.0),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _hanyaBuka,
                activeThumbColor: const Color(0xFFAC3509),
                title: const Text('Hanya kantin yang buka'),
                onChanged: (value) => setSheetState(() => _hanyaBuka = value),
              ),
              const Divider(),
              RadioGroup<String>(
                groupValue: _urut,
                onChanged: (value) =>
                    setSheetState(() => _urut = value ?? 'name'),
                child: Column(
                  children: [
                    for (final (nilai, label) in const [
                      ('name', 'Nama A-Z'),
                      ('menuCount', 'Menu terbanyak'),
                      ('createdAt', 'Terbaru'),
                    ])
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: nilai,
                        activeColor: const Color(0xFFAC3509),
                        title: Text(label),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setSheetState(() {
                        _hanyaBuka = false;
                        _urut = 'name';
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF59413A),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      child: const Text('Atur Ulang'),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFAC3509),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
    if (sebelum != (_hanyaBuka, _urut)) await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<AppState>().cartCount;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.of(context).primaryBackground,
        bottomNavigationBar: const StudentNavBar(current: StudentTab.jelajah),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Jelajah Kantin',
                            style: AppTheme.of(context).headlineMedium.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                  color: const Color(0xFF1B1C1C),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                        Tooltip(
                          message: 'Keranjang',
                          child: InkResponse(
                            radius: 24.0,
                            onTap: () =>
                                context.pushNamed(KeranjangPage.routeName),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.shopping_cart_outlined,
                                      color: Color(0xFFAC3509), size: 24.0),
                                ),
                                if (cartCount > 0)
                                  Positioned(
                                    right: 0.0,
                                    top: 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFBA1A1A),
                                        borderRadius:
                                            BorderRadius.circular(999.0),
                                      ),
                                      child: Text(
                                        '$cartCount',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            controller: _searchController,
                            hintText: 'Cari kantin...',
                            onChanged: _onSearch,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Material(
                          color: _hanyaBuka || _urut != 'name'
                              ? const Color(0xFFAC3509)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: _bukaFilter,
                            child: Container(
                              width: 48.0,
                              height: 48.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                    color: const Color(0xFFE0BFB6)),
                              ),
                              child: Icon(
                                Icons.tune,
                                color: _hanyaBuka || _urut != 'name'
                                    ? Colors.white
                                    : const Color(0xFF59413A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ),
              ),
              Expanded(
                child: AsyncView<List<ApiCanteen>>(
                  key: _viewKey,
                  load: _load,
                  builder: (context, kantins, refresh) => kantins.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 60.0),
                            Icon(Icons.storefront,
                                size: 40.0,
                                color: const Color(0xFF9A8C87)
                                    .withValues(alpha: 0.8)),
                            const SizedBox(height: 12.0),
                            Text(
                              _query.isEmpty
                                  ? 'Belum ada kantin terdaftar.'
                                  : 'Kantin tidak ditemukan.',
                              textAlign: TextAlign.center,
                              style: AppTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w400),
                                    color: const Color(0xFF59413A),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 24.0),
                          itemCount: kantins.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14.0),
                          itemBuilder: (context, i) => KantinCard(
                            kantin: kantins[i],
                            onTap: () => context.pushNamed(
                              DetailKantinPage.routeName,
                              queryParameters: {'canteenId': '${kantins[i].id}'},
                            ),
                          ),
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
