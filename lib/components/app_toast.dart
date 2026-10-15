import 'dart:async';

import 'package:flutter/material.dart';

import '/core/nav/nav.dart' show appNavigatorKey;

/// Menampilkan pesan singkat di pojok kanan atas, di atas seluruh halaman.
///
/// Menjadi satu-satunya cara aplikasi memberi kabar hasil tindakan, supaya
/// tidak ada pesan yang menutupi tombol, bar keranjang, atau navigasi di
/// bagian bawah. Pesan baru langsung menggantikan pesan yang masih tampil.
///
/// Tidak meminta `BuildContext` karena memakai overlay navigator utama,
/// sehingga aman dipanggil setelah `await` walau halaman pemanggilnya
/// sudah ditutup.
void showToast(String pesan, {bool galat = false}) {
  final overlay = appNavigatorKey.currentState?.overlay;
  if (overlay == null) return;

  _aktif?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastView(
      pesan: pesan,
      galat: galat,
      onSelesai: () {
        if (_aktif != entry) return;
        entry.remove();
        _aktif = null;
      },
    ),
  );
  _aktif = entry;
  overlay.insert(entry);
}

OverlayEntry? _aktif;

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.pesan,
    required this.galat,
    required this.onSelesai,
  });

  final String pesan;
  final bool galat;
  final VoidCallback onSelesai;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      await _anim.reverse();
      widget.onSelesai();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8.0,
      right: 12.0,
      // Tidak menangkap sentuhan agar tombol di bawahnya tetap bisa ditekan.
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.3, 0.0), end: Offset.zero)
                .animate(curve),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: Material(
                color: widget.galat
                    ? const Color(0xFFBA1A1A)
                    : const Color(0xFF2E7D32),
                elevation: 6.0,
                borderRadius: BorderRadius.circular(12.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.galat
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Text(
                          widget.pesan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
