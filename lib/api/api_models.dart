/// Model data yang dikirim dan diterima dari Kantin ITK API.
///
/// Bentuknya mengikuti `components/schemas` pada berkas OpenAPI di
/// `https://api-kantinitk.noelsipayung.me/openapi.json`.
library;

/// Membaca angka yang bisa datang sebagai int maupun double dari JSON.
int _asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _asDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? _asDate(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// Memformat angka rupiah menjadi `Rp 15.000`.
String formatRupiah(num amount) {
  final digits = amount.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp $buffer';
}

// ---------------------------------------------------------------------------

class ApiUser {
  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.campusId,
    this.nim,
    this.roleLabel,
    this.profileImage,
    this.affiliation,
    this.faculty,
    this.studyProgram,
    this.whatsapp,
  });

  final int id;
  final String name;
  final String email;

  /// `pembeli` atau `penjual`.
  final String role;

  final String? campusId;
  final String? nim;
  final String? roleLabel;
  final String? profileImage;
  final String? affiliation;
  final String? faculty;
  final String? studyProgram;

  /// Nomor WhatsApp dalam bentuk baku berawalan 62 tanpa tanda tambah,
  /// siap dipakai pada tautan wa.me.
  final String? whatsapp;

  bool get isSeller => role == 'penjual';

  /// Baris kedua pada kartu profil, misalnya "Teknik - Informatika".
  String get subtitle {
    final parts = [faculty, studyProgram].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(' - ');
    return affiliation ?? roleLabel ?? email;
  }

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
        id: _asInt(j['id']),
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'pembeli') as String,
        campusId: j['campusId'] as String?,
        nim: j['nim'] as String?,
        roleLabel: j['roleLabel'] as String?,
        profileImage: j['profileImage'] as String?,
        affiliation: j['affiliation'] as String?,
        faculty: j['faculty'] as String?,
        studyProgram: j['studyProgram'] as String?,
        whatsapp: j['whatsapp'] as String?,
      );
}

class ApiSession {
  const ApiSession({
    required this.user,
    required this.accessToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
  });

  final ApiUser user;
  final String accessToken;
  final String tokenType;
  final String? expiresIn;

  factory ApiSession.fromJson(Map<String, dynamic> j) => ApiSession(
        user: ApiUser.fromJson((j['user'] as Map).cast<String, dynamic>()),
        accessToken: (j['accessToken'] ?? '') as String,
        tokenType: (j['tokenType'] ?? 'Bearer') as String,
        expiresIn: j['expiresIn']?.toString(),
      );
}

// ---------------------------------------------------------------------------

class ApiCanteen {
  const ApiCanteen({
    required this.id,
    required this.name,
    required this.isOpen,
    this.description,
    this.location,
    this.imageUrl,
    this.statusLabel,
    this.menuCount = 0,
    this.whatsapp,
  });

  final int id;
  final String name;
  final bool isOpen;
  final String? description;
  final String? location;
  final String? imageUrl;
  final String? statusLabel;
  final int menuCount;

  /// Nomor WhatsApp kantin, bentuk baku berawalan 62.
  final String? whatsapp;

  String get statusText => statusLabel ?? (isOpen ? 'Buka' : 'Tutup');

  factory ApiCanteen.fromJson(Map<String, dynamic> j) => ApiCanteen(
        id: _asInt(j['id']),
        name: (j['name'] ?? '') as String,
        isOpen: j['isOpen'] == true,
        description: j['description'] as String?,
        location: j['location'] as String?,
        imageUrl: j['imageUrl'] as String?,
        statusLabel: j['statusLabel'] as String?,
        menuCount: _asInt(j['menuCount']),
        whatsapp: j['whatsapp'] as String?,
      );
}

class ApiCategory {
  const ApiCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ApiCategory.fromJson(Map<String, dynamic> j) => ApiCategory(
        id: _asInt(j['id']),
        name: (j['name'] ?? '') as String,
      );
}

class ApiMenuItem {
  const ApiMenuItem({
    required this.id,
    required this.canteenId,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.isFavorite,
    this.canteenName,
    this.canteenIsOpen = true,
    this.category,
    this.description,
    this.imageUrl,
    this.soldCount,
  });

