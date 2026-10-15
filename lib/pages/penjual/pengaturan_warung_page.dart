import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/skeleton.dart';
import '/config/kantin_terdaftar.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/state/session_state.dart';

/// Membuat kantin penjual dan menyunting datanya, termasuk membuka atau menutupnya.
class PengaturanWarungPage extends StatefulWidget {
  const PengaturanWarungPage({super.key});

  static String routeName = 'PengaturanWarungPage';
  static String routePath = '/pengaturan-warung';

  @override
  State<PengaturanWarungPage> createState() =>
      _PengaturanWarungPageState();
}

class _PengaturanWarungPageState
    extends State<PengaturanWarungPage> {
  final _viewKey = GlobalKey<AsyncViewState<ApiCanteen?>>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whatsappController = TextEditingController();

  bool _buka = true;
  String? _imageUrl;
  bool _menyimpan = false;
  bool _mengunggah = false;
  bool _terisi = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  /// Mengambil kantin milik penjual; null berarti kantinnya belum dibuat.
  Future<ApiCanteen?> _load() async {
    final api = context.read<SessionState>().api;
    try {
      final kantin = await api.myCanteen();
      if (!_terisi) {
        _nameController.text = kantin.name;
        _locationController.text = kantin.location ?? '';
        _descriptionController.text = kantin.description ?? '';
        _whatsappController.text = kantin.whatsapp ?? '';
        _buka = kantin.isOpen;
        _imageUrl = kantin.imageUrl;
        _terisi = true;
      }
      return kantin;
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  void _pesan(String teks, {required bool galat}) {
    showToast(teks, galat: galat);
  }

  /// Menyimpan kantin lewat POST saat belum ada, atau PATCH saat sudah ada.
  Future<void> _simpan({required bool baru}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _menyimpan = true);

    final api = context.read<SessionState>().api;
    final lokasi = _locationController.text.trim();
    final keterangan = _descriptionController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final isi = <String, Object?>{
      'name': _nameController.text.trim(),
      'location': lokasi.isEmpty ? null : lokasi,
      'description': keterangan.isEmpty ? null : keterangan,
      'whatsapp': whatsapp.isEmpty ? null : whatsapp,
      'isOpen': _buka,
    };

    try {
      if (baru) {
        await api.createMyCanteen(isi..removeWhere((_, v) => v == null));
      } else {
        await api.updateMyCanteen(isi);
      }
      _terisi = false;
      await _viewKey.currentState?.reload();
      if (mounted) {
        _pesan(baru ? 'Kantin dibuat.' : 'Data kantin tersimpan.', galat: false);
      }
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  /// Mengunggah foto kantin dan langsung memasangnya lewat endpoint fotonya.
  Future<void> _gantiFoto() async {
    final berkas = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (berkas == null || !mounted) return;

    setState(() => _mengunggah = true);
    final api = context.read<SessionState>().api;
    try {
      final kantin = await api.uploadCanteenPhoto(berkas.path);
      if (!mounted) return;
      setState(() => _imageUrl = kantin.imageUrl);
      _pesan('Foto kantin diperbarui.', galat: false);
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  /// Menyalin isian sebuah entri daftar kantin ke formulir tanpa mengirimnya.
  void _isiDariDaftar(KantinTerdaftar entri) {
    setState(() {
      _nameController.text = entri.nama;
      _locationController.text = entri.lokasi ?? '';
      _descriptionController.text = entri.deskripsi ?? '';
      _whatsappController.text = entri.whatsapp ?? '';
      _imageUrl = entri.fotoUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFCF9F8),
          elevation: 0.0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Pengaturan Warung',
            style: AppTheme.of(context).titleLarge.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
        ),
        body: SafeArea(
          child: AsyncView<ApiCanteen?>(
            key: _viewKey,
            load: _load,
            builder: (context, kantin, refresh) =>
                _formulir(context, baru: kantin == null),
          ),
        ),
      ),
    );
  }

  Widget _formulir(BuildContext context, {required bool baru}) {
    final sibuk = _menyimpan || _mengunggah;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
        children: [
          if (baru) ...[
            _pengantarKantinBaru(context),
            const SizedBox(height: 20.0),
          ] else
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: _imageUrl == null || _imageUrl!.isEmpty
                        ? Container(
                            width: 180.0,
                            height: 120.0,
                            color: const Color(0xFFF0EDED),
                            child: const Icon(Icons.storefront,
                                size: 40.0, color: Color(0xFF9A8C87)),
                          )
                        : AppNetworkImage(
                            imageUrl: _imageUrl!,
                            width: 180.0,
                            height: 120.0,
                          ),
                  ),
                  const SizedBox(height: 8.0),
                  TextButton.icon(
                    onPressed: _mengunggah ? null : _gantiFoto,
                    icon: Icon(
                      _mengunggah
                          ? Icons.hourglass_top
                          : Icons.photo_camera_outlined,
                      size: 18.0,
                    ),
                    label: Text(
                        _mengunggah ? 'Mengunggah...' : 'Ganti Foto Kantin'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFAC3509)),
                  ),
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          _label(context, 'Nama kantin'),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _nameController,
            maxLength: 100,
            decoration: _dekorasi('Nama yang dilihat pembeli'),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12.0),
          _label(context, 'Lokasi'),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _locationController,
            maxLength: 255,
            decoration: _dekorasi('Letak kantin di kampus'),
          ),
          const SizedBox(height: 12.0),
          _label(context, 'Nomor WhatsApp'),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            decoration: _dekorasi('Nomor yang bisa dihubungi pembeli'),
          ),
          const SizedBox(height: 12.0),
          _label(context, 'Keterangan'),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _descriptionController,
            maxLength: 1000,
            maxLines: 3,
            decoration: _dekorasi('Menu andalan, jam buka, dan lainnya'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _buka,
            activeThumbColor: const Color(0xFFAC3509),
            title: const Text('Kantin sedang buka'),
            subtitle: Text(
              _buka
                  ? 'Pembeli bisa membuat pesanan baru.'
                  : 'Pesanan baru ditolak sampai dibuka kembali.',
              style: const TextStyle(fontSize: 12.0),
            ),
            onChanged: (value) => setState(() => _buka = value),
          ),
          const SizedBox(height: 16.0),
          FilledButton(
            onPressed: sibuk ? null : () => _simpan(baru: baru),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAC3509),
              disabledBackgroundColor: const Color(0xFFD9BFB6),
              minimumSize: const Size(double.infinity, 52.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              _menyimpan
                  ? 'Menyimpan...'
                  : baru
                      ? 'Buat Kantin'
                      : 'Simpan Perubahan',
              style:
                  const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
            ),
          ),
          if (baru) ...[
            const SizedBox(height: 10.0),
            Text(
              'Foto kantin bisa diunggah setelah kantin dibuat.',
              textAlign: TextAlign.center,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                    color: const Color(0xFF9A8C87),
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menyapa penjual yang belum punya kantin dan menawarkan isi cepat bila daftarnya terisi.
  Widget _pengantarKantinBaru(BuildContext context) {
    final email = context.read<SessionState>().user?.email ?? '';
    final disarankan = kantinUntukPenjual(email);
    final pilihan = [
      if (disarankan != null) disarankan,
      ...kKantinTerdaftar.where((k) => k != disarankan),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EF),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFFE0BFB6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFFAC3509)),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  'Kantinmu belum dibuat. Isi data di bawah, lalu menu bisa '
                  'ditambahkan.',
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: const Color(0xFF7A3B1E),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (pilihan.isNotEmpty) ...[
          const SizedBox(height: 16.0),
          _label(context, 'Isi cepat dari daftar kantin'),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final entri in pilihan)
                ActionChip(
                  label: Text(entri.nama),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: entri == disarankan
                        ? const Color(0xFFAC3509)
                        : const Color(0xFFE0BFB6),
                  ),
                  onPressed: () => _isiDariDaftar(entri),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _label(BuildContext context, String teks) => Text(
        teks,
        style: AppTheme.of(context).bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: const Color(0xFF1B1C1C),
              letterSpacing: 0.0,
            ),
      );

  InputDecoration _dekorasi(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFE0BFB6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFE0BFB6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFAC3509)),
        ),
      );
}
