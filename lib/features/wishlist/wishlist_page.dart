/// Wishlist (`/wishlist`): produk favorit tersimpan di perangkat, grid dua
/// kolom dengan tombol keranjang, dan keadaan kosong dengan Bipy.
library;

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/shell.dart' show CartButton;
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Daftar produk favorit.
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: const BpAppBar(
        title: 'Wishlist',
        actions: <Widget>[CartButton()],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          services.wishlist,
          services.catalog,
          services.auth,
        ]),
        builder: (context, _) {
          final state = catalogStateView(context);
          if (state != null) return state;
          final products = services.wishlist.products;
          final guest = !services.auth.isLoggedIn;
          if (products.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  imageAsset: 'assets/bipy/bipy_pose_belanja.webp',
                  imageSize: 150,
                  title: 'Wishlist masih kosong',
                  message:
                      'Ketuk ikon hati di produk yang kamu suka, nanti '
                      'tersimpan di sini.',
                  actionLabel: 'Mulai belanja',
                  onAction: () =>
                      services.router.go(context, const CatalogRoute()),
                ),
              ),
            );
          }
          final inStock = products.where((product) => product.inStock).length;
          return CustomScrollView(
            slivers: <Widget>[
              if (guest)
                SliverToBoxAdapter(
                  child: Container(
                    color: c.brandTint,
                    padding: const EdgeInsets.fromLTRB(
                      BpSpace.screen,
                      BpSpace.x2,
                      BpSpace.x2,
                      BpSpace.x2,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Wishlist tersimpan di perangkat ini. Masuk supaya '
                            'gampang checkout.',
                            style: BpText.caption.copyWith(color: c.text),
                          ),
                        ),
                        PillButton(
                          label: 'Masuk',
                          size: PillButtonSize.small,
                          variant: PillButtonVariant.tonal,
                          onPressed: () => services.router.go(
                            context,
                            const LoginRoute(next: '/wishlist'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BpSpace.screen,
                    BpSpace.x3,
                    BpSpace.screen,
                    BpSpace.x2,
                  ),
                  child: Text(
                    '${products.length} produk favorit'
                    '${inStock < products.length ? ' · ${products.length - inStock} stok habis' : ''}',
                    style: BpText.bodyS.copyWith(
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverProductGrid(
                itemCount: products.length,
                itemBuilder: (context, index) => ShopProductCard(
                  product: products[index],
                  action: ProductCardAction.addButton,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: BpSpace.x4)),
            ],
          );
        },
      ),
    );
  }
}
