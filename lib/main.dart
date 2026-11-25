import 'app/app.dart';
import 'features/account_routes.dart';
import 'features/order_routes.dart';
import 'features/shop_routes.dart';
import 'integration/kelopak_integration.dart';

/// Titik masuk Bpedia Demo: tiga grup fitur, zona Hadiah Kelopak, dan
/// gateway hadiah Kelopak (data v2 dipindahkan saat pertama dibuka).
Future<void> main() => runBpediaApp(
  routes: <RouteRegistrar>[
    registerShopRoutes,
    registerOrderRoutes,
    registerAccountRoutes,
    registerKelopakRoutes,
  ],
  rewardsBuilder: buildKelopakRewards,
  configure: attachKelopak,
);
