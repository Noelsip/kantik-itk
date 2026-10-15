/// Menyimpan kontak pengelola yang tampil pada Pusat Bantuan.
///
/// Nilai kosong menyembunyikan barisnya, jadi halaman tidak pernah menampilkan
/// kontak yang belum tentu bisa dihubungi.
class KontakBantuan {
  const KontakBantuan._();

  /// Alamat surel pengelola aplikasi.
  static const String email = '';

  /// Nomor WhatsApp pengelola, ditulis apa adanya untuk ditampilkan.
  static const String whatsapp = '';

  /// Letak sekretariat atau tempat bertanya langsung.
  static const String alamat = '';

  /// Menyatakan ada setidaknya satu kontak yang bisa ditampilkan.
  static bool get adaIsinya =>
      email.isNotEmpty || whatsapp.isNotEmpty || alamat.isNotEmpty;
}
