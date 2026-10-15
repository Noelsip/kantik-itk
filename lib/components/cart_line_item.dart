import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/api/api_models.dart';
import 'app_toast.dart';
import 'input_dialog.dart';
import 'menu_item_card.dart';
import 'qty_stepper.dart';
import '/core/app_theme.dart';
import '/state/app_state.dart';

/// Menampilkan satu baris keranjang beserta catatan, pengatur jumlah, dan tombol hapusnya.
class CartLineItem extends StatelessWidget {
  const CartLineItem({super.key, required this.item});

  final ApiCartItem item;

  Future<void> _confirmDelete(BuildContext context) async {
    final state = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus dari keranjang?'),
        content: Text('${item.menuName} akan dikeluarkan dari keranjangmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await state.removeCartItem(item.id);
    showToast(
      ok ? '${item.menuName} dihapus' : state.error ?? 'Gagal menghapus item',
      galat: !ok,
    );
  }

  /// Menambah, mengubah, atau mengosongkan catatan menu lewat PATCH tanpa menyentuh jumlahnya.
  Future<void> _ubahCatatan(BuildContext context) async {
    final state = context.read<AppState>();
    final catatan = await showInputDialog(
      context,
      judul: 'Catatan untuk penjual',
      label: 'Catatan (opsional)',
      petunjuk: 'Contoh: pedas sedikit, tanpa sambal',
      nilaiAwal: item.note,
      maxLength: 255,
      tombolSetuju: 'Simpan',
    );
    if (catatan == null || catatan == (item.note ?? '')) return;
    final ok = await state.setCartNote(item.id, catatan);
    showToast(
      ok
          ? (catatan.isEmpty ? 'Catatan dihapus' : 'Catatan disimpan')
          : state.error ?? 'Catatan gagal disimpan',
      galat: !ok,
    );
  }

  /// Mengubah jumlah lewat API lalu melaporkan kegagalannya tanpa mengubah tampilan.
  Future<void> _setQuantity(BuildContext context, int quantity) async {
    final state = context.read<AppState>();
    if (await state.setCartQuantity(item.id, quantity)) return;
    showToast(state.error ?? 'Gagal mengubah jumlah', galat: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuFoto(url: item.imageUrl, size: 80.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.menuName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.of(context).titleMedium.override(
                                font:
                                    GoogleFonts.inter(fontWeight: FontWeight.w600),
                                color: const Color(0xFF1B1C1C),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                      InkResponse(
                        radius: 20.0,
                        onTap: () => _confirmDelete(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.delete_outline,
                              size: 20.0, color: Color(0xFFBA1A1A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  // Ketuk untuk menambah atau mengubah catatan tanpa membuka halaman lain.
                  InkWell(
                    borderRadius: BorderRadius.circular(6.0),
                    onTap: () => _ubahCatatan(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            (item.note ?? '').isEmpty
                                ? Icons.add_comment_outlined
                                : Icons.edit_note,
                            size: 16.0,
                            color: const Color(0xFFAC3509),
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              (item.note ?? '').isEmpty
                                  ? 'Tambah catatan'
                                  : 'Catatan: ${item.note}',
                              style: AppTheme.of(context).bodySmall.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: (item.note ?? '').isEmpty
                                            ? FontWeight.w600
                                            : FontWeight.w400),
                                    color: (item.note ?? '').isEmpty
                                        ? const Color(0xFFAC3509)
                                        : const Color(0xFF59413A),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!item.isAvailable) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      'Menu ini sedang tidak tersedia',
                      style: AppTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            color: const Color(0xFFBA1A1A),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.subtotalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.of(context).titleMedium.override(
                                font:
                                    GoogleFonts.inter(fontWeight: FontWeight.w700),
                                color: const Color(0xFFAC3509),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                      QtyStepper(
                        quantity: item.quantity,
                        minQuantity: 0,
                        compact: true,
                        onChanged: (value) => _setQuantity(context, value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
