/// Menyimpan satu kantin yang dikenal aplikasi untuk mengisi cepat formulir kantin penjual.
class KantinTerdaftar {
  const KantinTerdaftar({
    required this.nama,
    this.emailPenjual,
    this.lokasi,
    this.deskripsi,
    this.whatsapp,
    this.fotoUrl,
  });

  /// Menamai kantin, paling panjang 100 karakter.
  final String nama;

  /// Menunjuk penjual pemiliknya; null berarti entri ini boleh diambil penjual mana pun.
  final String? emailPenjual;

  /// Menyebut letak kantin, misalnya `Gedung FTI, Lt. 1`.
  final String? lokasi;

  final String? deskripsi;

  /// Menyimpan nomor WhatsApp; penulisan 08xx, 62xx, atau +62xx dibakukan server.
  final String? whatsapp;

  /// Menunjuk alamat foto; biasanya null karena penjual mengunggah fotonya sendiri.
  final String? fotoUrl;

  /// Menyusun badan permintaan `POST /api/seller/canteen` tanpa menyertakan kolom kosong.
  Map<String, Object?> toBody() => {
        'name': nama,
        if (lokasi != null && lokasi!.isNotEmpty) 'location': lokasi,
        if (deskripsi != null && deskripsi!.isNotEmpty) 'description': deskripsi,
        if (whatsapp != null && whatsapp!.isNotEmpty) 'whatsapp': whatsapp,
        if (fotoUrl != null && fotoUrl!.isNotEmpty) 'imageUrl': fotoUrl,
        'isOpen': true,
      };
}

/// Mendaftarkan kantin kampus yang isian awalnya ingin disiapkan tanpa panel admin.
///
/// Membiarkannya kosong tetap aman: penjual mengisi sendiri formulir di Pengaturan
/// Warung. Menambah entri di sini hanya menyediakan tombol isi cepat untuk formulir itu.
const List<KantinTerdaftar> kKantinTerdaftar = [];

/// Mencari entri yang ditujukan untuk surel tertentu, null bila tidak ada.
KantinTerdaftar? kantinUntukPenjual(String email) {
  final target = email.trim().toLowerCase();
  if (target.isEmpty) return null;
  for (final kantin in kKantinTerdaftar) {
    if (kantin.emailPenjual?.trim().toLowerCase() == target) return kantin;
  }
  return null;
}
