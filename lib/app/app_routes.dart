/// Rute app (SPEC §3) sebagai tipe, satu pengurai [parseAppRoute], dan
/// pembuat jalur [AppRoutes]. Murni Dart: dipakai navigator, URL web, deep
/// link OneLink, dan muatan notifikasi.
library;

/// Tab navigasi bawah.
enum AppTab { home, catalog, rewards, orders, account }

/// Satu tujuan di dalam app.
sealed class AppRoute {
  const AppRoute();

  /// Lokasi kanonik, contoh `/produk/P39A06S01000021`.
  String get location;

  /// Tab yang menampilkan rute ini sebagai akar, atau null untuk halaman
  /// yang ditumpuk di atas kerangka.
  AppTab? get tab => null;

  /// Apakah tamu harus masuk dulu sebelum membuka rute ini.
  bool get requiresLogin => false;

  @override
  bool operator ==(Object other) =>
      other is AppRoute &&
      other.runtimeType == runtimeType &&
      other.location == location;

  @override
  int get hashCode => Object.hash(runtimeType, location);

  @override
  String toString() => '$runtimeType($location)';
}

/// `/` Beranda.
final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  String get location => '/';

  @override
  AppTab get tab => AppTab.home;
}

/// `/katalog` dengan filter opsional
/// (`?kategori=&brand=&q=&urut=&min=&maks=`).
final class CatalogRoute extends AppRoute {
  const CatalogRoute({
    this.category,
    this.brands = const <String>[],
    this.query,
    this.sort,
    this.minPrice,
    this.maxPrice,
  });

  /// ID kategori.
  final String? category;

  /// Nama brand terpilih.
  final List<String> brands;

  /// Teks cari.
  final String? query;

  /// Nilai `CatalogSort.param`.
  final String? sort;

  /// Harga minimum (rupiah).
  final int? minPrice;

  /// Harga maksimum (rupiah).
  final int? maxPrice;

  @override
  String get location => _withQuery('/katalog', <String, String?>{
    'kategori': category,
    'brand': brands.isEmpty ? null : brands.join(','),
    'q': query,
    'urut': sort,
    'min': minPrice?.toString(),
    'maks': maxPrice?.toString(),
  });

  @override
  AppTab get tab => AppTab.catalog;
}

/// `/cari` layar cari (riwayat dan saran).
final class SearchRoute extends AppRoute {
  const SearchRoute({this.query});

  /// Teks awal di kolom cari.
  final String? query;

  @override
  String get location => _withQuery('/cari', <String, String?>{'q': query});
}

/// `/produk/:kode` detail produk.
final class ProductRoute extends AppRoute {
  const ProductRoute(this.code);

  /// Kode produk katalog.
  final String code;

  @override
  String get location => '/produk/${Uri.encodeComponent(code)}';
}

/// `/hot-item` daftar Hot Item.
final class HotItemsRoute extends AppRoute {
  const HotItemsRoute();

  @override
  String get location => '/hot-item';
}

/// `/event` hub Event Promo.
final class EventHubRoute extends AppRoute {
  const EventHubRoute();

  @override
  String get location => '/event';
}

/// `/event/:id` halaman event.
final class EventRoute extends AppRoute {
  const EventRoute(this.id);

  /// ID event di `promo.json`.
  final String id;

  @override
  String get location => '/event/${Uri.encodeComponent(id)}';
}

/// `/wishlist` produk favorit.
final class WishlistRoute extends AppRoute {
  const WishlistRoute();

  @override
  String get location => '/wishlist';
}

/// `/keranjang`.
final class CartRoute extends AppRoute {
  const CartRoute();

  @override
  String get location => '/keranjang';
}

/// `/checkout`.
final class CheckoutRoute extends AppRoute {
  const CheckoutRoute();

  @override
  String get location => '/checkout';

  @override
  bool get requiresLogin => true;
}

/// `/bayar/:orderId` pembayaran (simulasi).
final class PaymentRoute extends AppRoute {
  const PaymentRoute(this.orderId);

  /// Nomor pesanan.
  final String orderId;

  @override
  String get location => '/bayar/${Uri.encodeComponent(orderId)}';

  @override
  bool get requiresLogin => true;
}

/// `/pesanan` Transaksi, dengan tab status opsional (`?status=`).
final class OrdersRoute extends AppRoute {
  const OrdersRoute({this.status});

  /// Nilai `OrderStatus.param`; null = semua.
  final String? status;

  @override
  String get location =>
      _withQuery('/pesanan', <String, String?>{'status': status});

  @override
  AppTab get tab => AppTab.orders;
}

/// `/pesanan/:id` detail pesanan.
final class OrderDetailRoute extends AppRoute {
  const OrderDetailRoute(this.orderId);

  /// Nomor pesanan.
  final String orderId;

