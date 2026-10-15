/// Pembungkus endpoint Kantin ITK API.
///
/// Setiap method mewakili satu operasi pada berkas OpenAPI dan sudah
/// mengembalikan model siap pakai, bukan JSON mentah.
library;

import 'api_client.dart';
import 'api_models.dart';

class KantinApi {
  KantinApi(this.client);

  final ApiClient client;

  // ----------------------------------------------------------------- umum

  /// Memastikan server hidup. Berguna untuk layar galat jaringan.
  Future<bool> health() async {
    try {
      final data = await client.get('/api/health');
      return data is Map && data['status'] == 'ok';
    } on ApiException {
      return false;
    }
  }

  // -------------------------------------------------------------- otentikasi

  /// Menukar `idToken` dari Google dengan kunci akses milik API.
  Future<ApiSession> loginWithGoogle(String idToken) async {
    final data = await client.post(
      '/api/auth/google',
      body: {'idToken': idToken},
    );
    return ApiSession.fromJson(mapFrom(data));
  }

  Future<ApiUser> me() async {
    final data = await client.get('/api/auth/me');
    final map = mapFrom(data);
    // Sebagian endpoint membungkus pengguna di dalam `user`.
    final raw = map['user'];
    return ApiUser.fromJson(
      raw is Map ? raw.cast<String, dynamic>() : map,
    );
  }

  Future<void> logout() => client.post('/api/auth/logout');

  /// [changes] menerima `name`, `profileImage`, dan `whatsapp`.
  /// Kirim `null` pada sebuah kolom untuk mengosongkannya.
  Future<ApiUser> updateProfile(Map<String, Object?> changes) async {
    final data = await client.patch('/api/users/me', body: changes);
    return ApiUser.fromJson(mapFrom(data));
  }

  /// Menyimpan profil secara utuh lewat `PUT /api/users/me`.
  ///
  /// Bedanya dengan [updateProfile] ada pada niatnya, bukan pada isi
  /// permintaan: PATCH dipakai saat satu kolom disentuh sendirian,
  /// sedangkan PUT dipakai saat seluruh isi formulir dikirim ulang
  /// sebagai satu kesatuan. Server menerima keduanya dengan bentuk badan
  /// yang sama.
  Future<ApiUser> replaceProfile(Map<String, Object?> profile) async {
    final data = await client.put('/api/users/me', body: profile);
    return ApiUser.fromJson(mapFrom(data));
  }

  /// Mengunggah berkas gambar sekaligus memasangnya sebagai foto profil.
  /// Satu panggilan, tidak perlu unggah lalu simpan terpisah.
  Future<ApiUser> uploadProfilePhoto(String filePath) async {
    final data = await client.upload('/api/users/me/photo', filePath);
    return ApiUser.fromJson(mapFrom(data));
  }

  /// Mengunggah gambar dan mengembalikan alamatnya, untuk dipasang pada
  /// `imageUrl` menu maupun kantin. JPG, PNG, atau WebP, maksimal 5 MB.
  Future<String> uploadImage(String filePath) async {
    final data = await client.upload('/api/uploads', filePath);
    return (mapFrom(data)['url'] ?? '') as String;
  }

  // ------------------------------------------------------------------ kantin

  Future<Paged<ApiCanteen>> canteens({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isOpen,
    String? sortBy,
    String? sortOrder,
  }) async {
    final data = await client.get('/api/canteens', query: {
      'page': page,
      'limit': limit,
      'search': search,
      'isOpen': isOpen?.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });
    return pagedFrom(data, ApiCanteen.fromJson);
  }

  Future<ApiCanteen> canteen(int id) async {
    final data = await client.get('/api/canteens/$id');
    return ApiCanteen.fromJson(mapFrom(data));
  }

