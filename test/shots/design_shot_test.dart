import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/design/gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/shot.dart';

Widget _app(Widget home, {required bool dark}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? BpTheme.dark() : BpTheme.light(),
    home: home,
  );
}

Widget _page(Widget body, {Widget? bottom}) {
  return Scaffold(
    bottomNavigationBar: bottom,
    body: SafeArea(child: body),
  );
}

void main() {
  for (final dark in <bool>[false, true]) {
    final suffix = dark ? 'gelap' : 'terang';

    testWidgets('galeri $suffix', (tester) async {
      const size = Size(390, 2200);
      await shot(
        tester,
        _app(const DesignGalleryPage(autoPlayBanners: false), dark: dark),
        name: 'design_galeri_${suffix}_1',
        size: size,
      );
      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -1700));
      await tester.pump(const Duration(milliseconds: 600));
      await settleImages(tester, rounds: 8);
      await tester.pump(const Duration(milliseconds: 400));
      await saveShot(tester, 'design_galeri_${suffix}_2');
      await tester.drag(list, const Offset(0, -1700));
      await tester.pump(const Duration(milliseconds: 600));
      await settleImages(tester, rounds: 8);
      await tester.pump(const Duration(milliseconds: 400));
      await saveShot(tester, 'design_galeri_${suffix}_3');
    });

    testWidgets('dialog dan pesan $suffix', (tester) async {
      await pumpShot(
        tester,
        _app(
          Builder(
            builder: (context) => _page(
              Center(
                child: PillButton(
                  label: 'Buka',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('1 produk dihapus dari keranjang'),
                        action: SnackBarAction(
                          label: 'Urungkan',
                          onPressed: () {},
                        ),
                      ),
                    );
                    showDialog<void>(
                      context: context,
                      builder: (context) => const GalleryDialog(),
                    );
                  },
                ),
              ),
            ),
          ),
          dark: dark,
        ),
        size: const Size(390, 520),
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await saveShot(tester, 'design_dialog_$suffix');
    });

    testWidgets('skala huruf 200% lebar 360 $suffix', (tester) async {
      await shot(
        tester,
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? BpTheme.dark() : BpTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const DesignGalleryPage(autoPlayBanners: false),
        ),
        name: 'design_skala200_${suffix}_1',
        size: const Size(360, 1800),
      );
      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -2300));
      await tester.pump(const Duration(milliseconds: 600));
      await settleImages(tester, rounds: 8);
      await tester.pump(const Duration(milliseconds: 400));
      await saveShot(tester, 'design_skala200_${suffix}_2');
    });

    testWidgets('kartu produk grid $suffix', (tester) async {
      await shot(
        tester,
        _app(
          _page(
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: BpSpace.x2),
              child: ProductGrid(
                itemCount: galleryProducts.length,
                itemBuilder: (context, index) => ProductCard(
                  data: galleryProducts[index],
                  wishlisted: index == 1,
                  onToggleWishlist: () {},
                  onAddToCart: () {},
                  action: index < 2
                      ? ProductCardAction.quickAdd
                      : ProductCardAction.addButton,
                  onTap: () {},
                ),
              ),
            ),
          ),
          dark: dark,
        ),
        name: 'design_kartu_produk_$suffix',
        size: const Size(390, 700),
      );
    });

    testWidgets('nav bawah $suffix', (tester) async {
      await shot(
        tester,
        _app(
          _page(
            const SizedBox.expand(),
            bottom: BpBottomNav(
              currentIndex: 0,
              onSelected: (_) {},
              trailing: <BpNavItem>[
                BpBottomNav.defaultTrailing[0].copyWith(badgeCount: 2),
                BpBottomNav.defaultTrailing[1],
              ],
              rewardDot: true,
            ),
          ),
          dark: dark,
        ),
        name: 'design_nav_$suffix',
        size: const Size(390, 160),
      );
    });

    testWidgets('sheet $suffix', (tester) async {
      await pumpShot(
        tester,
        _app(
          Builder(
            builder: (context) => _page(
              Center(
                child: PillButton(
                  label: 'Buka',
                  onPressed: () => showBpSheet<void>(
                    context: context,
                    builder: (context) => const GallerySheet(),
                  ),
                ),
              ),
            ),
          ),
          dark: dark,
        ),
        size: const Size(390, 640),
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await saveShot(tester, 'design_sheet_$suffix');
    });

    testWidgets('carousel dan keadaan kosong $suffix', (tester) async {
      await shot(
        tester,
        _app(
          _page(
            ListView(
              children: <Widget>[
                const Section(
                  child: BannerCarousel(
                    items: galleryBanners,
                    autoPlayInterval: Duration.zero,
                  ),
                ),
                Section(
                  child: EmptyState(
                    imageAsset: 'assets/bipy/bipy_tas_depan.webp',
                    title: 'Keranjangmu masih kosong',
                    message: 'Yuk, isi dengan produk favoritmu, Babes.',
                    actionLabel: 'Mulai belanja',
                    onAction: () {},
                  ),
                ),
              ],
            ),
          ),
          dark: dark,
        ),
        name: 'design_carousel_kosong_$suffix',
        size: const Size(390, 600),
      );
    });
  }
}