  @override
  String get location => '/pesanan/${Uri.encodeComponent(orderId)}';

  @override
  bool get requiresLogin => true;
}

/// `/pesanan/:id/sukses` layar sukses setelah pesanan dibuat atau dibayar.
final class OrderSuccessRoute extends AppRoute {
  const OrderSuccessRoute(this.orderId);

  /// Nomor pesanan.
  final String orderId;

  @override
  String get location => '/pesanan/${Uri.encodeComponent(orderId)}/sukses';

  @override
  bool get requiresLogin => true;
}

/// `/notifikasi` kotak masuk.
final class InboxRoute extends AppRoute {
  const InboxRoute();

  @override
  String get location => '/notifikasi';

  @override
  bool get requiresLogin => true;
}

/// `/akun`.
final class AccountRoute extends AppRoute {
  const AccountRoute();

  @override
  String get location => '/akun';

  @override
  AppTab get tab => AppTab.account;
}

/// `/akun/profil`.
final class ProfileRoute extends AppRoute {
  const ProfileRoute();

  @override
  String get location => '/akun/profil';

  @override
  bool get requiresLogin => true;
}

/// `/akun/sandi` ubah kata sandi dengan OTP (demo).
final class ChangePasswordRoute extends AppRoute {
  const ChangePasswordRoute();

  @override
  String get location => '/akun/sandi';

  @override
  bool get requiresLogin => true;
}

/// `/akun/alamat` buku alamat. [selecting] true saat dibuka dari checkout
/// untuk memilih alamat kirim.
final class AddressesRoute extends AppRoute {
  const AddressesRoute({this.selecting = false});

  /// Mode pilih alamat.
  final bool selecting;

  @override
  String get location => _withQuery('/akun/alamat', <String, String?>{
    'pilih': selecting ? '1' : null,
  });

  @override
  bool get requiresLogin => true;
}

/// `/akun/alamat/baru` atau `/akun/alamat/:id` formulir alamat.
final class AddressFormRoute extends AppRoute {
  const AddressFormRoute({this.addressId});

  /// Alamat yang diubah; null = alamat baru.
  final String? addressId;

  @override
  String get location => addressId == null
      ? '/akun/alamat/baru'
      : '/akun/alamat/${Uri.encodeComponent(addressId!)}';

  @override
  bool get requiresLogin => true;
}

/// `/akun/pengaturan`.
final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  String get location => '/akun/pengaturan';
}

/// `/masuk`. [next] adalah lokasi yang dibuka setelah berhasil masuk.
final class LoginRoute extends AppRoute {
  const LoginRoute({this.next});

  /// Lokasi tujuan setelah masuk (`?lanjut=`).
  final String? next;

  @override
  String get location =>
      _withQuery('/masuk', <String, String?>{'lanjut': next});
}

/// `/daftar`. [full] memilih daftar lengkap (dengan kata sandi).
final class RegisterRoute extends AppRoute {
  const RegisterRoute({this.full = false, this.next});

  /// Daftar lengkap, bukan daftar cepat.
  final bool full;

  /// Lokasi tujuan setelah daftar (`?lanjut=`).
  final String? next;

  @override
  String get location => _withQuery('/daftar', <String, String?>{
    'mode': full ? 'lengkap' : null,
    'lanjut': next,
  });
}

/// `/lupa-sandi`.
final class ForgotPasswordRoute extends AppRoute {
  const ForgotPasswordRoute();

  @override
  String get location => '/lupa-sandi';
}

/// `/bantuan`.
final class HelpRoute extends AppRoute {
  const HelpRoute();

  @override
  String get location => '/bantuan';
}

/// `/tentang`.
final class AboutRoute extends AppRoute {
  const AboutRoute();

  @override
  String get location => '/tentang';
}

/// `/snk` Syarat dan Ketentuan.
final class TermsRoute extends AppRoute {
  const TermsRoute();

  @override
  String get location => '/snk';
}

/// `/privasi` Kebijakan Privasi.
final class PrivacyRoute extends AppRoute {
  const PrivacyRoute();

  @override
  String get location => '/privasi';
}

/// `/demo` Mode Demo.
final class DemoRoute extends AppRoute {
  const DemoRoute();

  @override
  String get location => '/demo';
}

/// `/demo/galeri` galeri komponen desain.
final class GalleryRoute extends AppRoute {
  const GalleryRoute();

  @override
  String get location => '/demo/galeri';
}

/// `/hadiah` zona Hadiah.
final class RewardsRoute extends AppRoute {
  const RewardsRoute();

  @override
  String get location => '/hadiah';

  @override
  AppTab get tab => AppTab.rewards;
}

/// `/hadiah/checkin` Check-in Harian.
final class CheckInRoute extends AppRoute {
  const CheckInRoute();

  @override
  String get location => '/hadiah/checkin';
}

