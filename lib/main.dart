import 'app/app.dart';

/// Titik masuk Bpedia Demo.
///
/// Grup fitur disambungkan di sini lewat `runBpediaApp(routes: ...)`
/// (`registerShopRoutes`, `registerOrderRoutes`, `registerAccountRoutes`) dan
/// zona Hadiah lewat `configure`/`rewardsBuilder`. Tab yang belum punya fitur
/// menampilkan halaman pengganti dari kerangka.
Future<void> main() => runBpediaApp();
