import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import 'app_toast.dart';
import 'skeleton.dart';
import '/core/app_theme.dart';
import '/state/app_state.dart';

/// Menampilkan satu menu beserta tombol favorit dan tombol tambah ke keranjang.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ApiMenuItem item;
  final VoidCallback? onTap;

  /// Menambah satu porsi ke keranjang lalu melaporkan hasilnya lewat toast kanan atas.
  Future<void> _addToCart(BuildContext context) async {
    final state = context.read<AppState>();
    final ok = await state.addToCart(item.id);
    showToast(
      ok
          ? '${item.name} ditambahkan ke keranjang'
          : state.error ?? 'Gagal menambah ke keranjang',
      galat: !ok,
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final state = context.read<AppState>();
    if (await state.toggleFavorite(item.id)) return;
    showToast(state.error ?? 'Gagal mengubah favorit', galat: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFavorite = state.isFavorite(item.id);
    final inCart = state.quantityOf(item.id);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4.0,
                color: Color(0xFFE5E2E1),
                offset: Offset(0.0, 2.0),
              )
            ],
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFF6F3F2), width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                MenuFoto(url: item.imageUrl, size: 96.0),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                    color: const Color(0xFF1B1C1C),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                          FavoriteButton(
                            isFavorite: isFavorite,
                            onTap: () => _toggleFavorite(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        (item.soldCount ?? 0) > 0
                            ? '${item.stallName} - ${item.soldCount} terjual'
                            : item.stallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400),
                              color: const Color(0xFF59413A),
                              letterSpacing: 0.0,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.canOrder
                                  ? item.priceLabel
                                  : '${item.priceLabel} - ${item.isAvailable ? 'kantin tutup' : 'habis'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700),
                                    color: item.canOrder
                                        ? const Color(0xFFAC3509)
                                        : const Color(0xFF9A8C87),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                          _AddButton(
                            countInCart: inCart,
                            enabled: item.canOrder,
                            onTap: () => _addToCart(context),
                          ),
                        ],
                      ),
                    ],
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

/// Menampilkan foto menu, atau penampung abu-abu saat alamatnya kosong.
class MenuFoto extends StatelessWidget {
  const MenuFoto({super.key, required this.url, this.size = 96.0});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDED),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Icon(Icons.restaurant, color: Color(0xFF9A8C87)),
      );
    }
    return AppNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      radius: 12.0,
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFavorite ? 'Hapus dari favorit' : 'Tambahkan ke favorit',
      child: InkResponse(
        onTap: onTap,
        radius: 20.0,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color:
                isFavorite ? const Color(0xFFBA1A1A) : const Color(0xFF59413A),
            size: 20.0,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.countInCart,
    required this.onTap,
    this.enabled = true,
  });

  final int countInCart;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled ? 'Tambahkan ke keranjang' : 'Menu sedang tidak tersedia',
      child: Material(
        color: enabled ? const Color(0xFFAC3509) : const Color(0xFFD9BFB6),
        borderRadius: BorderRadius.circular(8.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 32.0,
            width: countInCart > 0 ? 52.0 : 32.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 18.0),
                if (countInCart > 0) ...[
                  const SizedBox(width: 2.0),
                  Text(
                    '$countInCart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