  /// Mengambil kantin beserta menunya; balasannya membungkus keduanya dalam satu objek.
  ///
  /// [sortBy] sama dengan [menu], termasuk `popular`.
  Future<ApiCanteenMenu> canteenMenu(
    int id, {
    int page = 1,
    int limit = 50,
    String? sortBy,
    String? sortOrder,
  }) async {
    final data = await client.get('/api/canteens/$id/menu', query: {
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });
    return ApiCanteenMenu.fromJson(mapFrom(data));
  }

  // -------------------------------------------------------------------- menu

  /// [sortBy] menerima `name`, `price`, `createdAt`, atau `popular`.
  /// `popular` mengurutkan dari `soldCount` terbesar dan mengabaikan [sortOrder].
  Future<Paged<ApiMenuItem>> menu({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? canteenId,
    bool? isAvailable,
    String? sortBy,
    String? sortOrder,
  }) async {
    final data = await client.get('/api/menu', query: {
      'page': page,
      'limit': limit,
      'search': search,
      'categoryId': categoryId,
      'canteenId': canteenId,
      'isAvailable': isAvailable?.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });
    return pagedFrom(data, ApiMenuItem.fromJson);
  }

  Future<ApiMenuItem> menuItem(int id) async {
    final data = await client.get('/api/menu/$id');
    return ApiMenuItem.fromJson(mapFrom(data));
  }

  Future<List<ApiCategory>> categories() async {
    final data = await client.get('/api/categories');
    return pagedFrom(data, ApiCategory.fromJson).items;
  }

  // ----------------------------------------------------------------- favorit

  Future<List<ApiMenuItem>> favorites() async {
    final data = await client.get('/api/favorites');
    return pagedFrom(data, ApiMenuItem.fromJson).items;
  }

  Future<void> addFavorite(int menuItemId) =>
      client.post('/api/favorites', body: {'menuItemId': menuItemId});

  Future<void> removeFavorite(int menuItemId) =>
      client.delete('/api/favorites/$menuItemId');

  // --------------------------------------------------------------- keranjang

  Future<ApiCart> cart() async {
    final data = await client.get('/api/cart');
    return ApiCart.fromJson(mapFrom(data));
  }

  /// Menambahkan menu ke keranjang.
  ///
  /// Keranjang boleh memuat menu dari beberapa kantin sekaligus; server
  /// mengelompokkannya sendiri dan tiap kelompok menjadi satu pesanan.
  /// [note] adalah catatan khusus untuk menu ini saja; menambahkan menu
  /// yang sama dengan catatan baru akan menimpa catatan sebelumnya.
  Future<ApiCart> addToCart(
    int menuItemId, {
    int quantity = 1,
    String? note,
  }) async {
    final data = await client.post('/api/cart/items', body: {
      'menuItemId': menuItemId,
      'quantity': quantity,
      if (note != null) 'note': note.trim().isEmpty ? null : note.trim(),
    });
    return ApiCart.fromJson(mapFrom(data));
  }

  /// Mengubah jumlah satu baris keranjang. [cartItemId] adalah id baris,
  /// bukan id menu.
  Future<ApiCart> updateCartItem(
    int cartItemId, {
    int? quantity,
    String? note,
  }) async {
    final data = await client.patch(
      '/api/cart/items/$cartItemId',
      body: {
        if (quantity != null) 'quantity': quantity,
        if (note != null) 'note': note.trim().isEmpty ? null : note.trim(),
      },
    );
    return ApiCart.fromJson(mapFrom(data));
  }

  Future<ApiCart> removeCartItem(int cartItemId) async {
    final data = await client.delete('/api/cart/items/$cartItemId');
    return ApiCart.fromJson(mapFrom(data));
  }

  Future<void> clearCart() => client.delete('/api/cart');

  // ----------------------------------------------------------------- pesanan

