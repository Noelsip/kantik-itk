import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/app_toast.dart';
import '/components/async_view.dart';
import '/components/notifikasi_badge.dart';
import '/components/skeleton.dart';
import '/components/student_nav_bar.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/state/app_state.dart';
import '/services/google_auth_service.dart';
import '/state/session_state.dart';

/// Menampilkan profil mahasiswa beserta angka pesanan, daftar favorit, dan tombol keluar.
class ProfilPembeliPage extends StatefulWidget {
  const ProfilPembeliPage({super.key});

  static String routeName = 'ProfilPembeliPage';
  static String routePath = '/profil';

  @override
  State<ProfilPembeliPage> createState() => _ProfilPembeliPageState();
}

class _ProfilPembeliPageState extends State<ProfilPembeliPage> {
  final _viewKey = GlobalKey<AsyncViewState<ApiProfileStats>>();

  /// Mengambil profil terbaru sekaligus angka ringkasannya.
  Future<ApiProfileStats> _load() async {
    final session = context.read<SessionState>();
    final state = context.read<AppState>();
    await session.refreshUser();
    await state.refreshFavorites();
    return session.api.profileStats();
  }

  /// Mengakhiri sesi di server dan di Google lalu kembali ke halaman masuk.
  Future<void> _keluar() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk memesan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    final navigator = GoRouter.of(context);
    await context.read<SessionState>().logout();
    await GoogleAuthService().signOut();
    navigator.goNamed(LoginPage.routeName);
  }

  /// Melepas satu menu dari daftar favorit lewat DELETE.
  Future<void> _hapusFavorit(ApiMenuItem item) async {
    final state = context.read<AppState>();
    final ok = await state.toggleFavorite(item.id);
    if (!mounted) return;
    await _viewKey.currentState?.reload();
    showToast(
      ok
          ? '${item.name} dihapus dari favorit'
          : state.error ?? 'Gagal mengubah favorit',
      galat: !ok,
    );
  }

  /// Menampilkan daftar favorit dalam lembar bawah beserta tombol hapusnya.
  void _bukaFavorit() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Consumer<AppState>(
          builder: (context, state, _) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
            children: [
              Text(
                'Menu Favorit (${state.favoriteMenus.length})',
                style: AppTheme.of(context).titleMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 14.0),
              if (state.favoriteMenus.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Belum ada menu favorit. Tekan ikon hati pada menu untuk '
                    'menyimpannya.',
                    textAlign: TextAlign.center,
                    style: AppTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                          color: const Color(0xFF59413A),
                          letterSpacing: 0.0,
                        ),
                  ),
                )
              else
                for (final item in state.favoriteMenus)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                          ? Container(
                              width: 48.0,
                              height: 48.0,
                              color: const Color(0xFFF0EDED),
                              child: const Icon(Icons.restaurant,
                                  color: Color(0xFF9A8C87)),
                            )
                          : AppNetworkImage(
                              imageUrl: item.imageUrl!,
                              width: 48.0,
                              height: 48.0,
                            ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(item.priceLabel),
                    trailing: IconButton(
                      tooltip: 'Hapus dari favorit',
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFBA1A1A)),
                      onPressed: () => _hapusFavorit(item),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.pushNamed(
                        DetailMakananPage.routeName,
                        queryParameters: {'menuId': '${item.id}'},
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const StudentNavBar(current: StudentTab.profil),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Keranjang',
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Color(0xFFAC3509)),
            onPressed: () => context.pushNamed(KeranjangPage.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncView<ApiProfileStats>(
          key: _viewKey,
          load: _load,
          builder: (context, stats, refresh) => ListView(
            padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0),
            children: [
              _identitas(context),
              const SizedBox(height: 20.0),
              _angka(context, stats),
              const SizedBox(height: 24.0),
              _kelompokMenu(context, [
                _Entri(
                  ikon: Icons.person_outline,
                  label: 'Edit Profil',
                  onTap: () async {
                    await context
                        .pushNamed(UbahProfilPembeliPage.routeName);
                    await _viewKey.currentState?.reload();
                  },
                ),
                _Entri(
                  ikon: Icons.favorite_border,
                  label: 'Menu Favorit',
                  trailing: '${stats.favoriteCount ?? 0}',
                  onTap: _bukaFavorit,
                ),
                _Entri(
                  ikon: Icons.notifications_none,
                  label: 'Notifikasi',
                  lencana: true,
                  onTap: () =>
                      context.pushNamed(NotifikasiPembeliPage.routeName),
                ),
                _Entri(
                  ikon: Icons.help_center_outlined,
                  label: 'Pusat Bantuan',
                  onTap: () =>
                      context.pushNamed(PusatBantuanPage.routeName),
                ),
                _Entri(
                  ikon: Icons.description_outlined,
                  label: 'Syarat & Ketentuan',
                  onTap: () =>
                      context.pushNamed(SyaratKetentuanPage.routeName),
                ),
              ]),
              const SizedBox(height: 20.0),
              OutlinedButton.icon(
                onPressed: _keluar,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
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
          ),
        ),
      ),
    );
  }

  Widget _identitas(BuildContext context) {
    final user = context.watch<SessionState>().user;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEAE7E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFDBD0), width: 3.0),
            ),
            child: ClipOval(
              child: (user?.profileImage?.isNotEmpty ?? false)
                  ? AppNetworkImage(
                      imageUrl: user!.profileImage!,
                      width: 66.0,
                      height: 66.0,
                      fallbackIcon: Icons.person,
                    )
                  : Container(
                      width: 66.0,
                      height: 66.0,
                      color: const Color(0xFFFFDBD0),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person,
                          color: Color(0xFFAC3509), size: 32.0),
                    ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Memuat...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.of(context).titleLarge.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  user?.email ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 6.0),
                if (user != null)
                  Text(
                    user.subtitle,
                    maxLines: 2,
                    style: AppTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                          color: const Color(0xFF59413A),
                          letterSpacing: 0.0,
                        ),
                  ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDBD0),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    user?.nim != null
                        ? 'NIM ${user!.nim}'
                        : (user?.roleLabel ?? 'Pengguna'),
                    style: const TextStyle(
                      color: Color(0xFFAC3509),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _angka(BuildContext context, ApiProfileStats stats) {
    final kartu = [
      ('Total', stats.total),
      ('Berjalan', stats.active),
      ('Selesai', stats.completed),
      ('Favorit', stats.favoriteCount ?? 0),
    ];
    return Row(
      children: [
        for (final (label, nilai) in kartu) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFEAE7E7)),
              ),
              child: Column(
                children: [
                  Text(
                    '$nilai',
                    style: AppTheme.of(context).titleLarge.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                          color: const Color(0xFFAC3509),
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    label,
                    style: AppTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          color: const Color(0xFF59413A),
                          letterSpacing: 0.0,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (label != 'Favorit') const SizedBox(width: 10.0),
        ],
      ],
    );
  }

  Widget _kelompokMenu(BuildContext context, List<_Entri> entri) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEAE7E7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entri.length; i++) ...[
            ListTile(
              leading: entri[i].lencana
                  ? NotifikasiBadge(
                      child: Icon(entri[i].ikon,
                          color: const Color(0xFFAC3509)),
                    )
                  : Icon(entri[i].ikon, color: const Color(0xFFAC3509)),
              title: Text(
                entri[i].label,
                style: AppTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entri[i].trailing != null)
                    Text(
                      entri[i].trailing!,
                      style: const TextStyle(
                        color: Color(0xFF59413A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 6.0),
                  const Icon(Icons.chevron_right, color: Color(0xFF9A8C87)),
                ],
              ),
              onTap: entri[i].onTap,
            ),
            if (i != entri.length - 1)
              const Divider(height: 1.0, indent: 16.0, endIndent: 16.0),
          ],
        ],
      ),
    );
  }
}

/// Menyusun satu baris menu pada halaman profil.
class _Entri {
  const _Entri({
    required this.ikon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.lencana = false,
  });

  final IconData ikon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  /// Menempelkan jumlah notifikasi belum dibaca pada ikonnya.
  final bool lencana;
}