  final int id;
  final int canteenId;
  final String name;
  final double price;
  final bool isAvailable;
  final bool isFavorite;
  final String? canteenName;
  final bool canteenIsOpen;
  final ApiCategory? category;
  final String? description;
  final String? imageUrl;

  /// Menghitung porsi terjual dari pesanan yang tidak ditolak maupun dibatalkan.
  ///
  /// Hanya dikirim pada daftar menu, tidak pada detail menu, jadi bisa null.
  final int? soldCount;

  String get priceLabel => formatRupiah(price);

  String get stallName => canteenName ?? 'Kantin';

  /// Menu hanya bisa dipesan bila menunya tersedia dan kantinnya buka.
  bool get canOrder => isAvailable && canteenIsOpen;

  ApiMenuItem copyWith({bool? isFavorite}) => ApiMenuItem(
        id: id,
        canteenId: canteenId,
        name: name,
        price: price,
        isAvailable: isAvailable,
        isFavorite: isFavorite ?? this.isFavorite,
        canteenName: canteenName,
        canteenIsOpen: canteenIsOpen,
        category: category,
        description: description,
        imageUrl: imageUrl,
        soldCount: soldCount,
      );

  factory ApiMenuItem.fromJson(Map<String, dynamic> j) {
    final rawCategory = j['category'];
    return ApiMenuItem(
      id: _asInt(j['id']),
      canteenId: _asInt(j['canteenId']),
      name: (j['name'] ?? '') as String,
      price: _asDouble(j['price']),
      isAvailable: j['isAvailable'] != false,
      isFavorite: j['isFavorite'] == true,
      canteenName: j['canteenName'] as String?,
      canteenIsOpen: j['canteenIsOpen'] != false,
      category: rawCategory is Map
          ? ApiCategory.fromJson(rawCategory.cast<String, dynamic>())
          : null,
      description: j['description'] as String?,
      imageUrl: j['imageUrl'] as String?,
      soldCount: j['soldCount'] == null ? null : _asInt(j['soldCount']),
    );
  }
}

// ---------------------------------------------------------------------------

/// Menyatukan kantin beserta menunya, mengikuti bentuk balasan endpoint menu kantin.
///
/// Dua endpoint memakai bentuk ini: menu sebuah kantin untuk pembeli dan menu
/// kantin sendiri untuk penjual. Keduanya membungkus isinya, bukan mengirim
/// daftar lugas seperti endpoint daftar yang lain.
class ApiCanteenMenu {
  const ApiCanteenMenu({this.canteen, this.items = const []});

  final ApiCanteen? canteen;
  final List<ApiMenuItem> items;

