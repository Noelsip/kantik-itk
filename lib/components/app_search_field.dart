import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/app_theme.dart';

/// Kolom pencarian dengan ikon kaca pembesar dan tombol bersihkan.
///
/// Tingginya dikunci lewat [height] dan isian teksnya dibuat rapat
/// (`isDense` dengan `contentPadding` nol). Tanpa itu, `TextFormField`
/// memakai padding bawaannya yang lebih tinggi daripada kotak pembungkus,
/// sehingga teks yang diketik terdorong keluar area yang terlihat.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.height = 48.0,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4.0,
            color: Color(0xFFE5E2E1),
            offset: Offset(0.0, 2.0),
          )
        ],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF0EDED), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 8.0, 0.0),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF59413A), size: 20.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    maxLines: 1,
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight:
                                AppTheme.of(context).bodyMedium.fontWeight,
                            fontStyle:
                                AppTheme.of(context).bodyMedium.fontStyle,
                          ),
                          color: const Color(0xFF1B1C1C),
                          letterSpacing: 0.0,
                        ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: hintText,
                      hintStyle: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight:
                                  AppTheme.of(context).bodyMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: const Color(0xFF9A8C87),
                            letterSpacing: 0.0,
                          ),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18.0),
                              color: const Color(0xFF59413A),
                              splashRadius: 18.0,
                              tooltip: 'Bersihkan pencarian',
                              onPressed: () {
                                controller.clear();
                                onChanged?.call('');
                              },
                            ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 32.0,
                        minHeight: 32.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deretan pilihan kategori berbentuk pil.
///
/// Menekan pilihan yang sedang aktif akan melepasnya, sehingga seluruh
/// data ditampilkan kembali tanpa perlu tombol "Semua" terpisah.
class CategoryChips<T> extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.iconOf,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in values) ...[
          Expanded(
            child: _chip(context, value),
          ),
          if (value != values.last) const SizedBox(width: 12.0),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, T value) {
    final active = value == selected;
    final icon = iconOf?.call(value);
    return Material(
      color: active ? const Color(0xFFAC3509) : Colors.white,
      borderRadius: BorderRadius.circular(999.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(999.0),
        onTap: () => onSelected(active ? null : value),
        child: Ink(
          decoration: BoxDecoration(
            color: active ? const Color(0xFFAC3509) : Colors.white,
            borderRadius: BorderRadius.circular(999.0),
            border: Border.all(
              color: active ? const Color(0xFFAC3509) : const Color(0xFFE0BFB6),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(12.0, 10.0, 12.0, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18.0,
                    color: active ? Colors.white : const Color(0xFF59413A),
                  ),
                  const SizedBox(width: 6.0),
                ],
                Flexible(
                  child: Text(
                    labelOf(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.of(context).labelLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontStyle:
                                AppTheme.of(context).labelLarge.fontStyle,
                          ),
                          color:
                              active ? Colors.white : const Color(0xFF1B1C1C),
                          letterSpacing: 0.0,
                        ),
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
