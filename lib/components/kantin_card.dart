import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/api/api_models.dart';
import 'skeleton.dart';
import '/core/app_theme.dart';

/// Menampilkan kartu kantin berisi foto sampul, nama, lokasi, jumlah menu, dan status buka.
class KantinCard extends StatelessWidget {
  const KantinCard({
    super.key,
    required this.kantin,
    this.onTap,
    this.width,
  });

  final ApiCanteen kantin;
  final VoidCallback? onTap;

  /// Menetapkan lebar tetap saat kartu diletakkan dalam daftar mendatar.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final foto = kantin.imageUrl;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Ink(
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 8.0,
                color: Color(0xFFE5E2E1),
                offset: Offset(0.0, 2.0),
              )
            ],
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFEAE7E7), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    child: foto == null || foto.isEmpty
                        ? Container(
                            width: double.infinity,
                            height: 120.0,
                            color: const Color(0xFFF0EDED),
                            child: const Icon(Icons.storefront,
                                size: 36.0, color: Color(0xFF9A8C87)),
                          )
                        : AppNetworkImage(
                            imageUrl: foto,
                            width: double.infinity,
                            height: 120.0,
                          ),
                  ),
                  Positioned(
                    top: 10.0,
                    right: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: kantin.isOpen
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF757575),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Text(
                        kantin.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kantin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.of(context).titleMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            color: const Color(0xFF1B1C1C),
                            letterSpacing: 0.0,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14.0, color: Color(0xFF59413A)),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            kantin.location ?? 'Lokasi belum diisi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w400),
                                  color: const Color(0xFF59413A),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '${kantin.menuCount} menu',
                      style: AppTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            color: const Color(0xFFAC3509),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
