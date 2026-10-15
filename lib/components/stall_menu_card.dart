import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import 'app_toast.dart';
import 'menu_item_card.dart';
import '/core/app_theme.dart';
import '/state/app_state.dart';

/// Menampilkan menu pada halaman detail kantin beserta tombol favorit dan tambah keranjang.
class StallMenuCard extends StatelessWidget {
  const StallMenuCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ApiMenuItem item;
  final VoidCallback? onTap;

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
                blurRadius: 6.0,
                color: Color(0xFFE5E2E1),
                offset: Offset(0.0, 2.0),
              )
            ],
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFF0EDED), width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MenuFoto(url: item.imageUrl, size: 84.0),
                const SizedBox(width: 14.0),
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
                            isFavorite: state.isFavorite(item.id),
                            onTap: () => state.toggleFavorite(item.id),
                          ),
                        ],
                      ),
                      if ((item.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.of(context).bodySmall.override(
                                font:
                                    GoogleFonts.inter(fontWeight: FontWeight.w400),
                                color: const Color(0xFF59413A),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ],
                      if ((item.soldCount ?? 0) > 0) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          '${item.soldCount} terjual',
                          style: AppTheme.of(context).bodySmall.override(
                                font:
                                    GoogleFonts.inter(fontWeight: FontWeight.w500),
                                color: const Color(0xFF9A8C87),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.priceLabel,
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
                          FilledButton(
                            onPressed:
                                item.canOrder ? () => _addToCart(context) : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFAC3509),
                              disabledBackgroundColor: const Color(0xFFD9BFB6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0, vertical: 6.0),
                              minimumSize: const Size(0, 34.0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              inCart > 0 ? 'Tambah ($inCart)' : 'Tambah',
                              style: const TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600),
                            ),
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