  factory ApiCanteenMenu.fromJson(Map<String, dynamic> j) {
    final rawCanteen = j['canteen'];
    return ApiCanteenMenu(
      canteen: rawCanteen is Map
          ? ApiCanteen.fromJson(rawCanteen.cast<String, dynamic>())
          : null,
      items: ((j['menu'] as List?) ?? const [])
          .map((e) => ApiMenuItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ApiCartItem {
  const ApiCartItem({
    required this.id,
    required this.menuItemId,
    required this.menuName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.isAvailable,
    this.imageUrl,
    this.category,
    this.note,
  });

  /// Id baris keranjang, bukan id menu. Dipakai untuk ubah dan hapus.
  final int id;

  final int menuItemId;
  final String menuName;
  final double price;
  final int quantity;
  final double subtotal;
  final bool isAvailable;
  final String? imageUrl;
  final ApiCategory? category;

  /// Catatan khusus untuk menu ini saja, terpisah dari catatan pesanan.
  final String? note;

  String get priceLabel => formatRupiah(price);
  String get subtotalLabel => formatRupiah(subtotal);

  factory ApiCartItem.fromJson(Map<String, dynamic> j) {
    final rawCategory = j['category'];
    return ApiCartItem(
      id: _asInt(j['id']),
      menuItemId: _asInt(j['menuItemId']),
      menuName: (j['menuName'] ?? '') as String,
      price: _asDouble(j['price']),
      quantity: _asInt(j['quantity'], 1),
      subtotal: _asDouble(j['subtotal']),
      isAvailable: j['isAvailable'] != false,
      imageUrl: j['imageUrl'] as String?,
      category: rawCategory is Map
          ? ApiCategory.fromJson(rawCategory.cast<String, dynamic>())
          : null,
      note: j['note'] as String?,
    );
  }
}

/// Sekelompok isi keranjang yang berasal dari satu kantin.
///
/// Keranjang boleh memuat menu dari beberapa kantin sekaligus; tiap
/// kelompok inilah yang nanti menjadi satu pesanan tersendiri.
class ApiCartGroup {
  const ApiCartGroup({
    required this.canteenId,
    required this.canteenName,
    required this.canteenIsOpen,
    required this.items,
    required this.itemCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final int canteenId;
  final String canteenName;
  final bool canteenIsOpen;
  final List<ApiCartItem> items;
  final int itemCount;
  final int totalQuantity;
  final double totalAmount;

  String get totalLabel => formatRupiah(totalAmount);

  factory ApiCartGroup.fromJson(Map<String, dynamic> j) {
    final c = j['canteen'];
    final canteen = c is Map ? c.cast<String, dynamic>() : const {};
    return ApiCartGroup(
      canteenId: _asInt(canteen['id']),
      canteenName: (canteen['name'] as String?) ?? 'Kantin',
      canteenIsOpen: canteen['isOpen'] != false,
      items: ((j['items'] as List?) ?? const [])
          .map((e) => ApiCartItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      itemCount: _asInt(j['itemCount']),
      totalQuantity: _asInt(j['totalQuantity']),
      totalAmount: _asDouble(j['totalAmount']),
    );
  }
}

class ApiCart {
  const ApiCart({
    this.id,
    this.canteen,
    this.items = const [],
    this.itemCount = 0,
    this.totalQuantity = 0,
    this.totalAmount = 0,
    this.hasUnavailableItem = false,
    this.canteens = const [],
    this.canteenCount = 0,
  });

  final int? id;

  /// Keranjang hanya boleh berisi menu dari satu kantin. Nilainya null
  /// ketika keranjang masih kosong.
  final ApiCanteen? canteen;

  final List<ApiCartItem> items;
  final int itemCount;
  final int totalQuantity;
  final double totalAmount;
  final bool hasUnavailableItem;

  /// Isi keranjang dikelompokkan per kantin. Tiap kelompok menjadi satu
  /// pesanan tersendiri saat checkout.
  final List<ApiCartGroup> canteens;

  /// Banyaknya kantin pada keranjang, sekaligus jumlah pesanan yang akan
  /// terbentuk.
  final int canteenCount;

  bool get isEmpty => items.isEmpty;

  /// Keranjang memuat menu dari lebih dari satu kantin, sehingga checkout
  /// akan menghasilkan beberapa pesanan sekaligus.
  bool get isMixed => canteenCount > 1;

  String get totalLabel => formatRupiah(totalAmount);

  /// Jumlah satu menu di keranjang; nol bila belum ada.
  int quantityOf(int menuItemId) {
    for (final item in items) {
      if (item.menuItemId == menuItemId) return item.quantity;
    }
    return 0;
  }

  ApiCartItem? lineOf(int menuItemId) {
    for (final item in items) {
      if (item.menuItemId == menuItemId) return item;
    }
    return null;
  }

  factory ApiCart.fromJson(Map<String, dynamic> j) {
    final rawCanteen = j['canteen'];
    return ApiCart(
      id: j['id'] == null ? null : _asInt(j['id']),
      canteen: rawCanteen is Map
          ? ApiCanteen.fromJson(rawCanteen.cast<String, dynamic>())
          : null,
      items: ((j['items'] as List?) ?? const [])
          .map((e) => ApiCartItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      itemCount: _asInt(j['itemCount']),
      totalQuantity: _asInt(j['totalQuantity']),
      totalAmount: _asDouble(j['totalAmount']),
      hasUnavailableItem: j['hasUnavailableItem'] == true,
      canteens: ((j['canteens'] as List?) ?? const [])
          .map((e) => ApiCartGroup.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      canteenCount: _asInt(j['canteenCount']),
    );
  }
}

// ---------------------------------------------------------------------------

/// Status pesanan sesuai daftar pada API.
enum ApiOrderStatus {
  menungguKonfirmasi('menunggu_konfirmasi', 'Menunggu Konfirmasi'),
  diterima('diterima', 'Diterima'),
  ditolak('ditolak', 'Ditolak'),
  diproses('diproses', 'Diproses'),
  siapDiambil('siap_diambil', 'Siap Diambil'),
  selesai('selesai', 'Selesai'),
  dibatalkan('dibatalkan', 'Dibatalkan');

  const ApiOrderStatus(this.value, this.label);

  final String value;
  final String label;

  static ApiOrderStatus parse(String? raw) {
    for (final s in values) {
      if (s.value == raw) return s;
    }
    return menungguKonfirmasi;
  }

  /// Pesanan yang sudah tidak berjalan lagi.
  bool get isFinished =>
      this == selesai || this == dibatalkan || this == ditolak;
}

class ApiOrderItem {
  const ApiOrderItem({
    required this.id,
    required this.menuItemId,
    required this.menuName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.note,
  });

  final int id;
  final int menuItemId;
  final String menuName;
  final double price;
  final int quantity;
  final double subtotal;

  /// Catatan khusus untuk menu ini, disalin dari keranjang.
  final String? note;

  String get priceLabel => formatRupiah(price);
  String get subtotalLabel => formatRupiah(subtotal);

  factory ApiOrderItem.fromJson(Map<String, dynamic> j) => ApiOrderItem(
        id: _asInt(j['id']),
        menuItemId: _asInt(j['menuItemId']),
        menuName: (j['menuName'] ?? '') as String,
        price: _asDouble(j['price']),
        quantity: _asInt(j['quantity'], 1),
        subtotal: _asDouble(j['subtotal']),
        note: j['note'] as String?,
      );
}

class ApiOrder {
  const ApiOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.isCancellable,
    required this.totalAmount,
    required this.items,
    required this.itemCount,
    this.statusLabel,
    this.note,
    this.rejectReason,
    this.canteenName,
    this.createdAt,
    this.buyerName,
    this.buyerCampusId,
  });

  final int id;
  final String orderNumber;
  final ApiOrderStatus status;
  final bool isCancellable;
  final double totalAmount;
  final List<ApiOrderItem> items;
  final int itemCount;
  final String? statusLabel;
  final String? note;
  final String? rejectReason;
  final String? canteenName;
  final DateTime? createdAt;

  /// Identitas pemesan. Hanya terisi pada endpoint sisi penjual, agar
  /// penjual bisa mencocokkan saat pesanan diambil.
  final String? buyerName;
  final String? buyerCampusId;

  String get statusText => statusLabel ?? status.label;
  String get totalLabel => formatRupiah(totalAmount);
  String get stall => canteenName ?? 'Kantin';

  /// Menamai pesanan dari menunya agar lebih mudah dikenali daripada nomor pesanan.
  ///
  /// Hasilnya misalnya `Risol Mayo` atau `Risol Mayo +2 menu lainnya`;
  /// nomor pesanan baru dipakai bila rincian menunya tidak ikut terkirim.
  String get judul {
    if (items.isEmpty) return orderNumber;
    final pertama = items.first.menuName;
    return items.length == 1
        ? pertama
        : '$pertama +${items.length - 1} menu lainnya';
  }

  factory ApiOrder.fromJson(Map<String, dynamic> j) {
    final rawCanteen = j['canteen'];
    return ApiOrder(
      id: _asInt(j['id']),
      orderNumber: (j['orderNumber'] ?? '') as String,
      status: ApiOrderStatus.parse(j['status'] as String?),
      isCancellable: j['isCancellable'] == true,
      totalAmount: _asDouble(j['totalAmount']),
      items: ((j['items'] as List?) ?? const [])
          .map((e) => ApiOrderItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      itemCount: _asInt(j['itemCount']),
      statusLabel: j['statusLabel'] as String?,
      note: j['note'] as String?,
      rejectReason: j['rejectReason'] as String?,
      canteenName:
          rawCanteen is Map ? rawCanteen['name'] as String? : null,
      createdAt: _asDate(j['createdAt']),
      buyerName: j['buyer'] is Map ? j['buyer']['name'] as String? : null,
      buyerCampusId:
          j['buyer'] is Map ? j['buyer']['campusId'] as String? : null,
    );
  }
}

// ---------------------------------------------------------------------------

/// Halaman hasil beserta keterangan cacah datanya.
class Paged<T> {
  const Paged({
    required this.items,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasNextPage = false,
    this.unreadCount,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int total;
  final bool hasNextPage;

  /// Jumlah notifikasi belum dibaca; hanya dikirim oleh daftar notifikasi.
  final int? unreadCount;

  factory Paged.fromJson(
    List<dynamic> data,
    Map<String, dynamic>? meta,
    T Function(Map<String, dynamic>) parse,
  ) {
    return Paged<T>(
      items: data
          .map((e) => parse((e as Map).cast<String, dynamic>()))
          .toList(),
      page: _asInt(meta?['page'], 1),
      totalPages: _asInt(meta?['totalPages'], 1),
      total: _asInt(meta?['total']),
      hasNextPage: meta?['hasNextPage'] == true,
      unreadCount:
          meta?['unreadCount'] == null ? null : _asInt(meta!['unreadCount']),
    );
  }
}

// ---------------------------------------------------------------------------

/// Jenis notifikasi yang dikirim server.
enum ApiNotificationType {
  orderCreated('order_created'),
  orderStatusChanged('order_status_changed'),
  orderCancelled('order_cancelled'),
  lainnya('lainnya');

  const ApiNotificationType(this.value);

  final String value;

  static ApiNotificationType parse(String? raw) {
    for (final t in values) {
      if (t.value == raw) return t;
    }
    // Jenis baru dari server tidak boleh membuat aplikasi jatuh.
    return lainnya;
  }
}

class ApiNotification {
  const ApiNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.orderId,
    this.orderNumber,
    this.orderStatus,
    this.createdAt,
    this.readAt,
  });

  final int id;
  final ApiNotificationType type;
  final String title;
  final String body;
  final bool isRead;

  /// Pesanan yang dirujuk notifikasi ini, bila ada.
  final int? orderId;
  final String? orderNumber;
  final String? orderStatus;

  final DateTime? createdAt;
  final DateTime? readAt;

  factory ApiNotification.fromJson(Map<String, dynamic> j) {
    final order = j['order'];
    final o = order is Map ? order.cast<String, dynamic>() : null;
    return ApiNotification(
      id: _asInt(j['id']),
      type: ApiNotificationType.parse(j['type'] as String?),
      title: (j['title'] ?? '') as String,
      body: (j['body'] ?? '') as String,
      isRead: j['isRead'] == true,
      orderId: o == null ? null : _asInt(o['id']),
      orderNumber: o?['orderNumber'] as String?,
      orderStatus: o?['status'] as String?,
      createdAt: _asDate(j['createdAt']),
      readAt: _asDate(j['readAt']),
    );
  }
}

/// Ringkasan angka untuk kartu statistik di halaman profil.
class ApiProfileStats {
  const ApiProfileStats({
    required this.role,
    this.total = 0,
    this.active = 0,
    this.completed = 0,
    this.rejected = 0,
    this.cancelled = 0,
    this.history = 0,
    this.favoriteCount,
    this.menuCount,
  });

  final String role;

  /// Bagi pembeli dihitung dari pesanan miliknya, bagi penjual dari
  /// pesanan yang masuk ke kantinnya.
  final int total;
  final int active;
  final int completed;
  final int rejected;
  final int cancelled;
  final int history;

  /// Hanya terisi untuk pembeli.
  final int? favoriteCount;

  /// Hanya terisi untuk penjual.
  final int? menuCount;

  bool get isSeller => role == 'penjual';

  factory ApiProfileStats.fromJson(Map<String, dynamic> j) {
    final o = j['orders'];
    final orders = o is Map ? o.cast<String, dynamic>() : const {};
    return ApiProfileStats(
      role: (j['role'] ?? 'pembeli') as String,
      total: _asInt(orders['total']),
      active: _asInt(orders['active']),
      completed: _asInt(orders['completed']),
      rejected: _asInt(orders['rejected']),
      cancelled: _asInt(orders['cancelled']),
      history: _asInt(orders['history']),
      favoriteCount:
          j['favoriteCount'] == null ? null : _asInt(j['favoriteCount']),
      menuCount: j['menuCount'] == null ? null : _asInt(j['menuCount']),
    );
  }
}
