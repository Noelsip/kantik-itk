import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import 'app_toast.dart';
import 'async_view.dart';
import '/core/app_theme.dart';
import '/state/notifikasi_state.dart';
import '/state/session_state.dart';

/// Menampilkan notifikasi pengguna dan menandainya terbaca, satu per satu atau sekaligus.
class NotifikasiList extends StatefulWidget {
  const NotifikasiList({super.key, this.onTapOrder});

  /// Menerima id pesanan ketika notifikasi yang ditekan menunjuk sebuah pesanan.
  final void Function(int orderId)? onTapOrder;

  @override
  State<NotifikasiList> createState() => NotifikasiListState();
}

class NotifikasiListState extends State<NotifikasiList> {
  final _viewKey = GlobalKey<AsyncViewState<List<ApiNotification>>>();

  /// Memuat daftar sekaligus menyegarkan lencana, karena pemuatan ulang selalu
  /// menyusul setiap kali notifikasi ditandai terbaca.
  ///
  /// Angka lencana diambil dari `meta.unreadCount` balasan yang sama; permintaan
  /// terpisah hanya dipakai bila server belum mengirimkannya.
  Future<List<ApiNotification>> _load() async {
    final api = context.read<SessionState>().api;
    final lencana = context.read<NotifikasiState>();
    final hasil = await api.notifications(limit: 50);
    final unread = hasil.unreadCount;
    if (unread != null) {
      lencana.setUnread(unread);
    } else {
      unawaited(lencana.refresh());
    }
    return hasil.items;
  }

  /// Menandai seluruh notifikasi terbaca lalu memuat ulang daftarnya.
  Future<void> tandaiSemuaTerbaca() async {
    final api = context.read<SessionState>().api;
    try {
      await api.markAllNotificationsRead();
      await _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      showToast(e.message, galat: true);
    }
  }

  /// Menandai satu notifikasi terbaca lalu membuka pesanan yang dirujuknya.
  Future<void> _buka(ApiNotification notif) async {
    final api = context.read<SessionState>().api;
    if (!notif.isRead) {
      try {
        await api.markNotificationRead(notif.id);
        await _viewKey.currentState?.reload();
      } on ApiException {
        // Kegagalan menandai tidak menghalangi pembukaan pesanan.
      }
    }
    if (notif.orderId != null) widget.onTapOrder?.call(notif.orderId!);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<ApiNotification>>(
      key: _viewKey,
      load: _load,
      builder: (context, notifikasi, refresh) => notifikasi.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80.0),
                const Icon(Icons.notifications_none,
                    size: 40.0, color: Color(0xFF9A8C87)),
                const SizedBox(height: 12.0),
                Text(
                  'Belum ada notifikasi.',
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
              itemCount: notifikasi.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10.0),
              itemBuilder: (context, i) => _kartu(context, notifikasi[i]),
            ),
    );
  }

  Widget _kartu(BuildContext context, ApiNotification notif) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.0),
      onTap: () => _buka(notif),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFFFF3EF),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: notif.isRead
                ? const Color(0xFFEAE7E7)
                : const Color(0xFFE0BFB6),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDBD0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long,
                  size: 18.0, color: Color(0xFFAC3509)),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight:
                                notif.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                          color: const Color(0xFF1B1C1C),
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    notif.body,
                    style: AppTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                          color: const Color(0xFF59413A),
                          letterSpacing: 0.0,
                        ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.only(top: 6.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFAC3509),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
