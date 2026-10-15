import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/components/skeleton.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/pages/pages.dart';
import '/state/session_state.dart';

/// Layar pembuka saat aplikasi pertama dijalankan.
///
/// Logo muncul dengan animasi masuk, disusul nama aplikasi dan tagline,
/// lalu berpindah sendiri ke halaman masuk. Menyentuh layar melewatkan
/// animasi.
///
/// Perpindahan menunggu pemulihan sesi selesai. Bila pemulihan itu gagal,
/// layar ini menampilkan galatnya beserta tombol coba lagi, bukan menahan
/// pengguna pada titik-titik pemuatan tanpa akhir.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static String routeName = 'SplashPage';
  static String routePath = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Mengatur animasi masuk logo dan teks.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Berputar terus untuk ornamen latar dan titik pemuatan.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  Timer? _advanceTimer;
  bool _leaving = false;

  /// Waktu tampil splash sudah habis, tinggal menunggu hasil pemulihan sesi.
  bool _waitingForSession = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _advanceTimer = Timer(const Duration(milliseconds: 2800), _advance);
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Berpindah ke halaman berikutnya sesuai keadaan sesi.
  ///
  /// Bila pemulihan sesi belum selesai, kepindahan ditunda sampai selesai
  /// agar pengguna yang sudah masuk tidak dilempar ke halaman masuk.
  void _advance() {
    if (_leaving || !mounted) return;
    final session = context.read<SessionState>();
    if (session.status == SessionStatus.memeriksa) {
      _waitingForSession = true;
      return;
    }
    _leaving = true;
    _advanceTimer?.cancel();
    context.goNamed(
      session.isLoggedIn
          ? session.homeRouteName
          : LoginPage.routeName,
    );
  }

  /// Interval animasi yang dipotong agar tiap elemen muncul bergantian.
  Animation<double> _stagger(double begin, double end) => CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  /// Mengulang pemulihan sesi setelah gagal.
  ///
  /// Setelah berhasil, perpindahan halaman dikerjakan oleh [build] yang
  /// ikut memantau status sesi, jadi di sini cukup memicu pemuatannya.
  void _retrySession() {
    _waitingForSession = true;
    context.read<SessionState>().restore();
  }

  @override
  Widget build(BuildContext context) {
    // Bila splash sudah selesai lebih dulu, lanjutkan begitu sesi diketahui.
    final session = context.watch<SessionState>();
    final status = session.status;
    if (_waitingForSession && status != SessionStatus.memeriksa) {
      _waitingForSession = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
    }

    final logoIn = _stagger(0.0, 0.55);
    final titleIn = _stagger(0.35, 0.8);
    final taglineIn = _stagger(0.55, 1.0);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: GestureDetector(
        onTap: _advance,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF8A5B),
                Color(0xFFFF7043),
                Color(0xFFD8451A),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ornamen bulat yang berputar pelan di latar.
              AnimatedBuilder(
                animation: _ambient,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _BubblePainter(progress: _ambient.value),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    _fadeSlide(
                      logoIn,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0)
                            .animate(logoIn),
                        child: _logoBadge(),
                      ),
                    ),
                    const SizedBox(height: 28.0),
                    _fadeSlide(
                      titleIn,
                      child: Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: AppTheme.of(context).headlineLarge.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800),
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    _fadeSlide(
                      taglineIn,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          AppConstants.tagline,
                          textAlign: TextAlign.center,
                          style: AppTheme.of(context).bodyLarge.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400),
                                color: const Color(0xFFFFE7DE),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    if (session.restoreFailed)
                      _fadeSlide(taglineIn, child: _retryCard(context, session))
                    else ...[
                      _fadeSlide(
                        taglineIn,
                        child: AnimatedBuilder(
                          animation: _ambient,
                          builder: (context, _) =>
                              _LoadingDots(progress: _ambient.value),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      _fadeSlide(
                        taglineIn,
                        child: Text(
                          'Menyiapkan menu hari ini...',
                          style: AppTheme.of(context).bodySmall.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400),
                                color: const Color(0xFFFFD9CB),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 36.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu putih berisi keterangan kegagalan beserta tombol coba lagi.
  ///
  /// Isinya memakai [NetworkErrorView] yang sama dengan halaman lain, dan
  /// dialasi putih supaya teksnya tetap terbaca di atas latar gradien.
  Widget _retryCard(BuildContext context, SessionState session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9F8),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: NetworkErrorView(
          message: session.error ??
              'Gagal menyiapkan sesi. Periksa koneksi internetmu lalu '
                  'coba lagi.',
          onRetry: _retrySession,
        ),
      ),
    );
  }

  /// Membungkus [child] dengan pudar dan geser ke atas mengikuti [animation].
  Widget _fadeSlide(Animation<double> animation, {required Widget child}) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _logoBadge() {
    return Container(
      width: 168.0,
      height: 168.0,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 40.0,
            spreadRadius: 4.0,
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0.0, 12.0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.restaurant_menu,
          size: 64.0,
          color: Color(0xFFAC3509),
        ),
      ),
    );
  }
}

/// Tiga titik yang membesar bergantian sebagai penanda pemuatan.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        // Setiap titik tertinggal sepertiga siklus dari titik sebelumnya.
        final phase = (progress * 6 + i / 3.0) % 1.0;
        final scale = 0.6 + 0.4 * math.sin(phase * math.pi).abs();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55 + 0.45 * scale),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Lingkaran-lingkaran transparan yang bergerak pelan di latar belakang.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.progress});

  final double progress;

  static const List<({double dx, double dy, double r, double opacity})> _seeds =
      [
    (dx: 0.15, dy: 0.18, r: 0.30, opacity: 0.10),
    (dx: 0.88, dy: 0.12, r: 0.20, opacity: 0.08),
    (dx: 0.78, dy: 0.72, r: 0.34, opacity: 0.07),
    (dx: 0.10, dy: 0.82, r: 0.22, opacity: 0.09),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * 2 * math.pi;
    for (var i = 0; i < _seeds.length; i++) {
      final seed = _seeds[i];
      // Setiap lingkaran mengambang mengikuti lintasan melingkar kecil.
      final drift = 12.0 + i * 4.0;
      final offset = Offset(
        seed.dx * size.width + math.cos(angle + i) * drift,
        seed.dy * size.height + math.sin(angle + i * 1.7) * drift,
      );
      canvas.drawCircle(
        offset,
        seed.r * size.width * 0.5,
        Paint()..color = Colors.white.withValues(alpha: seed.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
