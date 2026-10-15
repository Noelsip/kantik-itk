import 'package:flutter/material.dart';

/// Meminta satu isian teks lewat dialog; null berarti pengguna membatalkan.
///
/// Mengembalikan teks yang sudah dipangkas, bisa kosong bila kolomnya dibiarkan.
Future<String?> showInputDialog(
  BuildContext context, {
  required String judul,
  required String tombolSetuju,
  String? pesan,
  String? label,
  String? petunjuk,
  String? nilaiAwal,
  int? maxLength,
  Color? warnaSetuju,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _InputDialog(
      judul: judul,
      tombolSetuju: tombolSetuju,
      pesan: pesan,
      label: label,
      petunjuk: petunjuk,
      nilaiAwal: nilaiAwal,
      maxLength: maxLength,
      warnaSetuju: warnaSetuju,
    ),
  );
}

/// Stateful karena memiliki controller kolom isiannya.
///
/// Controller dilepas di [State.dispose], yaitu setelah animasi tutup dialog
/// selesai. Melepasnya tepat setelah `showDialog` kembali terlalu cepat:
/// kolom isian masih tampil selama animasi itu dan akan memakai controller
/// yang sudah dilepas.
class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.judul,
    required this.tombolSetuju,
    this.pesan,
    this.label,
    this.petunjuk,
    this.nilaiAwal,
    this.maxLength,
    this.warnaSetuju,
  });

  final String judul;
  final String tombolSetuju;
  final String? pesan;
  final String? label;
  final String? petunjuk;
  final String? nilaiAwal;
  final int? maxLength;
  final Color? warnaSetuju;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final _controller = TextEditingController(text: widget.nilaiAwal);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kolom = TextField(
      controller: _controller,
      autofocus: true,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.petunjuk,
      ),
    );

    return AlertDialog(
      title: Text(widget.judul),
      content: widget.pesan == null
          ? kolom
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pesan!),
                const SizedBox(height: 12.0),
                kolom,
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: widget.warnaSetuju == null
              ? null
              : TextButton.styleFrom(foregroundColor: widget.warnaSetuju),
          child: Text(widget.tombolSetuju),
        ),
      ],
    );
  }
}