  /// Mengubah isi keranjang menjadi pesanan.
  ///
  /// Server mengelompokkan isi keranjang menurut kantin asalnya, sehingga
  /// satu checkout bisa menghasilkan lebih dari satu pesanan. Karena itu
  /// hasilnya berupa daftar, bukan satu pesanan.
  Future<List<ApiOrder>> createOrder({String? note}) async {
    final data = await client.post(
      '/api/orders',
      body: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
    final raw = data is Map && data.containsKey('data') ? data['data'] : data;
    return ((raw as List?) ?? const [])
        .map((e) => ApiOrder.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// [scope] menerima `active`, `history`, atau `all`.
  Future<Paged<ApiOrder>> orders({
    int page = 1,
    int limit = 20,
    String scope = 'all',
    String? status,
  }) async {
    final data = await client.get('/api/orders', query: {
      'page': page,
      'limit': limit,
      'scope': scope,
      'status': status,
    });
    return pagedFrom(data, ApiOrder.fromJson);
  }

  Future<ApiOrder> order(int id) async {
    final data = await client.get('/api/orders/$id');
    return ApiOrder.fromJson(mapFrom(data));
  }

  Future<ApiOrder> cancelOrder(int id) async {
    final data = await client.patch('/api/orders/$id/cancel');
    return ApiOrder.fromJson(mapFrom(data));
  }
  // ------------------------------------------------------------------ penjual

  /// Ringkasan dasbor: kantin milik penjual, angka ringkas, dan pesanan
  /// terbaru. Bentuk `summary` dan `recentOrders` dibiarkan apa adanya
  /// karena API tidak memerincinya lebih jauh.
  Future<Map<String, dynamic>> sellerDashboard() async {
    final data = await client.get('/api/seller/dashboard');
    return mapFrom(data);
  }

  Future<ApiCanteen> myCanteen() async {
    final data = await client.get('/api/seller/canteen');
    return ApiCanteen.fromJson(mapFrom(data));
  }

  Future<ApiCanteen> createMyCanteen(Map<String, Object?> body) async {
    final data = await client.post('/api/seller/canteen', body: body);
    return ApiCanteen.fromJson(mapFrom(data));
  }

  Future<ApiCanteen> updateMyCanteen(Map<String, Object?> changes) async {
    final data = await client.patch('/api/seller/canteen', body: changes);
    return ApiCanteen.fromJson(mapFrom(data));
  }

  /// Mengunggah berkas gambar sekaligus memasangnya sebagai foto kantin.
  /// Cukup satu panggilan, tidak perlu unggah lalu simpan terpisah.
  Future<ApiCanteen> uploadCanteenPhoto(String filePath) async {
    final data = await client.upload('/api/seller/canteen/photo', filePath);
    return ApiCanteen.fromJson(mapFrom(data));
  }

  /// Mengambil kantin sendiri beserta menunya dalam satu balasan berbentuk objek.
  Future<ApiCanteenMenu> sellerMenu({
    int page = 1,
    int limit = 50,
  }) async {
    final data = await client.get('/api/seller/menu', query: {
      'page': page,
      'limit': limit,
    });
    return ApiCanteenMenu.fromJson(mapFrom(data));
  }

  Future<ApiMenuItem> sellerMenuItem(int id) async {
    final data = await client.get('/api/seller/menu/$id');
    return ApiMenuItem.fromJson(mapFrom(data));
  }

  /// [body] menerima name, description, price, categoryId, imageUrl,
  /// dan isAvailable. Hanya name dan price yang wajib.
  Future<ApiMenuItem> createMenu(Map<String, Object?> body) async {
    final data = await client.post('/api/seller/menu', body: body);
    return ApiMenuItem.fromJson(mapFrom(data));
  }

  Future<ApiMenuItem> updateMenu(int id, Map<String, Object?> changes) async {
    final data = await client.patch('/api/seller/menu/$id', body: changes);
    return ApiMenuItem.fromJson(mapFrom(data));
  }

  Future<void> deleteMenu(int id) => client.delete('/api/seller/menu/$id');

  /// Mengunggah berkas gambar sekaligus memasangnya sebagai foto menu.
  ///
  /// Menu milik penjual lain dijawab 404 oleh server, dan berkas yang
  /// terlanjur terunggah ikut dibuang di sisi server.
  Future<ApiMenuItem> uploadMenuPhoto(int id, String filePath) async {
    final data = await client.upload('/api/seller/menu/$id/photo', filePath);
    return ApiMenuItem.fromJson(mapFrom(data));
  }

  /// [scope] menerima `active` (masih berjalan), `history` (sudah selesai),
  /// atau `all`. [status] menyaring satu status saja, misalnya
  /// `menunggu_konfirmasi`.
  Future<Paged<ApiOrder>> sellerOrders({
    int page = 1,
    int limit = 20,
    String? scope,
    String? status,
  }) async {
    final data = await client.get('/api/seller/orders', query: {
      'page': page,
      'limit': limit,
      'scope': scope,
      'status': status,
    });
    return pagedFrom(data, ApiOrder.fromJson);
  }

  Future<ApiOrder> sellerOrder(int id) async {
    final data = await client.get('/api/seller/orders/$id');
    return ApiOrder.fromJson(mapFrom(data));
  }

  Future<ApiOrder> acceptOrder(int id) async {
    final data = await client.patch('/api/seller/orders/$id/accept');
    return ApiOrder.fromJson(mapFrom(data));
  }

  Future<ApiOrder> rejectOrder(int id, {String? reason}) async {
    final data = await client.patch(
      '/api/seller/orders/$id/reject',
      body: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
    );
    return ApiOrder.fromJson(mapFrom(data));
  }

  Future<ApiOrder> processOrder(int id) async {
    final data = await client.patch('/api/seller/orders/$id/process');
    return ApiOrder.fromJson(mapFrom(data));
  }

  Future<ApiOrder> markOrderReady(int id) async {
    final data = await client.patch('/api/seller/orders/$id/ready');
    return ApiOrder.fromJson(mapFrom(data));
  }

  Future<ApiOrder> completeOrder(int id) async {
    final data = await client.patch('/api/seller/orders/$id/complete');
    return ApiOrder.fromJson(mapFrom(data));
  }
  // ------------------------------------------------------------- notifikasi

  Future<Paged<ApiNotification>> notifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final data = await client.get('/api/notifications', query: {
      'page': page,
      'limit': limit,
      'unreadOnly': unreadOnly?.toString(),
    });
    return pagedFrom(data, ApiNotification.fromJson);
  }

  /// Jumlah notifikasi belum dibaca, untuk lencana pada ikon lonceng.
  Future<int> unreadNotificationCount() async {
    final data = await client.get('/api/notifications/unread-count');
    final map = mapFrom(data);
    final raw = map['unreadCount'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<void> markNotificationRead(int id) =>
      client.patch('/api/notifications/$id/read');

  Future<void> markAllNotificationsRead() =>
      client.patch('/api/notifications/read-all');

  /// Mendaftarkan token perangkat agar server tahu ke mana notifikasi
  /// dorong dikirim. Dipanggil ulang setiap Firebase memperbarui token.
  Future<void> registerDevice(String token, {String platform = 'android'}) =>
      client.post('/api/notifications/devices', body: {
        'token': token,
        'platform': platform,
      });

  /// Melepas perangkat, dipakai saat pengguna keluar.
  Future<void> unregisterDevice(String token) =>
      client.delete('/api/notifications/devices/$token');

  // -------------------------------------------------------------- statistik

  /// Ringkasan angka untuk halaman profil. Isinya menyesuaikan peran:
  /// pembeli mendapat jumlah favorit, penjual mendapat jumlah menu.
  Future<ApiProfileStats> profileStats() async {
    final data = await client.get('/api/users/me/stats');
    return ApiProfileStats.fromJson(mapFrom(data));
  }

  /// Menambah kategori menu, memakai ulang kategori yang namanya sudah ada.
  Future<ApiCategory> createCategory(String name) async {
    final data = await client.post('/api/categories', body: {'name': name});
    return ApiCategory.fromJson(mapFrom(data));
  }
}
