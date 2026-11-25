/// Membaca berkas aset proyek secara sinkron untuk `AppServices.forTest`.
///
/// Hanya berfungsi di VM (tes); di web selalu null.
library;

export 'test_assets_stub.dart' if (dart.library.io) 'test_assets_io.dart';
