import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/state/notifikasi_state.dart';

/// Menempelkan jumlah notifikasi belum dibaca pada sebuah ikon.
///
/// Lencananya tersembunyi selama tidak ada notifikasi yang belum dibaca.
class NotifikasiBadge extends StatelessWidget {
  const NotifikasiBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final jumlah = context.watch<NotifikasiState>().unread;
    return Badge(
      isLabelVisible: jumlah > 0,
      label: Text(jumlah > 99 ? '99+' : '$jumlah'),
      backgroundColor: const Color(0xFFBA1A1A),
      textColor: Colors.white,
      child: child,
    );
  }
}
