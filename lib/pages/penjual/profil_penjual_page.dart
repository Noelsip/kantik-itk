import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/notifikasi_badge.dart';
import '/components/seller_nav_bar.dart';
import '/components/skeleton.dart';
import '/core/app_theme.dart';
import '/pages/pages.dart';
import '/services/google_auth_service.dart';
import '/state/session_state.dart';

/// Menampilkan profil penjual beserta angka kantinnya dan jalan ke pengaturan.
class ProfilPenjualPage extends StatefulWidget {
  const ProfilPenjualPage({super.key});

  static String routeName = 'ProfilPenjualPage';
  static String routePath = '/profil-penjual';

  @override
  State<ProfilPenjualPage> createState() => _ProfilPenjualPageState();
}

class _ProfilPenjualPageState extends State<ProfilPenjualPage> {
  final _viewKey = GlobalKey<AsyncViewState<ApiProfileStats>>();

  Future<ApiProfileStats> _load() async {
    final session = context.read<SessionState>();
    await session.refreshUser();
    return session.api.profileStats();
  }

  /// Mengakhiri sesi di server dan di Google lalu kembali ke halaman masuk.
  Future<void> _keluar() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk mengelola kantin.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      bottomNavigationBar: const SellerNavBar(current: SellerTab.profil),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil Penjual',
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
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
              _kelompok(context, [
                (
                  Icons.storefront,
                  'Pengaturan Warung',
                  () async {
                    await context
                        .pushNamed(PengaturanWarungPage.routeName);
                    await _viewKey.currentState?.reload();
                  }
                ),
                (
                  Icons.restaurant_menu,
                  'Kelola Menu',
                  () => context.goNamed(KelolaMenuPage.routeName)
                ),
                (
                  Icons.person_outline,
                  'Edit Profil',
                  () async {
                    await context
                        .pushNamed(UbahProfilPenjualPage.routeName);
                    await _viewKey.currentState?.reload();
                  }
                ),
                (
                  Icons.notifications_none,
                  'Notifikasi',
                  () => context.pushNamed(NotifikasiPenjualPage.routeName)
                ),
                (
                  Icons.help_center_outlined,
                  'Pusat Bantuan',
                  () => context.pushNamed(PusatBantuanPage.routeName)
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
                      color: const Color(0xFFFFDBD0),
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront,
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
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDBD0),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    user?.roleLabel ?? 'Penjual',
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
      ('Menu', stats.menuCount ?? 0),
      ('Pesanan', stats.total),
      ('Berjalan', stats.active),
      ('Selesai', stats.completed),
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
          if (label != 'Selesai') const SizedBox(width: 10.0),
        ],
      ],
    );
  }

  Widget _kelompok(
    BuildContext context,
    List<(IconData, String, VoidCallback)> entri,
  ) {
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
              leading: entri[i].$1 == Icons.notifications_none
                  ? NotifikasiBadge(
                      child:
                          Icon(entri[i].$1, color: const Color(0xFFAC3509)),
                    )
                  : Icon(entri[i].$1, color: const Color(0xFFAC3509)),
              title: Text(
                entri[i].$2,
                style: AppTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: Color(0xFF9A8C87)),
              onTap: entri[i].$3,
            ),
            if (i != entri.length - 1)
              const Divider(height: 1.0, indent: 16.0, endIndent: 16.0),
          ],
        ],
      ),
    );
  }
}
