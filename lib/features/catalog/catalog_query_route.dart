/// Konversi dua arah antara rute `/katalog?...` dan [CatalogQuery].
library;

import '../../app/app_routes.dart';
import '../../data/catalog/catalog_repository.dart';

/// Kueri katalog dari parameter [route].
CatalogQuery queryOfRoute(CatalogRoute route) => CatalogQuery(
  text: route.query ?? '',
  categoryId: route.category,
  brands: route.brands,
  minPrice: route.minPrice,
  maxPrice: route.maxPrice,
  sort: CatalogSort.fromParam(route.sort),
);

/// Rute katalog untuk [query]; urutan bawaan dan teks kosong tidak ditulis.
CatalogRoute routeOfQuery(CatalogQuery query) {
  final brands = query.brands.toList()..sort();
  return CatalogRoute(
    category: query.categoryId,
    brands: brands,
    query: query.text.isEmpty ? null : query.text,
    sort: query.sort == CatalogSort.relevance ? null : query.sort.param,
    minPrice: query.minPrice,
    maxPrice: query.maxPrice,
  );
}