/// `/hadiah/roda` Roda Sabtu.
final class WheelRoute extends AppRoute {
  const WheelRoute();

  @override
  String get location => '/hadiah/roda';
}

/// `/hadiah/misi` Misi Belanja.
final class MissionRoute extends AppRoute {
  const MissionRoute();

  @override
  String get location => '/hadiah/misi';
}

/// `/hadiah/hadiahku` hadiah menunggu.
final class MyGiftsRoute extends AppRoute {
  const MyGiftsRoute();

  @override
  String get location => '/hadiah/hadiahku';

  @override
  bool get requiresLogin => true;
}

/// `/hadiah/voucher`.
final class VouchersRoute extends AppRoute {
  const VouchersRoute();

  @override
  String get location => '/hadiah/voucher';

  @override
  bool get requiresLogin => true;
}

/// `/hadiah/riwayat` riwayat Kelopak.
final class LedgerRoute extends AppRoute {
  const LedgerRoute();

  @override
  String get location => '/hadiah/riwayat';

  @override
  bool get requiresLogin => true;
}

/// Lokasi yang tidak dikenal ("Waduh, tujuanmu nggak ada!").
final class NotFoundRoute extends AppRoute {
  const NotFoundRoute(this.location);

  @override
  final String location;
}

/// Pembuat jalur, supaya lokasi tidak ditulis tangan di layar.
abstract final class AppRoutes {
  static const String home = '/';
  static const String catalog = '/katalog';
  static const String search = '/cari';
  static const String hotItems = '/hot-item';
  static const String events = '/event';
  static const String wishlist = '/wishlist';
  static const String cart = '/keranjang';
  static const String checkout = '/checkout';
  static const String orders = '/pesanan';
  static const String inbox = '/notifikasi';
  static const String account = '/akun';
  static const String profile = '/akun/profil';
  static const String changePassword = '/akun/sandi';
  static const String addresses = '/akun/alamat';
  static const String settings = '/akun/pengaturan';
  static const String login = '/masuk';
  static const String register = '/daftar';
  static const String forgotPassword = '/lupa-sandi';
  static const String help = '/bantuan';
  static const String about = '/tentang';
  static const String terms = '/snk';
  static const String privacy = '/privasi';
  static const String demo = '/demo';
  static const String gallery = '/demo/galeri';
  static const String rewards = '/hadiah';
  static const String checkIn = '/hadiah/checkin';
  static const String wheel = '/hadiah/roda';
  static const String mission = '/hadiah/misi';
  static const String myGifts = '/hadiah/hadiahku';
  static const String vouchers = '/hadiah/voucher';
  static const String ledger = '/hadiah/riwayat';

  /// `/produk/:kode`.
  static String product(String code) => ProductRoute(code).location;

  /// `/event/:id`.
  static String event(String id) => EventRoute(id).location;

  /// `/bayar/:orderId`.
  static String payment(String orderId) => PaymentRoute(orderId).location;

  /// `/pesanan/:id`.
  static String order(String orderId) => OrderDetailRoute(orderId).location;

  /// `/pesanan/:id/sukses`.
  static String orderSuccess(String orderId) =>
      OrderSuccessRoute(orderId).location;

  /// `/pesanan?status=`.
  static String ordersWithStatus(String status) =>
      OrdersRoute(status: status).location;

  /// `/katalog?kategori=`.
  static String category(String id) => CatalogRoute(category: id).location;

  /// `/katalog?brand=`.
  static String brand(String name) =>
      CatalogRoute(brands: <String>[name]).location;

  /// Akar tab [tab].
  static AppRoute tabRoot(AppTab tab) => switch (tab) {
    AppTab.home => const HomeRoute(),
    AppTab.catalog => const CatalogRoute(),
    AppTab.rewards => const RewardsRoute(),
    AppTab.orders => const OrdersRoute(),
    AppTab.account => const AccountRoute(),
  };
}

/// Mengurai [location] menjadi [AppRoute].
///
/// Menerima jalur dengan atau tanpa garis miring awal (`hadiah/roda` dari
/// `deep_link_value`), URL lengkap, dan bentuk hash web (`/#/keranjang`).
/// Lokasi yang tidak dikenal menjadi [NotFoundRoute]; tidak pernah melempar.
AppRoute parseAppRoute(String location) {
  final raw = location.trim();
  final uri = _toUri(raw);
  if (uri == null) return NotFoundRoute(raw);
  final List<String> segments;
  try {
    segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  } on FormatException {
    return NotFoundRoute(raw);
  }
  final Map<String, String> query;
  try {
    query = uri.queryParameters;
  } on FormatException {
    return NotFoundRoute(raw);
  }
  final route = _match(segments, query);
  return route ?? NotFoundRoute(raw);
}

