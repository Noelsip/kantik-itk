import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/components/app_toast.dart';
import '/config/kontak_bantuan.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/pages/pages.dart';

/// Kerangka halaman informasi: app bar dengan tombol kembali dan isi yang
/// bisa digulir. Dipakai bersama oleh halaman Syarat & Ketentuan, Pusat
/// Bantuan dan Keamanan agar tampilannya seragam.
class _InfoScaffold extends StatelessWidget {
  const _InfoScaffold({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0.0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.goNamed(ProfilPembeliPage.routeName),
        ),
        title: Text(
          title,
          style: AppTheme.of(context).titleLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 32.0),
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: AppTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                        fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: const Color(0xFF59413A),
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 20.0),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Judul bagian bernomor beserta paragraf isinya.
class _Section extends StatelessWidget {
  const _Section({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26.0,
                height: 26.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDBD0),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Color(0xFFAC3509),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.0,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.of(context).titleMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: Text(
              body,
              style: AppTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                      fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: const Color(0xFF59413A),
                    letterSpacing: 0.0,
                    lineHeight: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu putih pembungkus sekelompok baris pengaturan.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Material dipakai agar riak sentuhan ListTile di dalamnya tetap
    // terlihat; dekorasi Container akan menutupinya.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Color(0xFFEAE7E7)),
        ),
        child: Column(children: children),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Syarat & Ketentuan
// ---------------------------------------------------------------------------

class SyaratKetentuanPage extends StatelessWidget {
  const SyaratKetentuanPage({super.key});

  static String routeName = 'SyaratKetentuanPage';
  static String routePath = '/syarat-ketentuan';

  @override
  Widget build(BuildContext context) {
    return const _InfoScaffold(
      title: 'Syarat & Ketentuan',
      subtitle: 'Berlaku mulai 1 September 2026. Dengan menggunakan aplikasi '
          'Kantin ITK, kamu dianggap telah membaca dan menyetujui ketentuan '
          'berikut.',
      children: [
        _Section(
          number: 1,
          title: 'Penggunaan Akun',
          body: 'Akun Kantin ITK hanya boleh digunakan oleh mahasiswa, dosen, '
              'dan tenaga kependidikan yang terdaftar di Institut Teknologi '
              'Kalimantan. Kamu bertanggung jawab menjaga kerahasiaan kata '
              'sandi dan seluruh aktivitas yang terjadi pada akunmu.',
        ),
        _Section(
          number: 2,
          title: 'Pemesanan',
          body: 'Pesanan yang sudah dikonfirmasi kantin akan langsung '
              'diproses. Pastikan menu, jumlah, dan catatan pesanan sudah '
              'benar sebelum melanjutkan ke checkout. Ketersediaan menu '
              'mengikuti stok yang dimiliki masing-masing kantin.',
        ),
        _Section(
          number: 3,
          title: 'Pembayaran',
          body: 'Pembayaran dilakukan secara tunai saat pengambilan pesanan '
              'atau melalui metode lain yang disediakan kantin. Tidak ada '
              'biaya tambahan di luar harga menu yang tertera.',
        ),
        _Section(
          number: 4,
          title: 'Pembatalan',
          body: 'Pesanan dapat dibatalkan selama statusnya masih "Menunggu '
              'Konfirmasi" atau "Sedang Diproses". Setelah pesanan berstatus '
              '"Siap Diambil", pembatalan tidak dapat dilakukan karena '
              'makanan sudah selesai disiapkan.',
        ),
        _Section(
          number: 5,
          title: 'Pengambilan Pesanan',
          body: 'Pesanan diambil langsung di kantin terkait dengan '
              'menunjukkan nomor pesanan. Pesanan yang tidak diambil dalam '
              '60 menit setelah berstatus siap dapat dibatalkan sepihak oleh '
              'kantin.',
        ),
        _Section(
          number: 6,
          title: 'Perilaku Pengguna',
          body: 'Dilarang menyalahgunakan aplikasi untuk pemesanan palsu, '
              'penyalahgunaan akun orang lain, atau tindakan yang merugikan '
              'kantin maupun pengguna lain. Pelanggaran dapat berakibat pada '
              'penangguhan akun.',
        ),
        _Section(
          number: 7,
          title: 'Perubahan Ketentuan',
          body: 'Pengelola dapat memperbarui syarat dan ketentuan ini '
              'sewaktu-waktu. Perubahan akan diumumkan melalui notifikasi '
              'dalam aplikasi sebelum mulai berlaku.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pusat Bantuan
// ---------------------------------------------------------------------------

class PusatBantuanPage extends StatefulWidget {
  const PusatBantuanPage({super.key});

  static String routeName = 'PusatBantuanPage';
  static String routePath = '/pusat-bantuan';

  @override
  State<PusatBantuanPage> createState() => _PusatBantuanPageState();
}

class _PusatBantuanPageState extends State<PusatBantuanPage> {
  static const List<({String question, String answer})> _faq = [
    (
      question: 'Bagaimana cara memesan makanan?',
      answer: 'Pilih menu dari beranda atau halaman kantin, tekan tombol '
          'tambah untuk memasukkannya ke keranjang, lalu buka keranjang dan '
          'tekan "Lanjutkan ke Checkout".',
    ),
    (
      question: 'Bisakah saya membatalkan pesanan?',
      answer: 'Bisa, selama status pesanan masih "Menunggu Konfirmasi" atau '
          '"Sedang Diproses". Buka halaman Pesanan, pilih pesananmu, lalu '
          'tekan "Batalkan Pesanan".',
    ),
    (
      question: 'Bagaimana cara mengubah jumlah menu?',
      answer: 'Di keranjang, gunakan tombol tambah dan kurang, atau ketuk '
          'angkanya untuk mengetik jumlah secara langsung.',
    ),
    (
      question: 'Menu yang saya cari tidak muncul.',
      answer: 'Coba hapus kata kunci pencarian atau lepas filter kategori. '
          'Menu juga bisa sedang tidak tersedia bila kantinnya tutup.',
    ),
    (
      question: 'Bagaimana cara menyimpan menu favorit?',
      answer: 'Tekan ikon hati pada kartu menu. Menu favorit bisa dilihat '
          'kembali dari halaman profil.',
    ),
    (
      question: 'Berapa lama pesanan saya siap?',
      answer: 'Umumnya 10 sampai 20 menit tergantung antrean kantin. Kamu '
          'akan menerima notifikasi saat pesanan siap diambil.',
    ),
  ];

  int? _openIndex;

  void _showContactSheet(String channel, String detail) {
    showToast('$channel: $detail');
  }

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Pusat Bantuan',
      subtitle: 'Temukan jawaban cepat di bawah ini, atau hubungi tim kami '
          'bila masalahmu belum terjawab.',
      children: [
        Text(
          'Pertanyaan yang Sering Diajukan',
          style: AppTheme.of(context).titleMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: const Color(0xFF1B1C1C),
                letterSpacing: 0.0,
              ),
        ),
        const SizedBox(height: 12.0),
        for (var i = 0; i < _faq.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: const BorderSide(color: Color(0xFFEAE7E7)),
              ),
              child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: PageStorageKey('faq$i'),
                initiallyExpanded: _openIndex == i,
                onExpansionChanged: (open) =>
                    setState(() => _openIndex = open ? i : null),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16.0),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                iconColor: const Color(0xFFAC3509),
                collapsedIconColor: const Color(0xFF59413A),
                title: Text(
                  _faq[i].question,
                  style: AppTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _faq[i].answer,
                      style: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight:
                                  AppTheme.of(context).bodyMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: const Color(0xFF59413A),
                            letterSpacing: 0.0,
                            lineHeight: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (KontakBantuan.adaIsinya) ...[
          const SizedBox(height: 20.0),
          Text(
            'Masih Butuh Bantuan?',
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: const Color(0xFF1B1C1C),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 12.0),
          _Card(children: _daftarKontak()),
        ],
      ],
    );
  }

  /// Menyusun baris kontak yang terisi saja, dipisahkan garis antar baris.
  List<Widget> _daftarKontak() {
    final baris = <Widget>[
      if (KontakBantuan.email.isNotEmpty)
        _contactTile(
          Icons.mail_outline,
          'Email',
          KontakBantuan.email,
          () => _showContactSheet('Email', KontakBantuan.email),
        ),
      if (KontakBantuan.whatsapp.isNotEmpty)
        _contactTile(
          Icons.chat_bubble_outline,
          'WhatsApp',
          KontakBantuan.whatsapp,
          () => _showContactSheet('WhatsApp', KontakBantuan.whatsapp),
        ),
      if (KontakBantuan.alamat.isNotEmpty)
        _contactTile(
          Icons.location_on_outlined,
          'Kunjungi Sekretariat',
          KontakBantuan.alamat,
          () => _showContactSheet('Alamat', KontakBantuan.alamat),
        ),
    ];
    return [
      for (var i = 0; i < baris.length; i++) ...[
        baris[i],
        if (i != baris.length - 1) const Divider(height: 1.0, indent: 64.0),
      ],
    ];
  }

  Widget _contactTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        width: 40.0,
        height: 40.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFDBD0),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Icon(icon, color: const Color(0xFFAC3509), size: 20.0),
      ),
      title: Text(
        title,
        style: AppTheme.of(context).bodyLarge.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w500),
              color: const Color(0xFF1B1C1C),
              letterSpacing: 0.0,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.of(context).bodySmall.override(
              font: GoogleFonts.inter(
                fontWeight: AppTheme.of(context).bodySmall.fontWeight,
                fontStyle: AppTheme.of(context).bodySmall.fontStyle,
              ),
              color: const Color(0xFF59413A),
              letterSpacing: 0.0,
            ),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: Color(0xFF9A8C87), size: 20.0),
    );
  }
}
