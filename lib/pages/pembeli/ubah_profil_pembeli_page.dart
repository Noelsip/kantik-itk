import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '/components/skeleton.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/state/session_state.dart';

/// Menyunting profil mahasiswa: nama, nomor WhatsApp, dan foto.
class UbahProfilPembeliPage extends StatefulWidget {
  const UbahProfilPembeliPage({super.key});

  static String routeName = 'UbahProfilPembeliPage';
  static String routePath = '/ubah-profil';

  @override
  State<UbahProfilPembeliPage> createState() =>
      _UbahProfilPembeliPageState();
}

class _UbahProfilPembeliPageState extends State<UbahProfilPembeliPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;

  bool _menyimpan = false;
  bool _mengunggah = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionState>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _whatsappController = TextEditingController(text: user?.whatsapp ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _pesan(String teks, {required bool galat}) {
    showToast(teks, galat: galat);
  }

  /// Mengirim seluruh isi formulir sekaligus lewat PUT lalu menutup halaman.
  Future<void> _simpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _menyimpan = true);

    final session = context.read<SessionState>();
    final navigator = Navigator.of(context);
    final whatsapp = _whatsappController.text.trim();
    final ok = await session.replaceProfile({
      'name': _nameController.text.trim(),
      'whatsapp': whatsapp.isEmpty ? null : whatsapp,
    });
    if (!mounted) return;
    setState(() => _menyimpan = false);

    if (!ok) {
      _pesan(session.error ?? 'Perubahan gagal disimpan', galat: true);
      return;
    }
    _pesan('Profil tersimpan.', galat: false);
    navigator.pop();
  }

  /// Mengosongkan nomor WhatsApp lewat PATCH tanpa menyentuh kolom lain.
  Future<void> _hapusWhatsapp() async {
    setState(() => _menyimpan = true);
    final session = context.read<SessionState>();
    final ok = await session.updateProfile(clearWhatsapp: true);
    if (!mounted) return;
    setState(() {
      _menyimpan = false;
      if (ok) _whatsappController.clear();
    });
    _pesan(
      ok ? 'Nomor WhatsApp dihapus.' : session.error ?? 'Gagal menghapus nomor',
      galat: !ok,
    );
  }

  /// Memilih gambar dari galeri lalu mengunggahnya sebagai foto profil.
  Future<void> _gantiFoto() async {
    final berkas = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (berkas == null || !mounted) return;

    setState(() => _mengunggah = true);
    final session = context.read<SessionState>();
    final ok = await session.uploadProfilePhoto(berkas.path);
    if (!mounted) return;
    setState(() => _mengunggah = false);
    _pesan(
      ok ? 'Foto profil diperbarui.' : session.error ?? 'Foto gagal diunggah',
      galat: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionState>().user;
    final sibuk = _menyimpan || _mengunggah;

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
            'Edit Profil',
            style: AppTheme.of(context).titleLarge.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 104.0,
                        height: 104.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFDBD0), width: 3.0),
                        ),
                        child: ClipOval(
                          child: (user?.profileImage?.isNotEmpty ?? false)
                              ? AppNetworkImage(
                                  imageUrl: user!.profileImage!,
                                  width: 98.0,
                                  height: 98.0,
                                  fallbackIcon: Icons.person,
                                )
                              : Container(
                                  color: const Color(0xFFFFDBD0),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.person,
                                      size: 44.0, color: Color(0xFFAC3509)),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0.0,
                        bottom: 0.0,
                        child: Material(
                          color: const Color(0xFFAC3509),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: sibuk ? null : _gantiFoto,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                _mengunggah
                                    ? Icons.hourglass_top
                                    : Icons.photo_camera,
                                size: 18.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28.0),
                _label(context, 'Nama lengkap'),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _nameController,
                  maxLength: 100,
                  decoration: _dekorasi('Nama sesuai data kampus'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12.0),
                _label(context, 'Nomor WhatsApp'),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: _dekorasi('Contoh: 081234567890'),
                  validator: (value) {
                    final teks = (value ?? '').trim();
                    if (teks.isEmpty) return null;
                    return RegExp(r'^(\+?62|0)8[0-9]{7,13}$').hasMatch(teks)
                        ? null
                        : 'Nomor tidak dikenali, gunakan awalan 08 atau 62';
                  },
                ),
                const SizedBox(height: 6.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: sibuk || (user?.whatsapp ?? '').isEmpty
                        ? null
                        : _hapusWhatsapp,
                    icon: const Icon(Icons.delete_outline, size: 18.0),
                    label: const Text('Hapus nomor WhatsApp'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFBA1A1A),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Nama fakultas, program studi, dan NIM diambil dari akun '
                  'kampus sehingga tidak bisa diubah di sini.',
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                        color: const Color(0xFF9A8C87),
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 24.0),
                FilledButton(
                  onPressed: sibuk ? null : _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFAC3509),
                    disabledBackgroundColor: const Color(0xFFD9BFB6),
                    minimumSize: const Size(double.infinity, 52.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    _menyimpan ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
