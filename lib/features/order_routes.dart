/// Grup layar transaksi (agen F2): keranjang, checkout, pembayaran
/// simulasi, layar sukses, daftar pesanan (tab Transaksi), dan detail
/// pesanan. Pengingat bayar Beranda diekspor sebagai [UnpaidOrderBanner].
///
/// ```dart
/// runBpediaApp(routes: [registerShopRoutes, registerOrderRoutes, ...]);
/// ```
library;

import '../app/app_router.dart';
import 'cart/cart_page.dart';
import 'checkout/checkout_page.dart';
import 'orders/order_detail_page.dart';
import 'orders/orders_page.dart';
import 'payment/order_success_page.dart';
import 'payment/payment_page.dart';

export 'orders/widgets/unpaid_order_banner.dart' show UnpaidOrderBanner;

/// Mendaftarkan halaman dan tab milik grup transaksi ke [router]:
/// `/keranjang`, `/checkout`, `/bayar/:id`, `/pesanan/:id`,
/// `/pesanan/:id/sukses`, dan tab `orders` (`/pesanan?status=`).
void registerOrderRoutes(AppRouter router) {
  router
    ..register<CartRoute>((context, route) => const CartPage())
    ..register<CheckoutRoute>((context, route) => const CheckoutPage())
    ..register<PaymentRoute>(
      (context, route) => PaymentPage(orderId: route.orderId),
    )
    ..register<OrderSuccessRoute>(
      (context, route) => OrderSuccessPage(orderId: route.orderId),
    )
    ..register<OrderDetailRoute>(
      (context, route) => OrderDetailPage(orderId: route.orderId),
    )
    ..registerTab(AppTab.orders, (context) => const OrdersPage());
}