AppRoute? _match(List<String> s, Map<String, String> q) {
  if (s.isEmpty) return const HomeRoute();
  final rest = s.length - 1;
  switch (s.first) {
    case 'katalog' when rest == 0:
      return CatalogRoute(
        category: _text(q['kategori']),
        brands: _list(q['brand']),
        query: _text(q['q']),
        sort: _text(q['urut']),
        minPrice: _price(q['min']),
        maxPrice: _price(q['maks']),
      );
    case 'cari' when rest == 0:
      return SearchRoute(query: _text(q['q']));
    case 'produk' when rest == 1:
      return ProductRoute(s[1]);
    case 'hot-item' when rest == 0:
      return const HotItemsRoute();
    case 'event' when rest == 0:
      return const EventHubRoute();
    case 'event' when rest == 1:
      return EventRoute(s[1]);
    case 'wishlist' when rest == 0:
      return const WishlistRoute();
    case 'keranjang' when rest == 0:
      return const CartRoute();
    case 'checkout' when rest == 0:
      return const CheckoutRoute();
    case 'bayar' when rest == 1:
      return PaymentRoute(s[1]);
    case 'pesanan' when rest == 0:
      return OrdersRoute(status: _text(q['status']));
    case 'pesanan' when rest == 1:
      return OrderDetailRoute(s[1]);
    case 'pesanan' when rest == 2 && s[2] == 'sukses':
      return OrderSuccessRoute(s[1]);
    case 'notifikasi' when rest == 0:
      return const InboxRoute();
    case 'akun':
      return _matchAccount(s, q);
    case 'masuk' when rest == 0:
      return LoginRoute(next: _text(q['lanjut']));
    case 'daftar' when rest == 0:
      return RegisterRoute(
        full: q['mode'] == 'lengkap',
        next: _text(q['lanjut']),
      );
    case 'lupa-sandi' when rest == 0:
      return const ForgotPasswordRoute();
    case 'bantuan' when rest == 0:
      return const HelpRoute();
    case 'tentang' when rest == 0:
      return const AboutRoute();
    case 'snk' when rest == 0:
      return const TermsRoute();
    case 'privasi' when rest == 0:
      return const PrivacyRoute();
    case 'demo' when rest == 0:
      return const DemoRoute();
    case 'demo' when rest == 1 && s[1] == 'galeri':
      return const GalleryRoute();
    case 'hadiah':
      return _matchRewards(s);
  }
  return null;
}

AppRoute? _matchAccount(List<String> s, Map<String, String> q) {
  if (s.length == 1) return const AccountRoute();
  if (s.length == 2) {
    return switch (s[1]) {
      'profil' => const ProfileRoute(),
      'sandi' => const ChangePasswordRoute(),
      'alamat' => AddressesRoute(selecting: q['pilih'] == '1'),
      'pengaturan' => const SettingsRoute(),
      _ => null,
    };
  }
  if (s.length == 3 && s[1] == 'alamat') {
    return AddressFormRoute(addressId: s[2] == 'baru' ? null : s[2]);
  }
  return null;
}

AppRoute? _matchRewards(List<String> s) {
  if (s.length == 1) return const RewardsRoute();
  if (s.length != 2) return null;
  return switch (s[1]) {
    'checkin' => const CheckInRoute(),
    'roda' => const WheelRoute(),
    'misi' => const MissionRoute(),
    'hadiahku' => const MyGiftsRoute(),
    'voucher' => const VouchersRoute(),
    'riwayat' => const LedgerRoute(),
    _ => null,
  };
}

Uri? _toUri(String raw) {
  if (raw.isEmpty) return Uri(path: '/');
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  // Strategi hash web: lokasi ada di fragmen (`https://host/#/keranjang`).
  final fragment = parsed.fragment;
  if (fragment.startsWith('/')) return Uri.tryParse(fragment);
  if (parsed.hasScheme && parsed.scheme != 'http' && parsed.scheme != 'https') {
    // Skema app (`bpedia://produk/X`): host adalah segmen pertama.
    return Uri(
      pathSegments: <String>[
        if (parsed.host.isNotEmpty) parsed.host,
        ...parsed.pathSegments,
      ],
      query: parsed.hasQuery ? parsed.query : null,
    );
  }
  return parsed;
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _list(String? value) => value == null
    ? const <String>[]
    : List<String>.unmodifiable(
        value
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty),
      );

int? _price(String? value) {
  final price = int.tryParse(value ?? '');
  return price == null || price < 0 ? null : price;
}

String _withQuery(String path, Map<String, String?> values) {
  final query = <String, String>{
    for (final entry in values.entries)
      if (entry.value != null && entry.value!.isNotEmpty)
        entry.key: entry.value!,
  };
  return query.isEmpty
      ? path
      : Uri(path: path, queryParameters: query).toString();
}
