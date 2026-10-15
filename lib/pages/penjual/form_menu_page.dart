import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/components/async_view.dart';
import '/components/input_dialog.dart';
import '/components/menu_item_card.dart';
import '/components/app_toast.dart';
import '/core/app_theme.dart';
import '/state/app_state.dart';
import '/state/session_state.dart';

/// Menambah menu baru atau menyunting menu yang sudah ada beserta fotonya.
class FormMenuPage extends StatefulWidget {
  const FormMenuPage({super.key, this.menuId});

  /// Mengisi formulir dengan menu yang disunting; null berarti menu baru.
  final String? menuId;

  static String routeName = 'FormMenuPage';
  static String routePath = '/form-menu';

  @override
  State<FormMenuPage> createState() =>
      _FormMenuPageState();
}

class _FormMenuPageState extends State<FormMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  int? _categoryId;
  bool _tersedia = true;
  String? _imageUrl;
  bool _menyimpan = false;
  bool _mengunggah = false;

  int? get _menuId => int.tryParse(widget.menuId ?? '');

  bool get _menyunting => _menuId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Mengambil menu yang disunting sekaligus memuat kategori dari server.
  Future<ApiMenuItem?> _load() async {
    final api = context.read<SessionState>().api;
    final state = context.read<AppState>();
    await state.refreshCategories();
    final id = _menuId;
    if (id == null) return null;

    final item = await api.sellerMenuItem(id);
    _nameController.text = item.name;
    _descriptionController.text = item.description ?? '';
    _priceController.text = item.price.round().toString();
    _categoryId = item.category?.id;
    _tersedia = item.isAvailable;
    _imageUrl = item.imageUrl;
    return item;
  }

  void _pesan(String teks, {required bool galat}) {
    showToast(teks, galat: galat);
  }

  /// Menyimpan menu lewat POST untuk menu baru atau PATCH untuk menu lama.
  Future<void> _simpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _menyimpan = true);

    final api = context.read<SessionState>().api;
    final navigator = Navigator.of(context);
    final isi = <String, Object?>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'price': int.tryParse(_priceController.text.trim()) ?? 0,
      'categoryId': _categoryId,
      'isAvailable': _tersedia,
      if (_imageUrl != null && _imageUrl!.isNotEmpty) 'imageUrl': _imageUrl,
    };

    try {
      final id = _menuId;
      if (id == null) {
        await api.createMenu(isi);
      } else {
        await api.updateMenu(id, isi);
      }
      if (!mounted) return;
      _pesan(_menyunting ? 'Menu diperbarui.' : 'Menu ditambahkan.',
          galat: false);
      navigator.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      _pesan(e.message, galat: true);
    }
  }

  /// Mengunggah gambar ke server dan memakai alamat hasilnya sebagai foto menu.
  Future<void> _pilihFoto() async {
    final berkas = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (berkas == null || !mounted) return;

    setState(() => _mengunggah = true);
    final api = context.read<SessionState>().api;
    try {
      final id = _menuId;
      // Menu yang sudah ada memakai endpoint fotonya sendiri agar langsung terpasang.
      final url = id == null
          ? await api.uploadImage(berkas.path)
          : (await api.uploadMenuPhoto(id, berkas.path)).imageUrl;
      if (!mounted) return;
      setState(() => _imageUrl = url);
      _pesan('Foto terunggah.', galat: false);
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  /// Membuat kategori baru di server lalu memilihnya untuk menu ini.
  Future<void> _tambahKategori() async {
    final nama = await showInputDialog(
      context,
      judul: 'Kategori baru',
      petunjuk: 'Contoh: Snack',
      tombolSetuju: 'Simpan',
    );
    if (nama == null || nama.isEmpty || !mounted) return;

    final api = context.read<SessionState>().api;
    final state = context.read<AppState>();
    try {
      final kategori = await api.createCategory(nama);
      await state.refreshCategories();
      if (!mounted) return;
      setState(() => _categoryId = kategori.id);
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message, galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppState>().categories;
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
            _menyunting ? 'Ubah Menu' : 'Tambah Menu',
            style: AppTheme.of(context).titleLarge.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
        ),
        body: SafeArea(
          child: AsyncView<ApiMenuItem?>(
            load: _load,
            pullToRefresh: false,
            builder: (context, item, refresh) => Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
                children: [
                  _pemilihFoto(context),
                  const SizedBox(height: 24.0),
                  _label(context, 'Nama menu'),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 150,
                    decoration: _dekorasi('Contoh: Nasi Goreng Spesial'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Nama menu wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12.0),
                  _label(context, 'Harga'),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _dekorasi('Contoh: 15000'),
                    validator: (value) {
                      final harga = int.tryParse((value ?? '').trim());
                      if (harga == null) return 'Harga harus berupa angka';
                      if (harga < 0) return 'Harga tidak boleh negatif';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12.0),
                  _label(context, 'Kategori'),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _categoryId,
                          decoration: _dekorasi('Pilih kategori'),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Tanpa kategori'),
                            ),
                            for (final c in categories)
                              DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _categoryId = value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        tooltip: 'Kategori baru',
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFFAC3509)),
                        onPressed: sibuk ? null : _tambahKategori,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  _label(context, 'Keterangan'),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: _dekorasi('Bahan, porsi, atau tingkat pedas'),
                  ),
                  const SizedBox(height: 4.0),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _tersedia,
                    activeThumbColor: const Color(0xFFAC3509),
                    title: const Text('Tersedia untuk dipesan'),
                    subtitle: Text(
                      _tersedia
                          ? 'Menu tampil dan bisa dibeli.'
                          : 'Menu tetap tampil tetapi ditandai habis.',
                      style: const TextStyle(fontSize: 12.0),
                    ),
                    onChanged: (value) => setState(() => _tersedia = value),
                  ),
                  const SizedBox(height: 20.0),
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
                      _menyimpan
                          ? 'Menyimpan...'
                          : _menyunting
                              ? 'Simpan Perubahan'
                              : 'Tambahkan Menu',
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pemilihFoto(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: SizedBox(
              width: 160.0,
              height: 160.0,
              child: MenuFoto(url: _imageUrl, size: 160.0),
            ),
          ),
          const SizedBox(height: 10.0),
          TextButton.icon(
            onPressed: _mengunggah ? null : _pilihFoto,
            icon: Icon(
              _mengunggah ? Icons.hourglass_top : Icons.photo_camera_outlined,
              size: 18.0,
            ),
            label: Text(_mengunggah ? 'Mengunggah...' : 'Pilih Foto Menu'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFAC3509),
            ),
          ),
        ],
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
