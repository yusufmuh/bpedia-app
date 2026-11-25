import 'package:bpedia_app/design/design.dart';
import 'package:bpedia_app/design/gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'design_harness.dart';

const String _longName =
    'Somethinc 5% Niacinamide Barrier Serum Brightening Moisture 20 ml';

const ProductCardData _fullProduct = ProductCardData(
  id: 'P11B11B01000004',
  name: _longName,
  brand: 'Somethinc Official Indonesia',
  price: 1250000,
  strikePrice: 2500000,
  discountPercent: 50,
  rating: 4.9,
  ribbon: 'Produk misi',
  imageAsset: 'assets/catalog/img/P11B11B01000004-1.webp',
);

const ProductCardData _soldOut = ProductCardData(
  id: 'P39A06S01000052',
  name: 'Animate Intense Acne Solution Day Cream 10 g',
  price: 10000,
  strikePrice: 21500,
  discountPercent: 53,
  imageAsset: 'assets/catalog/img/P39A06S01000052-1.webp',
  inStock: false,
);

Widget _pad(Widget child) =>
    Padding(padding: const EdgeInsets.all(BpSpace.screen), child: child);

/// Tiap entri dirender pada lebar 360 dengan skala huruf 200% di kedua tema.
final Map<String, Widget Function()> _cases = <String, Widget Function()>{
  'SearchField': () => _pad(
    Column(
      children: <Widget>[
        SearchField(
          hint: 'Cari sunscreen untuk kulit berminyak di Bpedia',
          onChanged: (_) {},
        ),
        const SizedBox(height: BpSpace.x2),
        SearchField.button(
          onTap: () {},
          hints: const <String>['Cari serum pencerah wajah di Bpedia'],
          trailing: const Icon(LucideIcons.slidersHorizontal),
        ),
      ],
    ),
  ),
  'SectionHeader dan Section': () => Section(
    header: SectionHeader(
      title: 'Rekomendasi produk pilihan untukmu',
      subtitle: 'Diperbarui dari katalog 25 Nov 2026',
      leading: const BrandIcon(BrandGlyph.flash),
      onAction: () {},
    ),
    inset: true,
    child: const Text('Isi seksi dengan kalimat yang cukup panjang untuk uji.'),
  ),
  'ProductCard kisi dua kolom': () => ProductGrid(
    itemCount: 6,
    itemBuilder: (context, index) {
      if (index == 5) return const ProductCardSkeleton();
      return ProductCard(
        data: index == 3 ? _soldOut : _fullProduct,
        wishlisted: index.isOdd,
        onTap: () {},
        onAddToCart: () {},
        onToggleWishlist: () {},
        action: ProductCardAction.values[index % 3],
      );
    },
  ),
  'ProductRail': () => ProductRail(
    itemCount: 3,
    itemBuilder: (context, index) => ProductCard(
      data: index == 1 ? _soldOut : _fullProduct,
      action: ProductCardAction.none,
      reserveRatingRow: false,
      onTap: () {},
    ),
  ),
  'PriceText': () => _pad(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PriceText(12500000, strikePrice: 25000000, discountPercent: 50),
        const PriceText(
          12500000,
          strikePrice: 25000000,
          discountPercent: 50,
          size: PriceTextSize.detail,
        ),
        const PriceText(12500000, strikePrice: 25000000, stacked: true),
        for (final size in PriceTextSize.values) PriceText(9900, size: size),
      ],
    ),
  ),
  'DiscountBadge dan StatusChip': () => _pad(
    Wrap(
      spacing: BpSpace.x2,
      runSpacing: BpSpace.x2,
      children: <Widget>[
        const DiscountBadge(percent: 99),
        const DiscountBadge(percent: 5, corner: true),
        for (final tone in StatusTone.values)
          StatusChip(
            label: 'Menunggu pembayaran sampai besok pukul 09.00 WIB',
            tone: tone,
            icon: const BrandIcon(BrandGlyph.original, size: 14),
          ),
      ],
    ),
  ),
  'QtyStepper': () => _pad(
    Row(
      children: <Widget>[
        const Expanded(child: PriceText(106800, strikePrice: 128000)),
        QtyStepper(value: 99, onChanged: (_) {}, onRemove: () {}),
      ],
    ),
  ),
  'PillButton': () => _pad(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final variant in PillButtonVariant.values)
          for (final size in PillButtonSize.values)
            Padding(
              padding: const EdgeInsets.only(bottom: BpSpace.x2),
              child: PillButton(
                label: 'Buat pesanan · Lunas dengan Kelopak',
                variant: variant,
                size: size,
                icon: const Icon(LucideIcons.plus),
                onPressed: () {},
              ),
            ),
        Row(
          children: <Widget>[
            Expanded(
              child: PillButton(
                label: 'Keranjang',
                variant: PillButtonVariant.outline,
                icon: const Icon(LucideIcons.plus),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: BpSpace.x2),
            Expanded(
              child: PillButton(label: 'Beli sekarang', onPressed: () {}),
            ),
          ],
        ),
        const PillButton(label: 'Memproses', busy: true, onPressed: null),
      ],
    ),
  ),
  'StickyBottomBar': () => Column(
    children: <Widget>[
      StickyBottomBar.total(
        total: 12500000,
        caption: 'Hemat Rp12.800 dengan Kelopak',
        actionLabel: 'Checkout (12)',
        onAction: () {},
      ),
      StickyBottomBar(
        header: const Text('Tambah Rp30.000 produk misi untuk voucher'),
        child: Row(
          children: <Widget>[
            Expanded(
              child: PillButton(
                label: 'Keranjang',
                variant: PillButtonVariant.outline,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: BpSpace.x2),
            Expanded(
              child: PillButton(label: 'Beli sekarang', onPressed: () {}),
            ),
          ],
        ),
      ),
    ],
  ),
  'Skeleton': () => _pad(
    const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Skeleton(width: 120, height: 120),
        SizedBox(height: BpSpace.x2),
        Skeleton.line(width: 200),
        SizedBox(height: BpSpace.x2),
        Skeleton.circle(size: 44),
      ],
    ),
  ),
  'EmptyState': () => EmptyState(
    imageAsset: 'assets/bipy/bipy_ngintip.webp',
    title: 'Belum ketemu yang kamu cari, Babes',
    message: 'Coba kata kunci lain atau hapus filter yang sedang aktif.',
    actionLabel: 'Hapus semua filter',
    onAction: () {},
    secondaryLabel: 'Kembali ke Beranda',
    onSecondary: () {},
  ),
  'BpChip': () => _pad(
    Wrap(
      spacing: BpSpace.x2,
      children: <Widget>[
        BpChip(label: 'Diskon Terbesar', selected: true, onTap: () {}),
        BpChip(label: 'Perawatan wajah dan tubuh', onDeleted: () {}),
        BpChip(
          label: 'Filter',
          leading: const Icon(LucideIcons.slidersHorizontal),
          onTap: () {},
        ),
      ],
    ),
  ),
  'BannerCarousel': () => const BannerCarousel(
    items: galleryBanners,
    autoPlayInterval: Duration.zero,
  ),
  'AssetPicture dan BrandIcon': () => _pad(
    const Row(
      children: <Widget>[
        AssetPicture(
          'assets/catalog/img/P11B11B01000004-1.webp',
          width: 72,
          height: 72,
          borderRadius: BpRadius.tileAll,
          semanticLabel: 'Brighty Glow & Bright Bar Soap',
        ),
        SizedBox(width: BpSpace.x3),
        AssetPicture('assets/tidak/ada.webp', width: 72, height: 72),
        SizedBox(width: BpSpace.x3),
        BrandIcon(BrandGlyph.voucher),
        BrandIcon(BrandGlyph.reward, style: BrandIconStyle.color, size: 32),
      ],
    ),
  ),
  'InfoRow dan BpSwitchTile': () => Column(
    children: <Widget>[
      BpSwitchTile(
        title: 'Pakai Kelopak untuk memotong total belanja',
        subtitle: 'Saldo 12.800 Kelopak · potong Rp1.280.000',
        leading: const BrandIcon(BrandGlyph.reward),
        value: true,
        onChanged: (_) {},
      ),
      InfoRow(
        label: 'Alamat pengiriman utama',
        helper: 'Belum ada alamat tersimpan di perangkat ini',
        value: 'Tambah alamat',
        leading: const Icon(LucideIcons.mapPin),
        onTap: () {},
      ),
      const InfoRow(
        label: 'Kelopak dipakai · 12.800 Kelopak',
        value: '-Rp1.280.000',
      ),
      const InfoRow(
        label: 'Total pembayaran',
        value: 'Rp12.500.000',
        emphasized: true,
      ),
    ],
  ),
  'VoucherTicket': () => _pad(
    Column(
      children: <Widget>[
        VoucherTicket(
          valueLabel: 'Rp100.000',
          title: 'Voucher Misi Belanja tahap kedua',
          condition: 'Min. belanja Rp1.500.000',
          expiry: 'Berlaku s.d. 25 Des 2026',
          actionLabel: 'Pakai',
          onAction: () {},
          selected: true,
        ),
        const SizedBox(height: BpSpace.x2),
        const VoucherTicket(
          valueLabel: 'Rp12.000',
          title: 'Tanggal Kembar 12.12',
          condition: 'Min. belanja Rp120.000',
          reason: 'Bisa diklaim 12 Des 2026 pukul 00.00 WIB',
          actionLabel: 'Klaim',
          muted: true,
        ),
      ],
    ),
  ),
};

