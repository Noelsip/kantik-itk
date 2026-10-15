import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/app_theme.dart';

/// Warna dasar dan sorotan efek berkilau pada kerangka pemuatan.
const Color _kBase = Color(0xFFEDE8E6);
const Color _kHighlight = Color(0xFFF9F6F5);

/// Menyediakan satu detak animasi bersama untuk seluruh kerangka di bawahnya.
///
/// Tanpa ini setiap kotak kerangka akan menjalankan pengontrol animasinya
/// sendiri dan kilaunya tampak tidak selaras.
class SkeletonTheme extends StatefulWidget {
  const SkeletonTheme({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonTheme> createState() => _SkeletonThemeState();
}

class _SkeletonThemeState extends State<SkeletonTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonTick(listenable: _controller, child: widget.child);
  }
}

class _SkeletonTick extends InheritedWidget {
  const _SkeletonTick({required this.listenable, required super.child});

  final Listenable listenable;

  static Listenable? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SkeletonTick>()
      ?.listenable;

  @override
  bool updateShouldNotify(_SkeletonTick oldWidget) =>
      listenable != oldWidget.listenable;
}

/// Kotak abu berkilau sebagai pengganti konten yang belum siap.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16.0,
    this.radius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  /// Kerangka berbentuk lingkaran, untuk foto profil atau ikon bulat.
  const Skeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0.0,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  /// Detak cadangan, dipakai bila widget ini berada di luar
  /// [SkeletonTheme]. Selalu dimiliki sendiri agar pembuangannya jelas;
  /// saat detak bersama tersedia, yang ini cukup dihentikan.
  late final AnimationController _fallback = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void dispose() {
    _fallback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shared = _SkeletonTick.maybeOf(context);
    final Animation<double> ticker;
    if (shared is Animation<double>) {
      if (_fallback.isAnimating) _fallback.stop();
      ticker = shared;
    } else {
      if (!_fallback.isAnimating) _fallback.repeat();
      ticker = _fallback;
    }
    return AnimatedBuilder(
      animation: ticker,
      builder: (context, _) {
        // Sorotan bergerak dari kiri layar ke kanan lalu mengulang.
        final slide = ticker.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(slide - 1, 0.0),
              end: Alignment(slide + 1, 0.0),
              colors: const [_kBase, _kHighlight, _kBase],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Kerangka satu kartu menu, meniru tata letak `MenuItemCard`.
class MenuCardSkeleton extends StatelessWidget {
  const MenuCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFF6F3F2)),
      ),
      padding: const EdgeInsets.all(12.0),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 96.0, height: 96.0, radius: 12.0),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.0),
                Skeleton(width: 160.0, height: 16.0),
                SizedBox(height: 10.0),
                Skeleton(width: 110.0, height: 12.0),
                SizedBox(height: 18.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Skeleton(width: 80.0, height: 16.0),
                    Skeleton(width: 32.0, height: 32.0, radius: 8.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kerangka satu kartu kantin.
class KantinCardSkeleton extends StatelessWidget {
  const KantinCardSkeleton({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEAE7E7)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            child: Skeleton(height: 120.0, radius: 0.0),
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 150.0, height: 16.0),
                SizedBox(height: 10.0),
                Skeleton(width: 110.0, height: 12.0),
                SizedBox(height: 10.0),
                Skeleton(width: 70.0, height: 12.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Daftar kerangka vertikal sebanyak [count].
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.itemBuilder,
    this.padding = const EdgeInsets.all(16.0),
  });

  final int count;
  final Widget Function(BuildContext, int)? itemBuilder;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonTheme(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12.0),
        itemBuilder: itemBuilder ?? (_, __) => const MenuCardSkeleton(),
      ),
    );
  }
}

/// Gambar jaringan dengan kerangka saat memuat dan tampilan khusus saat
/// gagal diambil.
///
/// Pemuatan gambar adalah titik paling sering terasa lambat ketika sinyal
/// buruk, jadi seluruh gambar di aplikasi memakai widget ini.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0.0,
    this.fallbackIcon = Icons.restaurant,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => Skeleton(
        width: width,
        height: height ?? 96.0,
        radius: radius,
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF0EDED),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: const Color(0xFF9A8C87), size: 24.0),
      ),
    );
    if (radius == 0.0) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
  }
}

/// Menampilkan kegagalan pemuatan beserta jenis dan kode galatnya, lengkap dengan tombol coba lagi.
class NetworkErrorView extends StatelessWidget {
  const NetworkErrorView({
    super.key,
    required this.onRetry,
    this.message =
        'Gagal memuat data. Periksa koneksi internetmu lalu coba lagi.',
    this.title = 'Koneksi Bermasalah',
    this.detail,
    this.icon = Icons.wifi_off,
  });

  final VoidCallback onRetry;
  final String message;

  /// Menyebut jenis kegagalan, misalnya ditolak server atau jaringan terputus.
  final String title;

  /// Menyebut kode teknisnya, misalnya `HTTP 404 - NOT_FOUND`.
  final String? detail;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDBD0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34.0, color: const Color(0xFFAC3509)),
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: AppTheme.of(context).titleMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: const Color(0xFF1B1C1C),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                      fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                  ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDED),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  detail!,
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontFamily: 'monospace',
                    color: Color(0xFF59413A),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20.0),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAC3509),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lapisan gelap dengan pemutar saat sebuah proses berjalan, misalnya
/// ketika pesanan sedang dikirim.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    this.message,
  });

  final bool busy;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (busy)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x99000000),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28.0, vertical: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFAC3509),
                        strokeWidth: 3.0,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16.0),
                        Text(
                          message!,
                          style: AppTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500),
                                color: const Color(0xFF1B1C1C),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
