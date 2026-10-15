import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '/pages/pages.dart';
import '/state/app_state.dart';

/// Menampilkan ringkasan keranjang yang menempel di bawah layar.
///
/// Pembeli bisa langsung checkout tanpa menggulir atau membuka halaman
/// keranjang lebih dulu. Menekan ringkasannya membuka keranjang untuk
/// mengubah isi, tombolnya langsung ke checkout. Tersembunyi saat keranjang
/// kosong.
class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isCartEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
      child: Material(
        color: const Color(0xFFAC3509),
        elevation: 4.0,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => context.pushNamed(KeranjangPage.routeName),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 10.0, 10.0),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.cartCount} item di keranjang',
                        style: const TextStyle(
                          color: Color(0xFFFFDBD0),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        state.totalLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  // Menu yang tidak tersedia harus dihapus dulu lewat halaman keranjang.
                  onPressed: state.cartHasUnavailable
                      ? null
                      : () => context.pushNamed(CheckoutPage.routeName),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFAC3509),
                    disabledBackgroundColor: const Color(0x66FFFFFF),
                    disabledForegroundColor: const Color(0xFFFFDBD0),
                    minimumSize: const Size(0, 40.0),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Checkout',
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
