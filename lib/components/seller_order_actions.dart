import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/state/session_state.dart';
import 'app_toast.dart';
import 'input_dialog.dart';

/// Menyebut tindakan penjual atas sebuah pesanan.
enum SellerOrderAction { terima, proses, siap, selesai, tolak }

/// Menentukan tindakan yang wajar dilakukan berikutnya dari status saat ini.
SellerOrderAction? aksiBerikutnya(ApiOrderStatus status) => switch (status) {
      ApiOrderStatus.menungguKonfirmasi => SellerOrderAction.terima,
      ApiOrderStatus.diterima => SellerOrderAction.proses,
      ApiOrderStatus.diproses => SellerOrderAction.siap,
      ApiOrderStatus.siapDiambil => SellerOrderAction.selesai,
      _ => null,
    };

/// Menamai tombol untuk sebuah tindakan.
String labelAksi(SellerOrderAction aksi) => switch (aksi) {
      SellerOrderAction.terima => 'Terima',
      SellerOrderAction.proses => 'Proses',
      SellerOrderAction.siap => 'Siap Diambil',
      SellerOrderAction.selesai => 'Selesaikan',
      SellerOrderAction.tolak => 'Tolak',
    };

/// Menjalankan tindakan penjual, meminta alasan bila menolak, dan melaporkan hasilnya.
Future<bool> jalankanAksiPesanan(
  BuildContext context,
  ApiOrder order,
  SellerOrderAction aksi,
) async {
  final api = context.read<SessionState>().api;
  String? alasan;
  if (aksi == SellerOrderAction.tolak) {
    alasan = await _tanyaAlasan(context, order);
    if (alasan == null) return false;
  }

  try {
    await switch (aksi) {
      SellerOrderAction.terima => api.acceptOrder(order.id),
      SellerOrderAction.proses => api.processOrder(order.id),
      SellerOrderAction.siap => api.markOrderReady(order.id),
      SellerOrderAction.selesai => api.completeOrder(order.id),
      SellerOrderAction.tolak => api.rejectOrder(order.id, reason: alasan),
    };
    showToast('Pesanan ${order.judul} ${_kabar(aksi)}');
    return true;
  } on ApiException catch (e) {
    showToast(e.message, galat: true);
    return false;
  }
}

/// Meminta alasan penolakan; null berarti penjual membatalkan niatnya.
Future<String?> _tanyaAlasan(BuildContext context, ApiOrder order) =>
    showInputDialog(
      context,
      judul: 'Tolak pesanan?',
      pesan: 'Pesanan ${order.judul} akan ditolak.',
      label: 'Alasan (opsional)',
      petunjuk: 'Contoh: bahan habis',
      maxLength: 255,
      tombolSetuju: 'Tolak',
      warnaSetuju: const Color(0xFFBA1A1A),
    );

String _kabar(SellerOrderAction aksi) => switch (aksi) {
      SellerOrderAction.terima => 'diterima.',
      SellerOrderAction.proses => 'sedang diproses.',
      SellerOrderAction.siap => 'siap diambil.',
      SellerOrderAction.selesai => 'selesai.',
      SellerOrderAction.tolak => 'ditolak.',
    };
