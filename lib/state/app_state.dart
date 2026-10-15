import 'package:flutter/foundation.dart';

import '/api/api_client.dart';
import '/api/api_models.dart';
import '/api/kantin_api.dart';
import 'session_state.dart';

/// Membatasi jumlah satu menu dalam keranjang, mengikuti aturan API.
const int kMaxQuantity = 99;

/// Menyimpan salinan keranjang, pesanan, favorit, dan kategori milik pengguna yang sedang masuk.
///
/// Mengirim setiap perubahan ke API lebih dulu, lalu memperbarui salinan dari balasannya.
class AppState extends ChangeNotifier {
  AppState(this._session);

  SessionState _session;

  KantinApi get _api => _session.api;

  ApiCart? _cart;
  List<ApiOrder> _orders = const [];
  List<ApiMenuItem> _favorites = const [];
  List<ApiCategory> _categories = const [];

  /// Menandai pemilik salinan saat ini untuk mengenali pergantian akun.
  int? _userId;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;

  /// Menyimpan pesan galat terakhir yang siap ditampilkan.
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  List<ApiCartItem> get cart => _cart?.items ?? const [];

  /// Mengelompokkan isi keranjang per kantin; tiap kelompok menjadi satu pesanan saat checkout.
  List<ApiCartGroup> get cartGroups => _cart?.canteens ?? const [];

  bool get isCartEmpty => cart.isEmpty;

  /// Menghitung seluruh item, bukan jumlah baris.
  int get cartCount => _cart?.totalQuantity ?? 0;

  double get total => _cart?.totalAmount ?? 0;

  String get totalLabel => formatRupiah(total);

  /// Menandai keranjang memuat lebih dari satu kantin, sehingga checkout memecah pesanan.
  bool get cartIsMixed => _cart?.isMixed ?? false;

  bool get cartHasUnavailable => _cart?.hasUnavailableItem ?? false;

  int quantityOf(int menuItemId) => _cart?.quantityOf(menuItemId) ?? 0;

  bool contains(int menuItemId) => quantityOf(menuItemId) > 0;

  ApiCartItem? cartLineOf(int menuItemId) => _cart?.lineOf(menuItemId);

  List<ApiOrder> get orders => _orders;

  /// Menyaring pesanan yang masih berjalan, terbaru lebih dulu.
  List<ApiOrder> get activeOrders =>
      _orders.where((o) => !o.status.isFinished).toList();

  /// Menyaring pesanan yang sudah selesai, ditolak, atau dibatalkan.
  List<ApiOrder> get finishedOrders =>
      _orders.where((o) => o.status.isFinished).toList();

  ApiOrder? orderById(int? id) {
    if (id == null) return null;
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  List<ApiMenuItem> get favoriteMenus => _favorites;

  bool isFavorite(int menuItemId) => _favorites.any((m) => m.id == menuItemId);

  List<ApiCategory> get categories => _categories;

  ApiCategory? categoryByName(String name) {
    final target = name.trim().toLowerCase();
    for (final c in _categories) {
      if (c.name.trim().toLowerCase() == target) return c;
    }
    return null;
  }

  /// Menyelaraskan isi dengan sesi aktif, memuat ulang hanya saat penggunanya berganti.
  void syncWith(SessionState session) {
    _session = session;
    final id = session.isLoggedIn ? session.user!.id : null;
    if (id == _userId) return;
    _userId = id;
    if (id == null) {
      _cart = null;
      _orders = const [];
      _favorites = const [];
      _error = null;
    } else {
      // Memuat tanpa await karena pemanggilnya build; mengumumkan hasilnya lewat notifyListeners.
      refreshAll();
    }
  }

  /// Memuat ulang keranjang, pesanan, favorit, dan kategori sekaligus.
  Future<void> refreshAll() async {
    _loading = true;
    notifyListeners();
    await Future.wait([
      _pull(() async => _cart = await _api.cart()),
      _pull(() async => _orders = (await _api.orders(limit: 50)).items),
      _pull(() async => _favorites = await _api.favorites()),
      _pull(() async => _categories = await _api.categories()),
    ]);
    _loading = false;
    notifyListeners();
  }

  /// Menjalankan pemuatan yang boleh gagal sendiri tanpa menggugurkan pemuatan lain.
  Future<void> _pull(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
    }
  }