void main() {
  for (final dark in <bool>[false, true]) {
    final theme = dark ? 'gelap' : 'terang';

    for (final entry in _cases.entries) {
      testWidgets('${entry.key}: skala 200% lebar 360 tanpa luapan ($theme)', (
        tester,
      ) async {
        await pumpDesign(tester, entry.value(), dark: dark, textScale: 2);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('BpAppBar, lencana, dan BpBottomNav: skala 200% ($theme)', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const SizedBox(height: 200),
        dark: dark,
        textScale: 2,
        appBar: BpAppBar(
          title: 'Keranjang belanja dan hadiah gratis (128)',
          showBack: true,
          onBack: () {},
          actions: <Widget>[
            BadgeIcon(
              icon: const BrandIcon(BrandGlyph.notif),
              label: 'Notifikasi',
              count: 120,
              onPressed: () {},
            ),
            CartBadgeIcon(count: 120, onPressed: () {}),
          ],
        ),
        bottom: BpBottomNav(
          currentIndex: 3,
          onSelected: (_) {},
          trailing: <BpNavItem>[
            BpBottomNav.defaultTrailing[0].copyWith(badgeCount: 120),
            BpBottomNav.defaultTrailing[1].copyWith(showDot: true),
          ],
          rewardDot: true,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('99+'), findsWidgets);
    });

    testWidgets('BpSheet: skala 200% lebar 360 tanpa luapan ($theme)', (
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
        dark: dark,
        textScale: 2,
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Filter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('galeri penuh: skala 200% lebar 360 tanpa luapan ($theme)', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const DesignGalleryPage(autoPlayBanners: false),
        dark: dark,
        textScale: 2,
        scroll: false,
      );
      final list = find.byType(ListView).first;
      for (var i = 0; i < 16; i++) {
        expect(tester.takeException(), isNull, reason: 'gulir ke-$i');
        await tester.drag(list, const Offset(0, -560));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('galeri penuh: skala 100% dan 130% lebar 360 tanpa luapan', (
    tester,
  ) async {
    for (final scale in <double>[1, 1.3]) {
      await pumpDesign(
        tester,
        DesignGalleryPage(key: ValueKey<double>(scale), autoPlayBanners: false),
        textScale: scale,
        scroll: false,
      );
      final list = find.byType(ListView).first;
      for (var i = 0; i < 10; i++) {
        expect(tester.takeException(), isNull, reason: 'skala $scale #$i');
        await tester.drag(list, const Offset(0, -560));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
  });
}
