import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'design.dart';

/// Contoh produk untuk galeri: potret `assets/catalog/catalog.json`
/// (bpedia.id, 25 Nov 2026). Rating hanya diisi bila katalog memilikinya.
const List<ProductCardData> galleryProducts = <ProductCardData>[
  ProductCardData(
    id: 'P11B11B01000004',
    name: 'Brighty Glow & Bright Bar Soap',
    brand: 'Brighty',
    price: 10000,
    strikePrice: 22500,
    discountPercent: 56,
    rating: 5,
    imageAsset: 'assets/catalog/img/P11B11B01000004-1.webp',
  ),
  ProductCardData(
    id: 'P39A06S01000021',
    name: 'Animate Brightening Facial Wash 100 ml',
    brand: 'Animate',
    price: 17800,
    rating: 5,
    imageAsset: 'assets/catalog/img/P39A06S01000021-1.webp',
  ),
  ProductCardData(
    id: 'P42S09S01000021',
    name: 'Somethinc 5% Niacinamide Barrier Serum - 20 ml',
    brand: 'Somethinc',
    price: 106800,
    imageAsset: 'assets/catalog/img/P42S09S01000021-1.webp',
    ribbon: 'Produk misi',
  ),
  ProductCardData(
    id: 'P39A06S01000052',
    name: 'Animate Intense Acne Solution Day Cream 10 g',
    brand: 'Animate',
    price: 10000,
    strikePrice: 21500,
    discountPercent: 53,
    imageAsset: 'assets/catalog/img/P39A06S01000052-1.webp',
    inStock: false,
  ),
];

/// Gambar highlight Hot Item asli (rasio 1:1) dari katalog.
const List<ProductCardData> galleryHotItems = <ProductCardData>[
  ProductCardData(
    id: 'P11B11B01000004',
    name: 'Brighty Glow & Bright Bar Soap',
    price: 10000,
    strikePrice: 22500,
    discountPercent: 56,
    imageAsset: 'assets/catalog/hot/P11B11B01000004.webp',
  ),
  ProductCardData(
    id: 'P02S01B01000005',
    name: 'Salsa Bleach Body Glow Serum Symphony',
    price: 10000,
    strikePrice: 20000,
    discountPercent: 50,
    imageAsset: 'assets/catalog/hot/P02S01B01000005.webp',
  ),
  ProductCardData(
    id: 'P39A06S01000053',
    name: 'Animate Intense Acne Solution Night Cream 10 g',
    price: 10000,
    strikePrice: 23500,
    discountPercent: 57,
    imageAsset: 'assets/catalog/hot/P39A06S01000053.webp',
  ),
];

const List<BannerItem> galleryBanners = <BannerItem>[
  BannerItem(
    asset: 'assets/promo/banner_main_bareng_bipy.webp',
    semanticLabel: 'Main bareng Bipy',
  ),
  BannerItem(
    asset: 'assets/promo/banner_black_friday.webp',
    semanticLabel: 'Black Friday',
  ),
  BannerItem(
    asset: 'assets/promo/banner_1212.webp',
    semanticLabel: 'Tanggal Kembar 12.12',
  ),
  BannerItem(
    asset: 'assets/promo/banner_komunitas.webp',
    semanticLabel: 'Komunitas WhatsApp',
  ),
  BannerItem(
    asset: 'assets/promo/banner_produk_gratis.webp',
    semanticLabel: 'Produk gratis',
  ),
];

/// Galeri seluruh komponen sistem desain (dibuka dari Mode Demo).
class DesignGalleryPage extends StatefulWidget {
  const DesignGalleryPage({
    super.key,
    this.onToggleTheme,
    this.autoPlayBanners = true,
  });

  /// Bila diisi, tombol matahari/bulan tampil di app bar.
  final VoidCallback? onToggleTheme;

