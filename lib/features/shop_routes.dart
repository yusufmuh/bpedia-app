/// Pendaftaran layar jelajah (agen F1): tab Beranda dan Katalog, Cari,
/// Detail produk, Hot Item, Event Promo, dan Wishlist.
///
/// Dipakai `runBpediaApp(routes: [registerShopRoutes, ...])`. Mode Demo
/// memakai [showActiveAppFlyer] untuk tombol "Tampilkan App Flyer".
library;

import 'package:flutter/widgets.dart';

import '../app/app_router.dart';
import 'catalog/catalog_page.dart';
import 'event/event_hub_page.dart';
import 'event/event_page.dart';
import 'home/home_page.dart';
import 'hot/hot_items_page.dart';
import 'product/product_page.dart';
import 'search/search_page.dart';
import 'wishlist/wishlist_page.dart';

export 'home/app_flyer.dart' show maybeShowDailyFlyer, showActiveAppFlyer;

/// Mendaftarkan semua rute dan tab milik layar jelajah ke [router].
void registerShopRoutes(AppRouter router) {
  router
    ..registerTab(AppTab.home, (context) => const HomePage())
    ..registerTab(AppTab.catalog, (context) => const CatalogPage())
    ..register<SearchRoute>(
      (context, route) => SearchPage(initialQuery: route.query),
    )
    ..register<ProductRoute>(
      (context, route) =>
          ProductPage(key: ValueKey<String>(route.code), code: route.code),
    )
    ..register<HotItemsRoute>((context, route) => const HotItemsPage())
    ..register<EventHubRoute>((context, route) => const EventHubPage())
    ..register<EventRoute>((context, route) => EventPage(id: route.id))
    ..register<WishlistRoute>((context, route) => const WishlistPage());
}
