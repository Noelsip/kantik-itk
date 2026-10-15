import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/app_theme.dart';
import '/state/app_state.dart';

/// Pengatur jumlah item: tombol kurang, kolom angka, tombol tambah.
///
/// Angkanya bisa diketik langsung. Tombol tambah dan kurang selalu
/// bergerak satu langkah.
class QtyStepper extends StatefulWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 1,
    this.compact = false,
  });

  final int quantity;

  /// Dipanggil dengan jumlah baru. Nilai di bawah [minQuantity] hanya
  /// diteruskan bila [minQuantity] bernilai nol, sehingga pemanggil bisa
  /// memperlakukannya sebagai penghapusan baris.
  final ValueChanged<int> onChanged;

  final int minQuantity;

  /// Versi lebih rapat untuk dipakai di dalam kartu daftar.
  final bool compact;

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.quantity.toString());
  late final FocusNode _focusNode = FocusNode()
    ..addListener(() {
      if (!_focusNode.hasFocus) _commit();
    });

  @override
  void didUpdateWidget(QtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jangan menimpa teks saat pengguna sedang mengetik.
    if (widget.quantity != oldWidget.quantity && !_focusNode.hasFocus) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Membaca isi kolom dan meneruskannya. Isian kosong atau tidak valid
  /// dikembalikan ke jumlah terakhir yang sah.
  void _commit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = widget.quantity.toString();
      return;
    }
    final clamped = parsed.clamp(widget.minQuantity, kMaxQuantity);
    if (clamped != parsed) _controller.text = clamped.toString();
    if (clamped != widget.quantity) widget.onChanged(clamped);
  }

  void _step(int delta) {
    final next = widget.quantity + delta;
    if (next < widget.minQuantity || next > kMaxQuantity) return;
    _controller.text = next.toString();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 28.0 : 32.0;
    final canDecrease = widget.quantity > widget.minQuantity;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F2),
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleButton(
              icon: Icons.remove,
              size: size,
              background: Colors.white,
              foreground:
                  canDecrease ? const Color(0xFF1B1C1C) : const Color(0xFFBDB6B4),
              onTap: canDecrease ? () => _step(-1) : null,
              tooltip: 'Kurangi satu',
            ),
            SizedBox(
              width: widget.compact ? 34.0 : 42.0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onSubmitted: (_) => _commit(),
                onTapOutside: (_) => _focusNode.unfocus(),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 6.0),
                ),
                style: AppTheme.of(context).titleMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            AppTheme.of(context).titleMedium.fontWeight,
                        fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                      ),
                      color: const Color(0xFF1B1C1C),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            _circleButton(
              icon: Icons.add,
              size: size,
              background: const Color(0xFFAC3509),
              foreground: Colors.white,
              onTap: widget.quantity < kMaxQuantity ? () => _step(1) : null,
              tooltip: 'Tambah satu',
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required double size,
    required Color background,
    required Color foreground,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: foreground, size: 18.0),
          ),
        ),
      ),
    );
  }
}