  /// Dimatikan pada tes supaya tidak ada pewaktu yang tertinggal.
  final bool autoPlayBanners;

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  static const List<String> _sorts = <String>[
    'Paling Sesuai',
    'Termurah',
    'Termahal',
    'Diskon Terbesar',
  ];
  static const List<String> _orderTabs = <String>[
    'Semua',
    'Menunggu pembayaran',
    'Dikemas',
    'Dikirim',
    'Selesai',
  ];

  int _tab = 0;
  int _cart = 2;
  int _qty = 1;
  int _sort = 0;
  int _courier = 0;
  bool _useKelopak = true;
  bool _agree = true;
  bool _busy = false;
  final Set<String> _wishlist = <String>{'P39A06S01000021'};
  final List<String> _filters = <String>['Skincare', 'Animate'];
  final TextEditingController _phone = TextEditingController(text: '0812');

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _openDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const GalleryDialog(),
    );
  }

  void _showSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('1 produk dihapus dari keranjang'),
          action: SnackBarAction(label: 'Urungkan', onPressed: () {}),
        ),
      );
  }

  void _toggleWishlist(String id) {
    setState(() {
      if (!_wishlist.remove(id)) _wishlist.add(id);
    });
  }

  void _openSheet() {
    showBpSheet<void>(
      context: context,
      builder: (context) => const GallerySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final toggle = widget.onToggleTheme;
    return Scaffold(
      appBar: BpAppBar(
        title: 'Galeri komponen',
        actions: <Widget>[
          if (toggle != null)
            IconButton(
              tooltip: c.isDark ? 'Tema terang' : 'Tema gelap',
              onPressed: toggle,
              icon: Icon(c.isDark ? LucideIcons.sun : LucideIcons.moon),
            ),
          BadgeIcon(
            icon: const BrandIcon(BrandGlyph.notif),
            label: 'Notifikasi',
            count: 3,
            onPressed: () {},
          ),
          CartBadgeIcon(
            count: _cart,
            onPressed: () => setState(() => _cart = 0),
          ),
        ],
      ),
      bottomNavigationBar: BpBottomNav(
        currentIndex: _tab,
        onSelected: (index) => setState(() => _tab = index),
        trailing: <BpNavItem>[
          BpBottomNav.defaultTrailing[0].copyWith(badgeCount: 2),
          BpBottomNav.defaultTrailing[1],
        ],
        rewardDot: true,
      ),
      body: ListView(
        children: <Widget>[
          Section(
            padding: const EdgeInsets.fromLTRB(
              BpSpace.screen,
              BpSpace.x3,
              BpSpace.screen,
              BpSpace.x3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AssetPicture(
                      c.isDark
                          ? 'assets/images/logo_wordmark_reverse.webp'
                          : 'assets/images/logo_wordmark_bipy.webp',
                      height: 28,
                      width: 77,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      showSkeleton: false,
                      semanticLabel: 'Bpedia',
                    ),
                    const Spacer(),
                    StatusChip(
                      label: c.isDark ? 'Tema gelap' : 'Tema terang',
                      tone: StatusTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: BpSpace.x3),
                SearchField.button(
                  onTap: () {},
                  hints: const <String>[
                    'Cari serum di Bpedia',
                    'Cari sunscreen di Bpedia',
                  ],
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Event Promo'),
            child: BannerCarousel(
              items: galleryBanners,
              autoPlayInterval: widget.autoPlayBanners
                  ? const Duration(seconds: 4)
                  : Duration.zero,
            ),
          ),
          Section(
            header: SectionHeader(
              title: 'Hot Item',
              leading: const AssetPicture(
                'assets/icons3d/hot.webp',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                showSkeleton: false,
              ),
              onAction: () {},
            ),
            child: ProductRail(
              itemCount: galleryHotItems.length,
              itemBuilder: (context, index) => ProductCard(
                data: galleryHotItems[index],
                action: ProductCardAction.none,
                reserveRatingRow: false,
                onTap: () {},
              ),
            ),
          ),
          Section(
            header: SectionHeader(
              title: 'Rekomendasi untukmu',
              onAction: () {},
            ),
            child: ProductGrid(
              itemCount: galleryProducts.length + 2,
              itemBuilder: (context, index) {
                if (index >= galleryProducts.length) {
                  return const ProductCardSkeleton();
                }
                final product = galleryProducts[index];
                return ProductCard(
                  data: product,
                  wishlisted: _wishlist.contains(product.id),
                  onToggleWishlist: () => _toggleWishlist(product.id),
                  onAddToCart: () => setState(() => _cart++),
                  action: index == 2
                      ? ProductCardAction.addButton
                      : ProductCardAction.quickAdd,
                  onTap: () {},
                );
              },
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Tombol'),
            inset: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PillButton(
                  label: 'Beli sekarang',
                  busy: _busy,
                  onPressed: () => setState(() => _busy = !_busy),
                  expand: true,
                ),
                const SizedBox(height: BpSpace.x2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PillButton(
                        label: 'Keranjang',
                        icon: const Icon(LucideIcons.plus),
                        variant: PillButtonVariant.outline,
                        onPressed: () => setState(() => _cart++),
                      ),
                    ),
                    const SizedBox(width: BpSpace.x2),
                    Expanded(
                      child: PillButton(
                        label: 'Pakai voucher',
                        variant: PillButtonVariant.tonal,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BpSpace.x2),
                Wrap(
                  spacing: BpSpace.x2,
                  runSpacing: BpSpace.x1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    PillButton(
                      label: 'Atur ulang',
                      variant: PillButtonVariant.neutral,
                      size: PillButtonSize.small,
                      onPressed: () {},
                    ),
                    PillButton(
                      label: 'Lihat pesanan',
                      variant: PillButtonVariant.text,
                      size: PillButtonSize.small,
                      onPressed: () {},
                    ),
                    const PillButton(
                      label: 'Stok habis',
                      size: PillButtonSize.small,
                      onPressed: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Chip dan status'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: BpSpace.screen,
                  ),
                  child: Row(
                    children: <Widget>[
                      for (var i = 0; i < _sorts.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: BpSpace.x2),
                          child: BpChip(
                            label: _sorts[i],
                            selected: _sort == i,
                            onTap: () => setState(() => _sort = i),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_filters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BpSpace.screen,
                    ),
                    child: Wrap(
                      spacing: BpSpace.x2,
                      children: <Widget>[
                        for (final filter in _filters)
                          BpChip(
                            label: filter,
                            onDeleted: () =>
                                setState(() => _filters.remove(filter)),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: BpSpace.x2),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: BpSpace.screen),
                  child: Wrap(
                    spacing: BpSpace.x2,
                    runSpacing: BpSpace.x2,
                    children: <Widget>[
                      StatusChip(
                        label: 'Menunggu pembayaran',
                        tone: StatusTone.warning,
                      ),
                      StatusChip(label: 'Dikemas', tone: StatusTone.brand),
                      StatusChip(label: 'Dikirim', tone: StatusTone.info),
                      StatusChip(label: 'Selesai', tone: StatusTone.success),
                      StatusChip(label: 'Dibatalkan', tone: StatusTone.danger),
                      StatusChip(label: 'Gratis', tone: StatusTone.gold),
                      StatusChip(
                        label: '100% Original',
                        tone: StatusTone.success,
                        icon: BrandIcon(BrandGlyph.original, size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Harga dan jumlah'),
            inset: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const PriceText(
                  10000,
                  strikePrice: 22500,
                  discountPercent: 56,
                  size: PriceTextSize.detail,
                ),
                const SizedBox(height: BpSpace.x2),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: PriceText(106800, strikePrice: 128000),
                    ),
                    QtyStepper(
                      value: _qty,
                      max: 5,
                      onChanged: (value) => setState(() => _qty = value),
                      onRemove: () => setState(() => _qty = 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Section(
            header: SectionHeader(title: 'Voucher', onAction: () {}),
            inset: true,
            child: Column(
              children: <Widget>[
                VoucherTicket(
                  valueLabel: 'Rp10.000',
                  title: 'Voucher Misi Belanja',
                  condition: 'Min. belanja Rp100.000',
                  expiry: 'Berlaku s.d. 25 Des 2026',
                  actionLabel: 'Pakai',
                  onAction: () {},
                ),
                const SizedBox(height: BpSpace.x2),
                const VoucherTicket(
                  valueLabel: 'Rp12.000',
                  title: 'Tanggal Kembar 12.12',
                  condition: 'Min. belanja Rp120.000',
                  reason: 'Bisa diklaim 12 Des 2026',
                  actionLabel: 'Klaim',
                  muted: true,
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Ringkasan dan baris menu'),
            child: Column(
              children: <Widget>[
                BpSwitchTile(
                  title: 'Pakai Kelopak',
                  subtitle: 'Saldo 128 Kelopak · potong Rp12.800',
                  leading: const AssetPicture(
                    'assets/icons3d/kelopak.webp',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    showSkeleton: false,
                  ),
                  value: _useKelopak,
                  onChanged: (value) => setState(() => _useKelopak = value),
                ),
                InfoRow(
                  label: 'Voucher',
                  value: '2 tersedia',
                  leading: const BrandIcon(BrandGlyph.voucher),
                  onTap: () {},
                ),
                InfoRow(
                  label: 'Alamat',
                  helper: 'Belum ada alamat tersimpan',
                  value: 'Tambah',
                  leading: const Icon(LucideIcons.mapPin),
                  onTap: () {},
                ),
                const Divider(
                  indent: BpSpace.screen,
                  endIndent: BpSpace.screen,
                ),
                const InfoRow(label: 'Subtotal produk', value: 'Rp116.800'),
                const InfoRow(label: 'Ongkir (demo)', value: 'Rp9.000'),
                if (_useKelopak)
                  InfoRow(
                    label: 'Kelopak dipakai · 128',
                    value: '-Rp12.800',
                    valueColor: c.success,
                  ),
                InfoRow(
                  label: 'Total',
                  value: _useKelopak ? 'Rp113.000' : 'Rp125.800',
                  emphasized: true,
                ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Bar aksi bawah'),
            padding: const EdgeInsets.only(top: BpSpace.x1),
            child: StickyBottomBar.total(
              total: _useKelopak ? 113000 : 125800,
              caption: _useKelopak ? 'Hemat Rp12.800 dengan Kelopak' : null,
              actionLabel: 'Checkout (2)',
              onAction: () {},
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Tab dan kolom isian'),
            child: DefaultTabController(
              length: _orderTabs.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    padding: const EdgeInsets.symmetric(horizontal: BpSpace.x1),
                    tabs: <Widget>[
                      for (final tab in _orderTabs) Tab(text: tab, height: 44),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BpSpace.screen,
                      BpSpace.x4,
                      BpSpace.screen,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Nomor HP atau email',
                            hintText: '0812 3456 7890',
                          ),
                        ),
                        const SizedBox(height: BpSpace.x3),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor HP',
                            errorText:
                                'Nomor HP belum lengkap. Isi 10–13 angka.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RadioGroup<int>(
                    groupValue: _courier,
                    onChanged: (value) =>
                        setState(() => _courier = value ?? _courier),
                    child: const Column(
                      children: <Widget>[
                        RadioListTile<int>(
                          value: 0,
                          title: Text('Bpedia Express'),
                          subtitle: Text('Ongkir Rp9.000 (demo)'),
                        ),
                        RadioListTile<int>(
                          value: 1,
                          title: Text('Wahana Express'),
                          subtitle: Text('Ongkir Rp11.000 (demo)'),
                        ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    value: _agree,
                    onChanged: (value) =>
                        setState(() => _agree = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Saya setuju dengan Syarat & Ketentuan'),
                  ),
                ],
              ),
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Ikon brand'),
            inset: true,
            child: Wrap(
              spacing: BpSpace.x3,
              runSpacing: BpSpace.x3,
              children: <Widget>[
                for (final glyph in BrandGlyph.values)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.brandTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: BrandIcon(
                      glyph,
                      style: BrandIconStyle.color,
                      semanticLabel: glyph.id,
                    ),
                  ),
              ],
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Keadaan kosong'),
            child: EmptyState(
              imageAsset: 'assets/bipy/bipy_ngintip.webp',
              title: 'Belum ketemu, Babes',
              message: 'Coba kata kunci lain atau hapus filter yang aktif.',
              actionLabel: 'Hapus filter',
              onAction: () {},
              compact: true,
            ),
          ),
          Section(
            header: const SectionHeader(title: 'Lembar, dialog, dan pesan'),
            inset: true,
            gap: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PillButton(
                  label: 'Buka lembar filter',
                  variant: PillButtonVariant.neutral,
                  icon: const Icon(LucideIcons.slidersHorizontal),
                  onPressed: _openSheet,
                ),
                const SizedBox(height: BpSpace.x2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PillButton(
                        label: 'Buka dialog',
                        variant: PillButtonVariant.neutral,
                        size: PillButtonSize.small,
                        onPressed: _openDialog,
                      ),
                    ),
                    const SizedBox(width: BpSpace.x2),
                    Expanded(
                      child: PillButton(
                        label: 'Tampilkan pesan',
                        variant: PillButtonVariant.neutral,
                        size: PillButtonSize.small,
                        onPressed: _showSnack,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog contoh (pola konfirmasi batal pesanan) untuk galeri dan tangkap layar.
class GalleryDialog extends StatelessWidget {
  const GalleryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batalkan pesanan ini?'),
      content: const Text(
        '128 Kelopak, voucher Rp10.000, dan hadiah gratis akan kembali ke '
        'akunmu.',
      ),
      actions: <Widget>[
        PillButton(
          label: 'Tidak jadi',
          variant: PillButtonVariant.text,
          size: PillButtonSize.small,
          onPressed: () => Navigator.maybePop(context),
        ),
        PillButton(
          label: 'Batalkan pesanan',
          size: PillButtonSize.small,
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}

/// Lembar contoh (pola lembar Filter katalog) untuk galeri dan tangkap layar.
class GallerySheet extends StatefulWidget {
  const GallerySheet({super.key});

  @override
  State<GallerySheet> createState() => _GallerySheetState();
}

class _GallerySheetState extends State<GallerySheet> {
  static const List<String> _categories = <String>[
    'Skincare',
    'Makeup',
    'Bodycare',
    'Haircare',
    'Fragrance',
  ];
  static const List<String> _prices = <String>[
    'Di bawah Rp25.000',
    'Rp25.000 – Rp75.000',
    'Di atas Rp75.000',
  ];

  final Set<String> _picked = <String>{'Skincare'};
  int? _price = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return BpSheet(
      title: 'Filter',
      footer: Row(
        children: <Widget>[
          Expanded(
            child: PillButton(
              label: 'Atur ulang',
              variant: PillButtonVariant.neutral,
              onPressed: () => setState(() {
                _picked.clear();
                _price = null;
              }),
            ),
          ),
          const SizedBox(width: BpSpace.x2),
          Expanded(
            flex: 2,
            child: PillButton(
              label: 'Terapkan',
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Kategori', style: BpText.subtitle.copyWith(color: c.text)),
          const SizedBox(height: BpSpace.x2),
          Wrap(
            spacing: BpSpace.x2,
            children: <Widget>[
              for (final category in _categories)
                BpChip(
                  label: category,
                  selected: _picked.contains(category),
                  onTap: () => setState(() {
                    if (!_picked.remove(category)) _picked.add(category);
                  }),
                ),
            ],
          ),
          const SizedBox(height: BpSpace.x4),
          Text('Harga', style: BpText.subtitle.copyWith(color: c.text)),
          const SizedBox(height: BpSpace.x2),
          Wrap(
            spacing: BpSpace.x2,
            children: <Widget>[
              for (var i = 0; i < _prices.length; i++)
                BpChip(
                  label: _prices[i],
                  selected: _price == i,
                  onTap: () => setState(() => _price = _price == i ? null : i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
