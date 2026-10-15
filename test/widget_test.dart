// Menguji pembacaan data dari bentuk JSON yang dikirim API.
//
// Contoh di bawah disalin dari `components/schemas` pada berkas OpenAPI,
// termasuk bagian yang baru: catatan per menu, nomor WhatsApp, dan
// keranjang yang dikelompokkan per kantin.
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_itk/api/api_models.dart';

void main() {
  group('pembacaan JSON', () {
    test('User membaca whatsapp dan peran', () {
      final u = ApiUser.fromJson(const {
        'id': 7,
        'name': 'Noel Ericson',
        'email': 'noel@student.itk.ac.id',
        'role': 'penjual',
        'roleLabel': 'Penjual',
        'whatsapp': '6281234567890',
        'faculty': 'Fakultas Sains dan Teknologi Informasi',
        'studyProgram': 'Informatika',
      });
      expect(u.whatsapp, '6281234567890');
      expect(u.isSeller, isTrue);
    });

    test('Canteen membaca whatsapp', () {
      final c = ApiCanteen.fromJson(const {
        'id': 1,
        'name': 'Kantin FSTI',
        'isOpen': true,
        'whatsapp': '6281211112222',
        'menuCount': 12,
      });
      expect(c.whatsapp, '6281211112222');
      expect(c.statusText, 'Buka');
    });

    test('CartItem membaca catatan per menu', () {
      final i = ApiCartItem.fromJson(const {
        'id': 3,
        'menuItemId': 9,
        'menuName': 'Nasi Goreng',
        'price': 15000,
        'quantity': 2,
        'subtotal': 30000,
        'isAvailable': true,
        'note': 'Pedas sedikit',
      });
      expect(i.note, 'Pedas sedikit');
      expect(i.subtotalLabel, 'Rp 30.000');
    });

    test('Cart mengelompokkan isi per kantin', () {
      final cart = ApiCart.fromJson(const {
        'id': 1,
        'items': [
          {
            'id': 1,
            'menuItemId': 9,
            'menuName': 'Nasi Goreng',
            'price': 15000,
            'quantity': 1,
            'subtotal': 15000,
            'isAvailable': true,
          },
          {
            'id': 2,
            'menuItemId': 12,
            'menuName': 'Es Teh',
            'price': 5000,
            'quantity': 1,
            'subtotal': 5000,
            'isAvailable': true,
          },
        ],
        'itemCount': 2,
        'totalQuantity': 2,
        'totalAmount': 20000,
        'canteenCount': 2,
        'canteens': [
          {
            'canteen': {'id': 1, 'name': 'Kantin FSTI', 'isOpen': true},
            'items': [
              {
                'id': 1,
                'menuItemId': 9,
                'menuName': 'Nasi Goreng',
                'price': 15000,
                'quantity': 1,
                'subtotal': 15000,
                'isAvailable': true,
              }
            ],
            'itemCount': 1,
            'totalQuantity': 1,
            'totalAmount': 15000,
          },
          {
            'canteen': {'id': 2, 'name': 'Kantin Teknik', 'isOpen': false},
            'items': [
              {
                'id': 2,
                'menuItemId': 12,
                'menuName': 'Es Teh',
                'price': 5000,
                'quantity': 1,
                'subtotal': 5000,
                'isAvailable': true,
              }
            ],
            'itemCount': 1,
            'totalQuantity': 1,
            'totalAmount': 5000,
          },
        ],
      });

      expect(cart.canteenCount, 2);
      expect(cart.isMixed, isTrue,
          reason: 'dua kantin berarti checkout menghasilkan dua pesanan');
      expect(cart.canteens.length, 2);
      expect(cart.canteens.first.canteenName, 'Kantin FSTI');
      expect(cart.canteens.last.canteenIsOpen, isFalse);
      expect(cart.quantityOf(9), 1);
      expect(cart.totalLabel, 'Rp 20.000');
    });

    test('Order membaca status dan catatan baris', () {
      final o = ApiOrder.fromJson(const {
        'id': 5,
        'orderNumber': 'ORD-2026-0005',
        'status': 'siap_diambil',
        'statusLabel': 'Siap Diambil',
        'isCancellable': false,
        'totalAmount': 20000,
        'itemCount': 1,
        'canteen': {'id': 1, 'name': 'Kantin FSTI'},
        'items': [
          {
            'id': 1,
            'menuItemId': 9,
            'menuName': 'Nasi Goreng',
            'price': 15000,
            'quantity': 1,
            'subtotal': 15000,
            'note': 'Tanpa sambal',
          }
        ],
      });
      expect(o.status, ApiOrderStatus.siapDiambil);
      expect(o.status.isFinished, isFalse);
      expect(o.items.first.note, 'Tanpa sambal');
      expect(o.stall, 'Kantin FSTI');
    });

    test('status yang tidak dikenal tidak membuat aplikasi jatuh', () {
      expect(ApiOrderStatus.parse('status_baru_dari_server'),
          ApiOrderStatus.menungguKonfirmasi);
      expect(ApiOrderStatus.parse(null), ApiOrderStatus.menungguKonfirmasi);
    });

    test('format rupiah', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(5000), 'Rp 5.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });
  });
}