  /// Menjalankan satu perubahan, mengumumkan hasilnya, dan menyimpan galatnya.
  Future<bool> _run(Future<void> Function() action) async {
    _error = null;
    try {
      await action();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCart() => _run(() async => _cart = await _api.cart());

  /// Menambah menu ke keranjang; jumlah menu yang sudah ada ditambah oleh server.
  Future<bool> addToCart(
    int menuItemId, {
    int quantity = 1,
    String? note,
  }) =>
      _run(() async {
        _cart = await _api.addToCart(
          menuItemId,
          quantity: quantity.clamp(1, kMaxQuantity),
          note: note,
        );
      });

  /// Mengubah jumlah satu baris keranjang; nilai nol atau kurang menghapus barisnya.
  Future<bool> setCartQuantity(int cartItemId, int quantity) {
    if (quantity <= 0) return removeCartItem(cartItemId);
    return _run(() async {
      _cart = await _api.updateCartItem(
        cartItemId,
        quantity: quantity.clamp(1, kMaxQuantity),
      );
    });
  }

  Future<bool> setCartNote(int cartItemId, String? note) => _run(() async {
        _cart = await _api.updateCartItem(cartItemId, note: note ?? '');
      });

  Future<bool> removeCartItem(int cartItemId) => _run(() async {
        _cart = await _api.removeCartItem(cartItemId);
      });

  Future<bool> clearCart() => _run(() async {
        await _api.clearCart();
        _cart = await _api.cart();
      });

  Future<void> refreshOrders() =>
      _run(() async => _orders = (await _api.orders(limit: 50)).items);

  /// Mengubah keranjang menjadi pesanan; hasilnya berupa daftar karena dipecah per kantin.
  Future<List<ApiOrder>?> placeOrder({String? note}) async {
    _error = null;
    try {
      final created = await _api.createOrder(note: note);
      _cart = await _api.cart();
      _orders = (await _api.orders(limit: 50)).items;
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _error = e.message;
      // Keranjang tetap utuh saat checkout ditolak; memuatnya ulang menampilkan
      // menu yang habis, terhapus, atau kantinnya tutup.
      if (_kodeKeranjangBerubah.contains(e.code)) {
        await _pull(() async => _cart = await _api.cart());
        _error = e.message;
      }
      notifyListeners();
      return null;
    }
  }

  /// Kode galat `CheckoutFailed` yang berarti isi keranjang di server sudah berubah.
  static const _kodeKeranjangBerubah = {
    'MENU_UNAVAILABLE',
    'MENU_NOT_FOUND',
    'CANTEEN_CLOSED',
    'CART_EMPTY',
  };

  Future<bool> cancelOrder(int id) => _run(() async {
        final updated = await _api.cancelOrder(id);
        _orders = [
          for (final o in _orders) if (o.id == updated.id) updated else o,
        ];
      });

  /// Mengambil ulang satu pesanan agar halaman status tidak perlu memuat seluruh daftar.
  Future<ApiOrder?> reloadOrder(int id) async {
    _error = null;
    try {
      final order = await _api.order(id);
      _orders = [
        for (final o in _orders) if (o.id == order.id) order else o,
      ];
      notifyListeners();
      return order;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshFavorites() =>
      _run(() async => _favorites = await _api.favorites());

  Future<bool> toggleFavorite(int menuItemId) => _run(() async {
        if (isFavorite(menuItemId)) {
          await _api.removeFavorite(menuItemId);
        } else {
          await _api.addFavorite(menuItemId);
        }
        _favorites = await _api.favorites();
      });

  Future<void> refreshCategories() =>
      _run(() async => _categories = await _api.categories());
}
