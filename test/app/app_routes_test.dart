import 'package:bpedia_app/app/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Semua rute SPEC §3 dengan lokasi kanoniknya.
  final routes = <String, AppRoute>{
    '/': const HomeRoute(),
    '/katalog': const CatalogRoute(),
    '/cari': const SearchRoute(),
    '/produk/P39A06S01000021': const ProductRoute('P39A06S01000021'),
    '/hot-item': const HotItemsRoute(),
    '/event': const EventHubRoute(),
    '/event/black-friday': const EventRoute('black-friday'),
    '/wishlist': const WishlistRoute(),
    '/keranjang': const CartRoute(),
    '/checkout': const CheckoutRoute(),
    '/bayar/BP-261125-0001': const PaymentRoute('BP-261125-0001'),
    '/pesanan': const OrdersRoute(),
    '/pesanan/BP-261125-0001': const OrderDetailRoute('BP-261125-0001'),
    '/pesanan/BP-261125-0001/sukses': const OrderSuccessRoute('BP-261125-0001'),
    '/notifikasi': const InboxRoute(),
    '/akun': const AccountRoute(),
    '/akun/profil': const ProfileRoute(),
    '/akun/sandi': const ChangePasswordRoute(),
    '/akun/alamat': const AddressesRoute(),
    '/akun/alamat/baru': const AddressFormRoute(),
    '/akun/alamat/a3': const AddressFormRoute(addressId: 'a3'),
    '/akun/pengaturan': const SettingsRoute(),
    '/masuk': const LoginRoute(),
    '/daftar': const RegisterRoute(),
    '/lupa-sandi': const ForgotPasswordRoute(),
    '/bantuan': const HelpRoute(),
    '/tentang': const AboutRoute(),
    '/snk': const TermsRoute(),
    '/privasi': const PrivacyRoute(),
    '/demo': const DemoRoute(),
    '/demo/galeri': const GalleryRoute(),
    '/hadiah': const RewardsRoute(),
    '/hadiah/checkin': const CheckInRoute(),
    '/hadiah/roda': const WheelRoute(),
    '/hadiah/misi': const MissionRoute(),
    '/hadiah/hadiahku': const MyGiftsRoute(),
    '/hadiah/voucher': const VouchersRoute(),
    '/hadiah/riwayat': const LedgerRoute(),
  };

  test('tiap rute: lokasi kanonik dan urai bolak-balik', () {
    for (final entry in routes.entries) {
      final route = entry.value;
      expect(route.location, entry.key);
      final parsed = parseAppRoute(entry.key);
      expect(parsed, route, reason: entry.key);
      expect(parsed.runtimeType, route.runtimeType, reason: entry.key);
      expect(parsed.location, entry.key);
    }
  });

  test('semua tipe rute tercakup', () {
    expect(routes.values.map((route) => route.runtimeType).toSet().length, 37);
  });

  test('konstanta dan pembuat jalur sama dengan lokasi rute', () {
    expect(AppRoutes.home, const HomeRoute().location);
    expect(AppRoutes.catalog, const CatalogRoute().location);
    expect(AppRoutes.search, const SearchRoute().location);
    expect(AppRoutes.hotItems, const HotItemsRoute().location);
    expect(AppRoutes.events, const EventHubRoute().location);
    expect(AppRoutes.wishlist, const WishlistRoute().location);
    expect(AppRoutes.cart, const CartRoute().location);
    expect(AppRoutes.checkout, const CheckoutRoute().location);
    expect(AppRoutes.orders, const OrdersRoute().location);
    expect(AppRoutes.inbox, const InboxRoute().location);
    expect(AppRoutes.account, const AccountRoute().location);
    expect(AppRoutes.profile, const ProfileRoute().location);
    expect(AppRoutes.changePassword, const ChangePasswordRoute().location);
    expect(AppRoutes.addresses, const AddressesRoute().location);
    expect(AppRoutes.settings, const SettingsRoute().location);
    expect(AppRoutes.login, const LoginRoute().location);
    expect(AppRoutes.register, const RegisterRoute().location);
    expect(AppRoutes.forgotPassword, const ForgotPasswordRoute().location);
    expect(AppRoutes.help, const HelpRoute().location);
    expect(AppRoutes.about, const AboutRoute().location);
    expect(AppRoutes.terms, const TermsRoute().location);
    expect(AppRoutes.privacy, const PrivacyRoute().location);
    expect(AppRoutes.demo, const DemoRoute().location);
    expect(AppRoutes.gallery, const GalleryRoute().location);
    expect(AppRoutes.rewards, const RewardsRoute().location);
    expect(AppRoutes.checkIn, const CheckInRoute().location);
    expect(AppRoutes.wheel, const WheelRoute().location);
    expect(AppRoutes.mission, const MissionRoute().location);
    expect(AppRoutes.myGifts, const MyGiftsRoute().location);
    expect(AppRoutes.vouchers, const VouchersRoute().location);
    expect(AppRoutes.ledger, const LedgerRoute().location);

    expect(AppRoutes.product('P1'), '/produk/P1');
    expect(AppRoutes.event('promo-1212'), '/event/promo-1212');
    expect(AppRoutes.payment('BP-1'), '/bayar/BP-1');
    expect(AppRoutes.order('BP-1'), '/pesanan/BP-1');
    expect(AppRoutes.orderSuccess('BP-1'), '/pesanan/BP-1/sukses');
    expect(AppRoutes.ordersWithStatus('dikemas'), '/pesanan?status=dikemas');
    expect(AppRoutes.category('skincare'), '/katalog?kategori=skincare');
    expect(AppRoutes.brand('Pinkflash'), '/katalog?brand=Pinkflash');
  });

  test('akar tab', () {
    expect(const HomeRoute().tab, AppTab.home);
    expect(const CatalogRoute(category: 'makeup').tab, AppTab.catalog);
    expect(const RewardsRoute().tab, AppTab.rewards);
    expect(const OrdersRoute(status: 'dikirim').tab, AppTab.orders);
    expect(const AccountRoute().tab, AppTab.account);
    for (final tab in AppTab.values) {
      expect(AppRoutes.tabRoot(tab).tab, tab);
    }
    expect(const ProductRoute('P1').tab, isNull);
    expect(const CartRoute().tab, isNull);
    expect(const WheelRoute().tab, isNull);
  });

  test('gerbang masuk mengikuti KEPUTUSAN §5', () {
    final gated = routes.values
        .where((route) => route.requiresLogin)
        .map((route) => route.runtimeType)
        .toSet();
    expect(gated, <Type>{
      CheckoutRoute,
      PaymentRoute,
      OrderDetailRoute,
      OrderSuccessRoute,
      InboxRoute,
      ProfileRoute,
      ChangePasswordRoute,
      AddressesRoute,
      AddressFormRoute,
      MyGiftsRoute,
      VouchersRoute,
      LedgerRoute,
    });
    // Tamu boleh jelajah, isi keranjang, dan melihat halaman game.
    for (final open in <AppRoute>[
      const HomeRoute(),
      const CatalogRoute(),
      const ProductRoute('P1'),
      const CartRoute(),
      const RewardsRoute(),
      const CheckInRoute(),
      const WheelRoute(),
      const MissionRoute(),
      const SettingsRoute(),
    ]) {
      expect(open.requiresLogin, isFalse, reason: open.location);
    }
  });

  group('parameter', () {
    test('katalog: kategori, brand jamak, cari, urut, dan harga', () {
      const route = CatalogRoute(
        category: 'skincare',
        brands: <String>['Pinkflash', 'You Beauty'],
        query: 'lip cream',
        sort: 'termurah',
        minPrice: 10000,
        maxPrice: 50000,
      );

      final parsed = parseAppRoute(route.location) as CatalogRoute;

      expect(parsed.category, 'skincare');
      expect(parsed.brands, <String>['Pinkflash', 'You Beauty']);
      expect(parsed.query, 'lip cream');
      expect(parsed.sort, 'termurah');
      expect(parsed.minPrice, 10000);
      expect(parsed.maxPrice, 50000);
      expect(parsed, route);
    });

    test('nilai kosong atau tidak sah diabaikan', () {
      final parsed =
          parseAppRoute('/katalog?kategori=&brand=,%20,&min=abc&maks=-5&q=%20')
              as CatalogRoute;

      expect(parsed.category, isNull);
      expect(parsed.brands, isEmpty);
      expect(parsed.query, isNull);
      expect(parsed.minPrice, isNull);
      expect(parsed.maxPrice, isNull);
      expect(parsed.location, '/katalog');
    });

    test('cari, status pesanan, pilih alamat', () {
      expect(
        (parseAppRoute('/cari?q=serum%20acne') as SearchRoute).query,
        'serum acne',
      );
      expect(
        (parseAppRoute('/pesanan?status=menunggu') as OrdersRoute).status,
        'menunggu',
      );
      expect(
        (parseAppRoute('/akun/alamat?pilih=1') as AddressesRoute).selecting,
        isTrue,
      );
      expect(
        const AddressesRoute(selecting: true).location,
        '/akun/alamat?pilih=1',
      );
      expect(
        (parseAppRoute('/akun/alamat?pilih=ya') as AddressesRoute).selecting,
        isFalse,
      );
    });

    test('masuk dan daftar membawa tujuan lanjut', () {
      const login = LoginRoute(next: '/pesanan/BP-261125-0001');
      final parsedLogin = parseAppRoute(login.location) as LoginRoute;
      expect(parsedLogin.next, '/pesanan/BP-261125-0001');
      expect(
        parseAppRoute(parsedLogin.next!),
        const OrderDetailRoute('BP-261125-0001'),
      );

      const register = RegisterRoute(full: true, next: '/checkout');
      final parsedRegister = parseAppRoute(register.location) as RegisterRoute;
      expect(parsedRegister.full, isTrue);
      expect(parsedRegister.next, '/checkout');
      expect((parseAppRoute('/daftar') as RegisterRoute).full, isFalse);
    });

    test('segmen jalur di-encode dan dikembalikan utuh', () {
      const route = ProductRoute('P 1/2?x');

      expect(route.location, '/produk/P%201%2F2%3Fx');
      expect((parseAppRoute(route.location) as ProductRoute).code, 'P 1/2?x');
    });
  });

  group('bentuk masukan', () {
    test('deep_link_value tanpa garis miring awal', () {
      expect(parseAppRoute('hadiah/roda'), const WheelRoute());
      expect(
        parseAppRoute('produk/P39A06S01000052'),
        const ProductRoute('P39A06S01000052'),
      );
      expect(parseAppRoute('keranjang'), const CartRoute());
    });

    test('kosong, spasi, dan garis miring berlebih', () {
      expect(parseAppRoute(''), const HomeRoute());
      expect(parseAppRoute('   '), const HomeRoute());
      expect(parseAppRoute('/hadiah/'), const RewardsRoute());
      expect(parseAppRoute(' /hot-item '), const HotItemsRoute());
    });

    test('URL lengkap, hash web, dan skema app', () {
      expect(
        parseAppRoute('https://demo.bpedia.id/event/black-friday'),
        const EventRoute('black-friday'),
      );
      expect(
        parseAppRoute('https://demo.bpedia.id/#/keranjang'),
        const CartRoute(),
      );
      expect(
        parseAppRoute('https://demo.bpedia.id/#/katalog?kategori=makeup'),
        const CatalogRoute(category: 'makeup'),
      );
      expect(parseAppRoute('bpedia-demo://hadiah/roda'), const WheelRoute());
      expect(
        parseAppRoute('bpedia-demo://produk/P39A06S01000052'),
        const ProductRoute('P39A06S01000052'),
      );
    });
  });

  group('tidak dikenal', () {
    test('menjadi NotFoundRoute dengan lokasi asli, tidak pernah melempar', () {
      for (final location in <String>[
        '/tidak-ada',
        '/produk',
        '/produk/a/b',
        '/event/a/b',
        '/bayar',
        '/pesanan/BP-1/lain',
        '/pesanan/BP-1/sukses/lagi',
        '/akun/lain',
        '/akun/alamat/a/b',
        '/hadiah/lain',
        '/hadiah/roda/putar',
        '/demo/lain',
        '/keranjang/isi',
        '/Katalog',
        '/%E0%A4%A',
        '/produk/%E0%A4',
        'http://[::1',
        '::::',
      ]) {
        final route = parseAppRoute(location);
        expect(route, isA<NotFoundRoute>(), reason: location);
        expect(route.location, location, reason: location);
        expect(route.tab, isNull);
        expect(route.requiresLogin, isFalse);
      }
    });
  });

  test('kesetaraan memakai tipe dan lokasi', () {
    expect(const ProductRoute('A'), const ProductRoute('A'));
    expect(const ProductRoute('A').hashCode, const ProductRoute('A').hashCode);
    expect(const ProductRoute('A'), isNot(const ProductRoute('B')));
    expect(const OrderDetailRoute('X'), isNot(const PaymentRoute('X')));
    expect(const NotFoundRoute('/keranjang'), isNot(const CartRoute()));
    expect(const CartRoute().toString(), 'CartRoute(/keranjang)');
  });
}
