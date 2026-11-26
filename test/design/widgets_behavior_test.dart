import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/design/gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_harness.dart';

const ProductCardData _product = ProductCardData(
  id: 'P11B11B01000004',
  name: 'Brighty Glow & Bright Bar Soap',
  brand: 'Brighty',
  price: 10000,
  strikePrice: 22500,
  discountPercent: 56,
  rating: 5,
  imageAsset: 'assets/catalog/img/P11B11B01000004-1.webp',
);

const ProductCardData _soldOut = ProductCardData(
  id: 'P39A06S01000052',
  name: 'Animate Intense Acne Solution Day Cream 10 g',
  price: 10000,
  imageAsset: 'assets/catalog/img/P39A06S01000052-1.webp',
  inStock: false,
);

Widget _pad(Widget child) =>
    Padding(padding: const EdgeInsets.all(BpSpace.screen), child: child);

void main() {
  group('QtyStepper', () {
    testWidgets('tambah dan kurang mengirim nilai baru dalam batas', (
      tester,
    ) async {
      var value = 2;
      await pumpDesign(
        tester,
        _pad(
          StatefulBuilder(
            builder: (context, setState) => QtyStepper(
              value: value,
              max: 3,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Tambah jumlah'));
      await tester.pump();
      expect(value, 3);
      await tester.tap(find.byTooltip('Tambah jumlah'));
      await tester.pump();
      expect(value, 3, reason: 'tidak melewati batas atas');
      await tester.tap(find.byTooltip('Kurangi jumlah'));
      await tester.pump();
      await tester.tap(find.byTooltip('Kurangi jumlah'));
      await tester.pump();
      expect(value, 1);
      await tester.tap(find.byTooltip('Kurangi jumlah'));
      await tester.pump();
      expect(value, 1, reason: 'tidak turun di bawah batas bawah');
    });

    testWidgets('jumlah 1 dengan onRemove menampilkan hapus', (tester) async {
      var removed = 0;
      var changed = 0;
      await pumpDesign(
        tester,
        _pad(
          QtyStepper(
            value: 1,
            onChanged: (_) => changed++,
            onRemove: () => removed++,
          ),
        ),
      );
      expect(find.byTooltip('Kurangi jumlah'), findsNothing);
      await tester.tap(find.byTooltip('Hapus dari keranjang'));
      expect(removed, 1);
      expect(changed, 0);
    });

    testWidgets('area ketuk tiap tombol minimal 48', (tester) async {
      await pumpDesign(tester, _pad(QtyStepper(value: 2, onChanged: (_) {})));
      for (final tip in <String>['Tambah jumlah', 'Kurangi jumlah']) {
        final size = tapAreaOf(
          tester,
          find.ancestor(
            of: find.byTooltip(tip),
            matching: find.byType(BpTappable),
          ),
        );
        expect(size.width, greaterThanOrEqualTo(48), reason: tip);
        expect(size.height, greaterThanOrEqualTo(48), reason: tip);
      }
    });
  });

  group('BpChip', () {
    testWidgets('ketuk memilih, hapus memanggil onDeleted', (tester) async {
      var selected = false;
      var deleted = 0;
      await pumpDesign(
        tester,
        _pad(
          StatefulBuilder(
            builder: (context, setState) => Wrap(
              children: <Widget>[
                BpChip(
                  label: 'Termurah',
                  selected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
                BpChip(label: 'Skincare', onDeleted: () => deleted++),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Termurah'));
      await tester.pump();
      expect(selected, isTrue);
      await tester.tap(find.text('Skincare'));
      expect(deleted, 1);
    });

    testWidgets('tinggi area ketuk minimal 48 dan semantik terpilih', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDesign(
        tester,
        _pad(BpChip(label: 'Termurah', selected: true, onTap: () {})),
      );
      expect(
        tester.getSize(find.byType(BpTappable)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Termurah')),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
      );
      handle.dispose();
    });
  });

  group('BannerCarousel', () {
    testWidgets('geser mengganti banner, penghitung, dan callback', (
      tester,
    ) async {
      final pages = <int>[];
      await pumpDesign(
        tester,
        BannerCarousel(
          items: galleryBanners,
          autoPlayInterval: Duration.zero,
          onPageChanged: pages.add,
        ),
      );
      expect(find.text('1/5'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('2/5'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.drag(find.byType(PageView), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('5/5'), findsOneWidget, reason: 'berputar ke kiri');
      expect(pages, <int>[1, 0, 4]);
    });

    testWidgets('putar otomatis maju tiap interval dan berhenti saat dibuang', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const BannerCarousel(
          items: galleryBanners,
          autoPlayInterval: Duration(seconds: 4),
        ),
      );
      expect(find.text('1/5'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('2/5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('kurangi gerak: pindah tanpa animasi', (tester) async {
      await pumpDesign(
        tester,
        const BannerCarousel(
          items: galleryBanners,
          autoPlayInterval: Duration(seconds: 4),
        ),
        reduceMotion: true,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text('2/5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('satu banner: tanpa titik dan penghitung; ketuk diteruskan', (
      tester,
    ) async {
      var taps = 0;
      await pumpDesign(
        tester,
        BannerCarousel(
          items: <BannerItem>[
            BannerItem(
              asset: 'assets/promo/banner_1212.webp',
              semanticLabel: 'Tanggal Kembar 12.12',
              onTap: () => taps++,
            ),
          ],
        ),
      );
      expect(find.text('1/1'), findsNothing);
      await tester.tap(find.byType(BannerCarousel));
      expect(taps, 1);
    });

    testWidgets('daftar kosong tidak memakan ruang', (tester) async {
      await pumpDesign(tester, const BannerCarousel(items: <BannerItem>[]));
      expect(tester.getSize(find.byType(BannerCarousel)).height, 0);
    });
  });

  group('PillButton', () {
    testWidgets('aktif memanggil, nonaktif dan sibuk tidak', (tester) async {
      var taps = 0;
      await pumpDesign(
        tester,
        _pad(
          Column(
            children: <Widget>[
              PillButton(label: 'Beli sekarang', onPressed: () => taps++),
              const PillButton(label: 'Stok habis', onPressed: null),
              PillButton(
                label: 'Memproses',
                busy: true,
                onPressed: () => taps += 10,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Beli sekarang'));
      await tester.tap(find.text('Stok habis'), warnIfMissed: false);
      await tester.tap(find.byType(PillButton).last, warnIfMissed: false);
      expect(taps, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tinggi 48 (besar) dan area ketuk 48 untuk ukuran kecil', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        _pad(
          Column(
            children: <Widget>[
              PillButton(label: 'Besar', onPressed: () {}),
              PillButton(
                label: 'Kecil',
                size: PillButtonSize.small,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      for (final button in tester.widgetList<PillButton>(
        find.byType(PillButton),
      )) {
        expect(
          tester.getSize(find.byWidget(button)).height,
          greaterThanOrEqualTo(48),
          reason: button.label,
        );
      }
    });
  });

  group('ProductCard', () {
    testWidgets('ketuk kartu, tambah, dan wishlist punya callback terpisah', (
      tester,
    ) async {
      final log = <String>[];
      await pumpDesign(
        tester,
        ProductGrid(
          itemCount: 2,
          itemBuilder: (context, index) => ProductCard(
            data: _product,
            action: index == 0
                ? ProductCardAction.quickAdd
                : ProductCardAction.addButton,
            onTap: () => log.add('buka$index'),
            onAddToCart: () => log.add('tambah$index'),
            onToggleWishlist: () => log.add('hati$index'),
          ),
        ),
      );
      await tester.tap(find.text(_product.name).first);
      await tester.tap(find.byTooltip('Tambah ke keranjang'));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Keranjang'));
      await tester.tap(find.byTooltip('Simpan ke wishlist').last);
      await tester.pump(const Duration(seconds: 2));
      expect(log, <String>['buka0', 'tambah0', 'tambah1', 'hati1']);
      expect(find.text('-56%'), findsNWidgets(2));
      expect(find.text('Rp22.500'), findsNWidgets(2));
    });

    testWidgets('stok habis: pita tampil dan tombol tambah mati', (
      tester,
    ) async {
      var added = 0;
      await pumpDesign(
        tester,
        ProductGrid(
          itemCount: 2,
          itemBuilder: (context, index) => ProductCard(
            data: _soldOut,
            action: index == 0
                ? ProductCardAction.quickAdd
                : ProductCardAction.addButton,
            onAddToCart: () => added++,
          ),
        ),
      );
      expect(find.text('Stok habis'), findsNWidgets(2));
      await tester.tap(find.text('Keranjang'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));
      expect(added, 0);
    });

    testWidgets('semantik kartu menyebut nama, harga, diskon, dan rating', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDesign(
        tester,
        ProductGrid(
          itemCount: 1,
          itemBuilder: (context, index) =>
              ProductCard(data: _product, onTap: () {}),
        ),
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Brighty Glow & Bright Bar Soap, Brighty, harga Rp10\.000, '
            r'harga sebelumnya Rp22\.500, diskon 56 persen, rating 5,0',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('dua kartu sebaris sama tinggi walau isi berbeda', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        ProductGrid(
          itemCount: 2,
          itemBuilder: (context, index) => ProductCard(
            data: index == 0 ? _product : _soldOut,
            onAddToCart: () {},
          ),
        ),
      );
      final cards = find.byType(ProductCard);
      expect(
        tester.getSize(cards.at(0)).height,
        tester.getSize(cards.at(1)).height,
      );
      expect(
        tester.getSize(cards.at(0)).width,
        closeTo((360 - 2 * BpSpace.gridMargin - BpSpace.grid) / 2, 0.5),
      );
    });

    for (final scroll in <bool>[true, false]) {
      testWidgets(
        'tombol + Keranjang menempel ke dasar kartu dan sejajar sebaris '
        '(${scroll ? 'gulir' : 'rel'})',
        (tester) async {
          const plain = ProductCardData(
            id: 'P1',
            name: 'Toner',
            price: 25000,
            imageAsset: 'assets/catalog/img/P11B11B01000004-1.webp',
          );
          Widget card(int index) => ProductCard(
            data: index == 0 ? _product : plain,
            action: ProductCardAction.addButton,
            onAddToCart: () {},
          );
          await pumpDesign(
            tester,
            scroll
                ? ProductGrid(itemCount: 2, itemBuilder: (_, i) => card(i))
                : ProductRail(itemCount: 2, itemBuilder: (_, i) => card(i)),
            scroll: scroll,
          );
          final buttons = find.bySemanticsLabel('Tambah ke keranjang');
          expect(buttons, findsNWidgets(2));
          final cards = find.byType(ProductCard);
          for (var i = 0; i < 2; i++) {
            final cardRect = tester.getRect(cards.at(i));
            final buttonRect = tester.getRect(buttons.at(i));
            expect(
              cardRect.bottom - buttonRect.bottom,
              lessThanOrEqualTo(BpSpace.cardDense + 1),
              reason: 'kartu $i',
            );
          }
          expect(
            tester.getRect(buttons.at(0)).bottom,
            moreOrLessEquals(tester.getRect(buttons.at(1)).bottom),
          );
        },
      );
    }

    testWidgets('kartu + Keranjang di kolom tanpa batas tinggi tetap rapat', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        ProductCard(
          data: _product,
          action: ProductCardAction.addButton,
          onAddToCart: () {},
        ),
      );
      final card = tester.getRect(find.byType(ProductCard));
      final button = tester.getRect(
        find.bySemanticsLabel('Tambah ke keranjang'),
      );
      expect(card.bottom - button.bottom, lessThanOrEqualTo(BpSpace.cardDense));
      expect(tester.takeException(), isNull);
    });
  });

  group('BpBottomNav', () {
    testWidgets('lima tab mengirim indeks 0 sampai 4', (tester) async {
      final picked = <int>[];
      await pumpDesign(
        tester,
        const SizedBox(height: 100),
        bottom: BpBottomNav(
          currentIndex: 0,
          onSelected: picked.add,
          trailing: <BpNavItem>[
            BpBottomNav.defaultTrailing[0].copyWith(badgeCount: 2),
            BpBottomNav.defaultTrailing[1],
          ],
          rewardDot: true,
        ),
      );
      for (final label in <String>[
        'Beranda',
        'Katalog',
        'Hadiah',
        'Transaksi',
        'Akun',
      ]) {
        await tester.tap(find.text(label));
      }
      expect(picked, <int>[0, 1, 2, 3, 4]);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(DotBadge), findsOneWidget);
    });

    testWidgets('semantik tab menyebut posisi, lencana, dan status terpilih', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDesign(
        tester,
        const SizedBox(height: 100),
        bottom: BpBottomNav(
          currentIndex: 3,
          onSelected: (_) {},
          trailing: <BpNavItem>[
            BpBottomNav.defaultTrailing[0].copyWith(badgeCount: 2),
            BpBottomNav.defaultTrailing[1],
          ],
          rewardDot: true,
        ),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('^Transaksi, tab 4 dari 5')),
        ),
        isSemantics(isSelected: true, hasSelectedState: true),
      );
      expect(
        find.bySemanticsLabel('Hadiah, tab 3 dari 5, ada yang bisa diklaim'),
        findsOneWidget,
      );
      handle.dispose();
    });

    test('token tombol Hadiah mengikuti Figma: 50 dp, naik 12', () {
      expect(BpSize.rewardButton, 50);
      expect(BpSize.rewardLift, 12);
    });

    for (final dark in <bool>[false, true]) {
      testWidgets('tombol Hadiah bercincin surface 4 dan label tebal '
          '(${dark ? 'gelap' : 'terang'})', (tester) async {
        await pumpDesign(
          tester,
          const SizedBox(height: 100),
          dark: dark,
          bottom: BpBottomNav(currentIndex: 0, onSelected: (_) {}),
        );
        final c = dark ? BpColors.dark : BpColors.light;
        final ring = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .singleWhere((d) => d.gradient == BpFest.candy);
        final border = ring.border! as Border;
        expect(border.top.width, 4);
        expect(border.top.color, c.surface);
        final shadow = ring.boxShadow!.single;
        expect(shadow.offset, const Offset(0, 2));
        expect(shadow.blurRadius, 8);

        final nav = tester.getRect(find.byType(BpBottomNav));
        final circle = tester.getRect(
          find
              .ancestor(
                of: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).gradient == BpFest.candy,
                ),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(circle.size, const Size.square(50));
        expect(circle.top, moreOrLessEquals(nav.top - 12, epsilon: 0.5));

        final idle = tester.widget<Text>(find.text('Hadiah')).style!;
        expect(idle.fontWeight, FontWeight.w700);
        expect(idle.color, c.text);

        await pumpDesign(
          tester,
          const SizedBox(height: 100),
          dark: dark,
          bottom: BpBottomNav(
            currentIndex: BpBottomNav.rewardIndex,
            onSelected: (_) {},
          ),
        );
        final active = tester.widget<Text>(find.text('Hadiah')).style!;
        expect(active.fontWeight, FontWeight.w700);
        expect(active.color, c.brandStrong);
      });
    }
  });

  group('Lencana', () {
    testWidgets('keranjang menampilkan jumlah, 99+, dan kosong', (
      tester,
    ) async {
      var taps = 0;
      Widget bar(int count) => _pad(
        CartBadgeIcon(
          key: ValueKey<int>(count),
          count: count,
          onPressed: () => taps++,
        ),
      );
      await pumpDesign(tester, bar(3));
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.byType(CartBadgeIcon));
      expect(taps, 1);
      await pumpDesign(tester, bar(250));
      expect(find.text('99+'), findsOneWidget);
      await pumpDesign(tester, bar(0));
      expect(find.byType(CountBadge), findsNothing);
      expect(
        tester.getSize(find.byType(CartBadgeIcon)).shortestSide,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('BpSheet', () {
    testWidgets('showBpSheet membuka lembar berjudul dan Tutup menutupnya', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        Builder(
          builder: (context) => PillButton(
            label: 'Buka',
            onPressed: () => showBpSheet<void>(
              context: context,
              builder: (context) => const GallerySheet(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Filter'), findsOneWidget);
      await tester.tap(find.text('Makeup'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Filter'), findsNothing);
    });

    testWidgets('showBpSheet mengembalikan nilai pop', (tester) async {
      String? result;
      await pumpDesign(
        tester,
        Builder(
          builder: (context) => PillButton(
            label: 'Buka',
            onPressed: () async {
              result = await showBpSheet<String>(
                context: context,
                builder: (context) => BpSheet(
                  title: 'Urutkan',
                  child: PillButton(
                    label: 'Termurah',
                    onPressed: () => Navigator.pop(context, 'termurah'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Termurah'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(result, 'termurah');
    });
  });

  group('SearchField', () {
    testWidgets('mengetik, menghapus, dan mengirim', (tester) async {
      final changes = <String>[];
      String? submitted;
      await pumpDesign(
        tester,
        _pad(
          SearchField(
            onChanged: changes.add,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      );
      expect(find.byTooltip('Hapus teks'), findsNothing);
      await tester.enterText(find.byType(TextField), 'serum');
      await tester.pump();
      expect(changes.last, 'serum');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, 'serum');
      await tester.tap(find.byTooltip('Hapus teks'));
      await tester.pump();
      expect(changes.last, '');
      expect(find.byTooltip('Hapus teks'), findsNothing);
    });

    testWidgets('varian tombol memanggil onTap dan mengganti petunjuk', (
      tester,
    ) async {
      var taps = 0;
      await pumpDesign(
        tester,
        _pad(
          SearchField.button(
            onTap: () => taps++,
            hints: const <String>['Cari serum', 'Cari sunscreen'],
          ),
        ),
      );
      expect(find.text('Cari serum'), findsOneWidget);
      await tester.tap(find.byType(SearchField));
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Cari sunscreen'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('Baris dan bar', () {
    testWidgets('BpSwitchTile: ketuk baris membalik nilai', (tester) async {
      var value = true;
      await pumpDesign(
        tester,
        StatefulBuilder(
          builder: (context, setState) => BpSwitchTile(
            title: 'Pakai Kelopak',
            subtitle: 'Saldo 128 Kelopak',
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      );
      await tester.tap(find.text('Pakai Kelopak'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(value, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 300));
      expect(value, isTrue);
    });

    for (final dark in <bool>[false, true]) {
      test('sakelar mengikuti kenop G5 (${dark ? 'gelap' : 'terang'})', () {
        final c = dark ? BpColors.dark : BpColors.light;
        final theme = (dark ? BpTheme.dark() : BpTheme.light()).switchTheme;
        const off = <WidgetState>{};
        const on = <WidgetState>{WidgetState.selected};
        expect(theme.trackColor!.resolve(off), c.surfaceMuted);
        expect(theme.trackOutlineColor!.resolve(off), c.textFaint);
        expect(theme.trackOutlineWidth!.resolve(off), 2);
        expect(theme.thumbColor!.resolve(off), c.textFaint);
        expect(theme.trackColor!.resolve(on), c.brand);
        expect(theme.trackOutlineColor!.resolve(on), Colors.transparent);
        expect(theme.thumbColor!.resolve(on), const Color(0xFFFFFFFF));
      });
    }

    testWidgets('InfoRow dan SectionHeader: ketuk memanggil callback', (
      tester,
    ) async {
      final log = <String>[];
      await pumpDesign(
        tester,
        Section(
          header: SectionHeader(
            title: 'Voucher',
            onAction: () => log.add('semua'),
          ),
          child: InfoRow(
            label: 'Voucher',
            value: '2 tersedia',
            onTap: () => log.add('baris'),
          ),
        ),
      );
      await tester.tap(find.text('Lihat semua'));
      await tester.tap(find.text('2 tersedia'));
      expect(log, <String>['semua', 'baris']);
    });

    testWidgets('StickyBottomBar.total: total terformat, aksi bisa mati', (
      tester,
    ) async {
      var taps = 0;
      await pumpDesign(
        tester,
        Column(
          children: <Widget>[
            StickyBottomBar.total(
              total: 113000,
              actionLabel: 'Checkout (2)',
              onAction: () => taps++,
            ),
            StickyBottomBar.total(
              total: 0,
              actionLabel: 'Checkout',
              onAction: null,
            ),
          ],
        ),
      );
      expect(find.text('Rp113.000'), findsOneWidget);
      expect(find.text('Rp0'), findsOneWidget);
      await tester.tap(find.text('Checkout (2)'));
      await tester.tap(find.text('Checkout'), warnIfMissed: false);
      expect(taps, 1);
    });

    testWidgets('EmptyState dan VoucherTicket: aksi utama dan keadaan redup', (
      tester,
    ) async {
      final log = <String>[];
      await pumpDesign(
        tester,
        Column(
          children: <Widget>[
            EmptyState(
              imageAsset: 'assets/bipy/bipy_ngintip.webp',
              title: 'Belum ketemu, Babes',
              actionLabel: 'Hapus filter',
              onAction: () => log.add('kosong'),
            ),
            _pad(
              VoucherTicket(
                valueLabel: 'Rp10.000',
                title: 'Voucher Misi Belanja',
                actionLabel: 'Pakai',
                onAction: () => log.add('pakai'),
              ),
            ),
            _pad(
              VoucherTicket(
                valueLabel: 'Rp12.000',
                title: 'Tanggal Kembar 12.12',
                reason: 'Bisa diklaim 12 Des 2026',
                actionLabel: 'Klaim',
                onAction: () => log.add('klaim'),
                muted: true,
              ),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Hapus filter'));
      await tester.tap(find.text('Pakai'));
      await tester.tap(find.text('Klaim'), warnIfMissed: false);
      expect(log, <String>['kosong', 'pakai']);
      expect(find.text('Bisa diklaim 12 Des 2026'), findsOneWidget);
    });
  });

  group('BrandIcon dan AssetPicture', () {
    testWidgets('mono diwarnai tema; warna dipetakan ulang di tema gelap', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const Row(
          children: <Widget>[
            BrandIcon(BrandGlyph.home),
            BrandIcon(BrandGlyph.home, style: BrandIconStyle.color),
          ],
        ),
        dark: true,
      );
      final pictures = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .toList();
      expect(pictures, hasLength(2));
      expect(pictures[0].colorFilter, isNotNull);
      final mono = pictures[0].bytesLoader;
      final color = pictures[1].bytesLoader;
      expect(mono, isA<SvgAssetLoader>());
      expect(color, isA<SvgAssetLoader>());
      expect((mono as SvgAssetLoader).assetName, BrandGlyph.home.monoAsset);
      expect((color as SvgAssetLoader).assetName, BrandGlyph.home.colorAsset);
      expect(color.colorMapper, isNotNull);
      expect(tester.getSize(find.byType(BrandIcon).first), const Size(24, 24));
    });

    testWidgets('ikon warna di tema terang memakai berkas apa adanya', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const BrandIcon(BrandGlyph.voucher, style: BrandIconStyle.color),
      );
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect((picture.bytesLoader as SvgAssetLoader).colorMapper, isNull);
    });

    testWidgets('gambar yang gagal dimuat diganti ikon, tanpa galat', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const AssetPicture('assets/tidak/ada.webp', width: 80, height: 80),
      );
      await tester.runAsync<void>(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AssetPicture)), const Size(80, 80));
      expect(find.byType(BrandIcon), findsOneWidget);
    });
  });

  group('Tema', () {
    testWidgets('komponen Material mengikuti token di kedua tema', (
      tester,
    ) async {
      for (final dark in <bool>[false, true]) {
        final theme = dark ? BpTheme.dark() : BpTheme.light();
        final c = dark ? BpColors.dark : BpColors.light;
        expect(theme.useMaterial3, isTrue);
        expect(theme.scaffoldBackgroundColor, c.canvas);
        expect(theme.colorScheme.primary, c.brand);
        expect(theme.colorScheme.onPrimary, c.onBrand);
        expect(theme.colorScheme.surface, c.surface);
        expect(theme.appBarTheme.backgroundColor, c.surface);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.bottomSheetTheme.backgroundColor, c.surface);
        expect(theme.dividerTheme.color, c.line);
        expect(theme.textTheme.bodyMedium?.fontFamily, BpText.family);
        expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
      }
    });

    testWidgets('context.bp mengembalikan palet tema aktif', (tester) async {
      late BpColors seen;
      await pumpDesign(
        tester,
        Builder(
          builder: (context) {
            seen = context.bp;
            return const SizedBox.shrink();
          },
        ),
        dark: true,
      );
      expect(seen.isDark, isTrue);
      expect(seen.canvas, BpColors.dark.canvas);
    });
  });
}
